class_name PlayerInput
extends Node
## Turns local devices into an intent for its Player: move, aim, held buttons and
## buffered presses. The Player never reads Input directly: in co-op (M11) remote
## intents arrive over the network instead and the host applies them the same way.

const BUFFERED: Array[StringName] = [&"attack_light", &"attack_heavy", &"dodge", &"interact"]

## Seconds the mouse stays the aim source after it last moved or clicked.
@export var mouse_aim_timeout: float = 2.0
## A press is remembered this long, so pressing during recovery queues the next action.
@export var buffer_time: float = 0.2

var move: Vector2 = Vector2.ZERO
var aim: Vector2 = Vector2.ZERO  ## normalized, or ZERO when nothing is aiming
var block_held: bool = false
var sprint_held: bool = false

var _mouse_aim_left: float = 0.0
var _buffer: Dictionary = {}  # action -> seconds left


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		_mouse_aim_left = mouse_aim_timeout


## True when this machine controls the owning player. Solo: always true (peer 1).
func is_local() -> bool:
	var body := get_parent() as Player
	return body != null and body.peer_id == multiplayer.get_unique_id()


## Samples devices for this physics tick. Called by the Player, so ordering is explicit.
func gather(delta: float) -> void:
	for action: StringName in _buffer.keys():
		_buffer[action] = maxf(0.0, _buffer[action] - delta)
	if not is_local():
		return
	move = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	block_held = Input.is_action_pressed(&"block")
	sprint_held = Input.is_action_pressed(&"sprint")
	for action in BUFFERED:
		if Input.is_action_just_pressed(action):
			_buffer[action] = buffer_time
	_gather_aim(delta)


## Takes a buffered press if there is one.
func consume(action: StringName) -> bool:
	if _buffer.get(action, 0.0) > 0.0:
		_buffer[action] = 0.0
		return true
	return false


func clear_buffer() -> void:
	_buffer.clear()


func _gather_aim(delta: float) -> void:
	var stick := Input.get_vector(&"aim_left", &"aim_right", &"aim_up", &"aim_down")
	_mouse_aim_left = maxf(0.0, _mouse_aim_left - delta)
	if stick != Vector2.ZERO:
		aim = stick.normalized()
		_mouse_aim_left = 0.0
	elif _mouse_aim_left > 0.0:
		var body := get_parent() as Node2D
		var to_mouse := body.get_global_mouse_position() - (body.global_position + Vector2(0, -10))
		aim = to_mouse.normalized() if to_mouse.length() > 1.0 else Vector2.ZERO
	else:
		aim = Vector2.ZERO
