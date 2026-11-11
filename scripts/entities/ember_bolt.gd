class_name EmberBolt
extends Node2D
## A thrown ember from the Cradle Lantern: the Unlaid's ranged answer. Flies straight,
## lights the cave as it goes, bursts on the first Hollowed or wall it meets.

const SPEED: float = 330.0
const LIFE: float = 0.85
const RADIUS: float = 6.0
const CORE := Color(1.0, 0.93, 0.7)
const GLOW := Color(1.0, 0.6, 0.22)

var direction: Vector2 = Vector2.RIGHT
var info: DamageInfo
var hit_fx: FxDef

var _hitbox: Hitbox
var _age: float = 0.0
var _trail: Array[Vector2] = []
var _done: bool = false


func _ready() -> void:
	_hitbox = Hitbox.new()
	_hitbox.team = 0
	add_child(_hitbox)
	_hitbox.shape_circle(RADIUS, 0.0)
	_hitbox.hit_landed.connect(func(_t: Node, _r: int, _i: DamageInfo) -> void: _burst())
	_hitbox.activate(info)
	add_child(Prop.make_light(GLOW, 1.3, 0.55, Vector2.ZERO))


func _physics_process(delta: float) -> void:
	if _done:
		return
	_age += delta
	var step := direction * SPEED * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + step + direction * RADIUS, Const.LAYER_WORLD)
	# The bolt flies at chest height; walls are tested at the feet line below it.
	query.from += Vector2(0, Player.CHEST_HEIGHT)
	query.to += Vector2(0, Player.CHEST_HEIGHT)
	if get_world_2d().direct_space_state.intersect_ray(query) or _age >= LIFE:
		_burst()
		return
	_trail.push_front(global_position)
	if _trail.size() > 7:
		_trail.pop_back()
	global_position += step
	queue_redraw()


func _draw() -> void:
	for i in _trail.size():
		var k := 1.0 - float(i) / _trail.size()
		draw_circle(to_local(_trail[i]), 3.0 * k, Color(GLOW, 0.5 * k))
	var flick := 0.85 + 0.15 * sin(_age * 40.0)
	draw_circle(Vector2.ZERO, 7.0 * flick, Color(GLOW, 0.35))
	draw_circle(Vector2.ZERO, 4.0, GLOW)
	draw_circle(Vector2.ZERO, 2.0, CORE)


func _burst() -> void:
	if _done:
		return
	_done = true
	_hitbox.deactivate()
	Fx.spawn(hit_fx, global_position, direction, self)
	queue_free()
