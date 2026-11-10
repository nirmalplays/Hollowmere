class_name Player
extends CharacterBody2D
## M1 player: 8-direction movement with acceleration and friction, 4-direction
## animation (side frames flip for left), camera on the local player only.
## Host-authority aware (GAME_PLAN 9): the authority peer applies intent; solo = peer 1.

signal facing_changed(direction: Vector2)

@export var tuning: MovementTuning
@export var sprite_sheet: SpriteSheetDef

var peer_id: int = Const.SOLO_PEER_ID
var facing: Vector2 = Vector2.DOWN

@onready var _input: PlayerInput = $Input
@onready var _sprite: AnimatedSprite2D = $Sprite
@onready var _camera: Camera2D = $Camera


func _ready() -> void:
	set_multiplayer_authority(peer_id)
	_sprite.sprite_frames = SpriteFramesBuilder.build(sprite_sheet)
	_sprite.offset = sprite_sheet.foot_offset()
	_camera.enabled = _input.is_local()
	if _camera.enabled:
		_camera.make_current()
	_update_animation()


func _physics_process(delta: float) -> void:
	_input.gather(delta)
	if is_multiplayer_authority():
		_apply_movement(_input.move, delta)
	_update_facing()
	_update_animation()


func set_camera_limits(rect: Rect2i) -> void:
	_camera.limit_left = rect.position.x
	_camera.limit_top = rect.position.y
	_camera.limit_right = rect.end.x
	_camera.limit_bottom = rect.end.y


func _apply_movement(move: Vector2, delta: float) -> void:
	if move != Vector2.ZERO:
		var target := move.limit_length(1.0) * tuning.max_speed
		velocity = velocity.move_toward(target, tuning.acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, tuning.friction * delta)
	move_and_slide()


## Aim wins over movement so the character faces where it will attack (M2).
func _update_facing() -> void:
	var want := _input.aim if _input.aim != Vector2.ZERO else _input.move
	if want != Vector2.ZERO and not want.is_equal_approx(facing):
		facing = want.normalized()
		facing_changed.emit(facing)


func _update_animation() -> void:
	var dir_name: StringName
	if absf(facing.x) >= absf(facing.y):
		dir_name = &"side"
		_sprite.flip_h = facing.x < 0.0
	else:
		dir_name = &"up" if facing.y < 0.0 else &"down"
		_sprite.flip_h = false
	# Real velocity, not requested: pushing into a wall should play idle, not walk.
	var moving := get_real_velocity().length() > tuning.max_speed * 0.1
	var anim := StringName(("walk_" if moving else "idle_") + dir_name)
	if _sprite.animation != anim:
		_sprite.play(anim)
