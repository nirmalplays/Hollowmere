class_name EchoWisp
extends Node2D
## What a Hollowed leaves behind: a mote of pale light that bursts out, hangs a moment,
## then runs to the nearest Unlaid. Echoes are spent at a fire to grow stronger.

const CORE := Color(0.86, 0.96, 1.0)
const GLOW := Color(0.5, 0.8, 1.0)

var value: int = 1

var _vel: Vector2 = Vector2.ZERO
var _age: float = 0.0
var _hang: float = 0.45
var _trail: Array[Vector2] = []


static func burst(parent: Node, at: Vector2, total: int) -> void:
	var count := clampi(total / 4, 2, 9)
	var left := total
	for i in count:
		var wisp := EchoWisp.new()
		wisp.value = left if i == count - 1 else total / count
		left -= wisp.value
		var ang := randf() * TAU
		wisp._vel = Vector2(cos(ang), sin(ang) * 0.7) * randf_range(70.0, 150.0)
		wisp._hang = randf_range(0.35, 0.65)
		parent.add_child(wisp)
		wisp.global_position = at + Vector2(0, -12)


func _ready() -> void:
	z_index = 4
	add_child(Prop.make_light(GLOW, 0.7, 0.3, Vector2.ZERO))


func _process(delta: float) -> void:
	_age += delta
	var target := get_tree().get_first_node_in_group(&"players") as Player
	if _age < _hang or target == null:
		_vel = _vel.move_toward(Vector2.ZERO, 260.0 * delta)
	else:
		var to := target.chest_position() - global_position
		if to.length() < 10.0:
			target.gain_echoes(value)
			queue_free()
			return
		# Faster the longer it has been chasing, so it always arrives.
		_vel = _vel.lerp(to.normalized() * (180.0 + (_age - _hang) * 520.0), 1.0 - exp(-9.0 * delta))
	_trail.push_front(global_position)
	if _trail.size() > 6:
		_trail.pop_back()
	global_position += _vel * delta
	queue_redraw()


func _draw() -> void:
	for i in _trail.size():
		var k := 1.0 - float(i) / _trail.size()
		draw_circle(to_local(_trail[i]), 2.0 * k, Color(GLOW, 0.45 * k))
	var pulse := 0.8 + 0.2 * sin(_age * 14.0)
	draw_circle(Vector2.ZERO, 5.0 * pulse, Color(GLOW, 0.3))
	draw_circle(Vector2.ZERO, 2.2, CORE)
