class_name ResourceBar
extends Control
## A pixel bar for HP/stamina/mana. Width grows with the max value (more HP = longer
## bar), and a pale "chip" trails behind recent losses so damage reads at a glance.

@export var fill_color: Color = Color(0.72, 0.26, 0.23)
@export var chip_color: Color = Color(0.96, 0.85, 0.6)
@export var back_color: Color = Color(0.1, 0.08, 0.12)
@export var border_color: Color = Color(0.33, 0.32, 0.36)
@export var pixels_per_point: float = 0.8
@export var bar_height: int = 5
@export var chip_delay: float = 0.4
@export var chip_speed: float = 60.0  ## points per second

var value: float = 1.0
var max_value: float = 1.0
var dimmed: bool = false  ## e.g. stamina while exhausted

var _chip: float = 1.0
var _chip_wait: float = 0.0


func set_values(new_value: float, new_max: float) -> void:
	if new_value < value:
		_chip = maxf(_chip, value)
		_chip_wait = chip_delay
	else:
		_chip = maxf(_chip, new_value)
	value = new_value
	max_value = maxf(new_max, 1.0)
	custom_minimum_size = Vector2(roundf(max_value * pixels_per_point) + 2.0, bar_height + 2)
	queue_redraw()


func _process(delta: float) -> void:
	if _chip <= value:
		return
	if _chip_wait > 0.0:
		_chip_wait -= delta
		return
	_chip = maxf(value, _chip - chip_speed * delta)
	queue_redraw()


func _draw() -> void:
	var inner_w := roundf(max_value * pixels_per_point)
	draw_rect(Rect2(0, 0, inner_w + 2, bar_height + 2), border_color)
	draw_rect(Rect2(1, 1, inner_w, bar_height), back_color)
	var chip_w := roundf(inner_w * clampf(_chip / max_value, 0.0, 1.0))
	draw_rect(Rect2(1, 1, chip_w, bar_height), chip_color)
	var fill_w := roundf(inner_w * clampf(value / max_value, 0.0, 1.0))
	var color := fill_color.darkened(0.45) if dimmed else fill_color
	draw_rect(Rect2(1, 1, fill_w, bar_height), color)
	draw_rect(Rect2(1, 1, fill_w, 1), color.lightened(0.25))  # top highlight
