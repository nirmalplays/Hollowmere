class_name Pickup
extends Node2D
## An item lying in the world. Walk over it to take it (a toast shows its name).
## M4 replaces the drawn icon with item data and inventory slots.

signal picked(item_id: StringName)

@export var item_id: StringName = &"sexton_key"
@export var item_name: String = "Sexton's Key"
@export var radius: float = 18.0

var _t: float = 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	for node in get_tree().get_nodes_in_group(&"players"):
		var p := node as Player
		if p and p.global_position.distance_to(global_position) < radius:
			EventBus.item_picked.emit(p.peer_id, item_id, 1)
			EventBus.toast_shown.emit("Item", item_name)
			AudioManager.sfx(&"treasure", -4.0, 0.0)
			picked.emit(item_id)
			queue_free()
			return


func _draw() -> void:
	var bob := sin(_t * 3.0) * 2.0
	var glow := 0.5 + 0.5 * sin(_t * 4.0)
	draw_circle(Vector2(0, -6 + bob), 9.0, Color(1.0, 0.85, 0.4, 0.15 + 0.1 * glow))
	# A small gold key.
	var o := Vector2(-6, -10 + bob)
	draw_circle(o + Vector2(3, 3), 3.0, Color(0.85, 0.65, 0.25))
	draw_circle(o + Vector2(3, 3), 1.2, Color(0.2, 0.14, 0.08))
	draw_rect(Rect2(o + Vector2(5, 2), Vector2(8, 2)), Color(0.85, 0.65, 0.25))
	draw_rect(Rect2(o + Vector2(10, 4), Vector2(2, 3)), Color(0.85, 0.65, 0.25))
	draw_rect(Rect2(o + Vector2(12, 4), Vector2(1, 2)), Color(0.85, 0.65, 0.25))
