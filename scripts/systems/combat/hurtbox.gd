class_name Hurtbox
extends Area2D
## Where an entity can be hit. Forwards hits to `entity.receive_hit(info) -> int`
## (a DamageInfo.Result), so the entity decides about i-frames, blocks and parries.

@export var team: int = 0

var enabled: bool = true
var entity: Node


func _ready() -> void:
	collision_layer = Const.LAYER_HURTBOX
	collision_mask = 0
	monitoring = false
	monitorable = true
	if entity == null:
		entity = get_parent()


func receive(info: DamageInfo) -> int:
	if not enabled:
		return DamageInfo.Result.IGNORED
	return entity.receive_hit(info)
