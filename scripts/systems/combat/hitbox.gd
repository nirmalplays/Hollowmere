class_name Hitbox
extends Area2D
## Deals a DamageInfo to every overlapping enemy Hurtbox, once per activation.
## Only the host resolves hits (GAME_PLAN 9.1); clients just see the results.

signal hit_landed(target: Node, result: int, info: DamageInfo)

@export var team: int = 0

var active: bool = false

var _template: DamageInfo
var _already_hit: Array[Node] = []
var _shape_node: CollisionShape2D


func _ready() -> void:
	collision_layer = Const.LAYER_HITBOX
	collision_mask = Const.LAYER_HURTBOX
	monitorable = false
	_shape_node = CollisionShape2D.new()
	add_child(_shape_node)
	active = false


## A rectangle in front of the body: `dir` points forward, `height` lifts it to chest level.
func shape_rect(size: Vector2, dir: Vector2, reach: float, height: float) -> void:
	var rect := RectangleShape2D.new()
	rect.size = size
	_shape_node.shape = rect
	position = Vector2(0.0, -height) + dir * reach
	rotation = dir.angle()


func shape_circle(radius: float, height: float) -> void:
	var circle := CircleShape2D.new()
	circle.radius = radius
	_shape_node.shape = circle
	position = Vector2(0.0, -height)
	rotation = 0.0


func activate(info: DamageInfo) -> void:
	_template = info
	_already_hit.clear()
	active = true


func deactivate() -> void:
	active = false


func _physics_process(_delta: float) -> void:
	if not active or not NetManager.is_host():
		return
	for area in get_overlapping_areas():
		var hurtbox := area as Hurtbox
		if hurtbox == null or hurtbox.team == team or not hurtbox.enabled:
			continue
		var target := hurtbox.entity
		if target in _already_hit:
			continue
		_already_hit.append(target)
		var origin := global_position
		if is_instance_valid(_template.source):
			origin = (_template.source as Node2D).global_position
		var info := _template.aimed_at(target as Node2D, origin)
		var result := hurtbox.receive(info)
		hit_landed.emit(target, result, info)
