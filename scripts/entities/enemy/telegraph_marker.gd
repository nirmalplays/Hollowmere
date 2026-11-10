class_name TelegraphMarker
extends Node2D
## Ground marker for an AoE wind-up: an outline of the danger zone that fills
## as the attack approaches, so the player can read when to dodge or parry.

const RING_COLOR := Color(1.0, 0.35, 0.25, 0.85)
const FILL_COLOR := Color(1.0, 0.35, 0.25, 0.3)
const SQUASH: float = 0.6  ## top-down ground ellipse

var radius: float = 20.0
var progress: float = 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()


func show_marker(r: float) -> void:
	radius = r
	progress = 0.0
	visible = true


func hide_marker() -> void:
	visible = false


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, SQUASH))
	if progress > 0.0:
		draw_circle(Vector2.ZERO, radius * progress, FILL_COLOR)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, RING_COLOR, 1.0, false)
