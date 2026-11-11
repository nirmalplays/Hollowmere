class_name Trigger
extends Area2D
## An invisible zone that fires once when a local player walks in (quest `reach`
## objectives, scripted beats). The area builder sets `id` to its layout character.

signal triggered(id: StringName)

@export var id: StringName = &""
@export var radius: float = 40.0
@export var once: bool = true

var _fired: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = Const.LAYER_PLAYER
	monitoring = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if (_fired and once) or not body is Player:
		return
	_fired = true
	triggered.emit(id)


## Lets a one-shot trigger fire again once the player has stepped out and back in.
func rearm() -> void:
	_fired = false
