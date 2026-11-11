class_name TelegraphMarker
extends Node2D
## Ground warning for an enemy wind-up, so the player can read when and where to
## dodge or parry: a circle round the enemy, a box in front of it, or pits on the
## ground at the target. The shape fills as the attack approaches.

enum Mode { CIRCLE, BOX, PITS }

const RING_COLOR := Color(1.0, 0.35, 0.25, 0.85)
const FILL_COLOR := Color(1.0, 0.35, 0.25, 0.3)
const SQUASH: float = 0.6  ## top-down ground ellipse

var radius: float = 20.0
var progress: float = 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()

var _mode: Mode = Mode.CIRCLE
var _box := Vector2(30, 22)
var _dir := Vector2.RIGHT
var _reach: float = 20.0
var _pits: Array[Vector2] = []


func show_marker(r: float) -> void:
	_mode = Mode.CIRCLE
	radius = r
	_open()


func show_box(size: Vector2, dir: Vector2, reach: float) -> void:
	_mode = Mode.BOX
	_box = size
	_dir = dir
	_reach = reach
	_open()


## Pits: the first on `at` (local), the rest spread around it.
func show_pits(at: Vector2, r: float, count: int, spread: float, dir: Vector2) -> void:
	_mode = Mode.PITS
	radius = r
	_pits = [at]
	for i in range(1, count):
		var ang := dir.angle() + TAU * i / count
		_pits.append(at + Vector2(cos(ang), sin(ang)) * spread)
	_open()


func extra_pit_positions() -> Array[Vector2]:
	return _pits.slice(1) if _mode == Mode.PITS else ([] as Array[Vector2])


func hide_marker() -> void:
	visible = false


func _open() -> void:
	progress = 0.0
	visible = true


func _draw() -> void:
	match _mode:
		Mode.BOX:
			draw_set_transform(_dir * _reach, _dir.angle(), Vector2.ONE)
			var rect := Rect2(-_box * 0.5, _box)
			draw_rect(Rect2(rect.position, Vector2(_box.x * progress, _box.y)), FILL_COLOR)
			draw_rect(rect, RING_COLOR, false, 1.0)
		Mode.PITS:
			for p in _pits:
				_circle(p)
		_:
			_circle(Vector2.ZERO)


func _circle(at: Vector2) -> void:
	draw_set_transform(at, 0.0, Vector2(1.0, SQUASH))
	if progress > 0.0:
		draw_circle(Vector2.ZERO, radius * progress, FILL_COLOR)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, RING_COLOR, 1.0, false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
