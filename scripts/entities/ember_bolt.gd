class_name EmberBolt
extends Node2D
## Something thrown that flies straight, lights its way and bursts on the first Hollowed
## or tree it meets: the lantern's ember, a staff bolt, a cinder lance, a thrown knife.

const CORE := Color(1.0, 0.93, 0.7)

var direction: Vector2 = Vector2.RIGHT
var info: DamageInfo
var hit_fx: FxDef
var speed: float = 330.0
var life: float = 0.85
var radius: float = 6.0
var glow := Color(1.0, 0.6, 0.22)
var blade: bool = false  ## drawn as a spinning knife, no light

var _hitbox: Hitbox
var _age: float = 0.0
var _trail: Array[Vector2] = []
var _done: bool = false


func _ready() -> void:
	_hitbox = Hitbox.new()
	_hitbox.team = 0
	add_child(_hitbox)
	_hitbox.shape_circle(radius, 0.0)
	_hitbox.hit_landed.connect(func(_t: Node, _r: int, _i: DamageInfo) -> void: _burst())
	_hitbox.activate(info)
	if not blade:
		add_child(Prop.make_light(glow, 1.3, 0.4 + radius * 0.03, Vector2.ZERO))


func _physics_process(delta: float) -> void:
	if _done:
		return
	_age += delta
	var step := direction * speed * delta
	# It flies at chest height; walls and trunks are tested on the ground line below it.
	var foot := Vector2(0, Player.CHEST_HEIGHT)
	var query := PhysicsRayQueryParameters2D.create(global_position + foot, global_position + foot + step + direction * radius, Const.LAYER_WORLD)
	if get_world_2d().direct_space_state.intersect_ray(query) or _age >= life:
		_burst()
		return
	_trail.push_front(global_position)
	if _trail.size() > 7:
		_trail.pop_back()
	global_position += step
	queue_redraw()


func _draw() -> void:
	if blade:
		var spin := _age * 30.0
		var tip := Vector2(cos(spin), sin(spin)) * 6.0
		draw_line(-tip, tip, Color(0.86, 0.9, 0.95), 2.0)
		draw_line(-tip, -tip * 0.4, Color(0.45, 0.3, 0.2), 2.0)
		return
	var k0 := radius / 6.0
	for i in _trail.size():
		var k := 1.0 - float(i) / _trail.size()
		draw_circle(to_local(_trail[i]), 3.0 * k * k0, Color(glow, 0.5 * k))
	var flick := 0.85 + 0.15 * sin(_age * 40.0)
	draw_circle(Vector2.ZERO, 7.0 * flick * k0, Color(glow, 0.35))
	draw_circle(Vector2.ZERO, 4.0 * k0, glow)
	draw_circle(Vector2.ZERO, 2.0 * k0, CORE)


func _burst() -> void:
	if _done:
		return
	_done = true
	_hitbox.deactivate()
	Fx.spawn(hit_fx, global_position, direction, self)
	queue_free()
