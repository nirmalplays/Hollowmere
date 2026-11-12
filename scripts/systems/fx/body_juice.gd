class_name BodyJuice
extends Node
## Makes a body look alive without a single extra frame of art: it leans into its
## movement, squashes and stretches on every action and springs back, leaves ghosts
## behind a dash, and kicks up dust. One per character; states call `punch`, `ghosts`,
## `dust`. Works on the character's AnimatedSprite2D, whose origin is at the feet, so
## scaling plants on the ground.

const LEAN: float = 0.085  ## radians at full speed
const SPRING: float = 190.0
const DAMPING: float = 15.0
const GHOST_GAP: float = 0.028

var sprite: AnimatedSprite2D
var body: CharacterBody2D
var top_speed: float = 120.0

var _base: Vector2 = Vector2.ONE
var _scale: Vector2 = Vector2.ONE  ## multiplier on the base scale, sprung toward ONE
var _vel: Vector2 = Vector2.ZERO
var _ghost_left: float = 0.0
var _ghost_tick: float = 0.0
var _ghost_tint := Color(0.6, 0.8, 1.0)
var _bob: float = 0.0


func setup(owner_body: CharacterBody2D, target: AnimatedSprite2D, speed: float) -> void:
	body = owner_body
	sprite = target
	top_speed = maxf(speed, 1.0)
	_base = target.scale


## Knock the shape away from rest; it springs back. (1.2, 0.8) = wide and short.
func punch(shape: Vector2) -> void:
	_scale = shape
	_vel = Vector2.ZERO


## Leave fading copies of the body behind for `seconds` (a dash, a lunge).
func ghosts(seconds: float, tint: Color = Color(0.6, 0.8, 1.0)) -> void:
	_ghost_left = seconds
	_ghost_tick = 0.0
	_ghost_tint = tint


## A few puffs kicked up at the feet, thrown opposite to `direction`.
func dust(direction: Vector2, amount: int = 6) -> void:
	if body == null or not body.is_inside_tree():
		return
	var p := CPUParticles2D.new()
	p.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	p.one_shot = true
	p.emitting = true
	p.amount = amount
	p.lifetime = 0.42
	p.explosiveness = 0.9
	p.direction = -direction if direction != Vector2.ZERO else Vector2.UP
	p.spread = 55.0
	p.gravity = Vector2(0, -20)
	p.initial_velocity_min = 22.0
	p.initial_velocity_max = 54.0
	p.damping_min = 60.0
	p.damping_max = 90.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.5
	p.color = Color(0.74, 0.7, 0.6, 0.6)
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	p.color_ramp = fade
	p.z_index = -1
	body.get_parent().add_child(p)
	p.global_position = body.global_position
	p.finished.connect(p.queue_free)


func _process(delta: float) -> void:
	if sprite == null:
		return
	# A damped spring pulls the shape back to rest. Stepped in small slices: one long
	# frame (a hitch when the first hit compiles its effects) would otherwise fling the
	# spring to infinity and every body would vanish.
	var left := minf(delta, 0.1)
	while left > 0.0:
		var dt := minf(left, 1.0 / 120.0)
		left -= dt
		_vel += ((Vector2.ONE - _scale) * SPRING - _vel * DAMPING) * dt
		_scale += _vel * dt
	if not (_scale.is_finite() and _vel.is_finite()):
		_scale = Vector2.ONE
		_vel = Vector2.ZERO
	_scale = _scale.clamp(Vector2(0.5, 0.5), Vector2(1.6, 1.6))
	# The body's own velocity, never get_real_velocity(): during hit-stop time stands
	# still, the engine divides movement by zero seconds, and the NaN that comes back
	# would poison the scale and rotation for good (the body vanishes).
	var moving: Vector2 = body.velocity if body else Vector2.ZERO
	if not moving.is_finite():
		moving = Vector2.ZERO
	var speed := moving.length()
	# A walker's bounce: a small rise and fall in step with the stride.
	_bob += delta * (5.0 + speed * 0.09)
	var bounce := 1.0 + 0.022 * sin(_bob * 2.0) * clampf(speed / top_speed, 0.0, 1.0) + 0.012 * sin(_bob * 0.45)
	sprite.scale = _base * Vector2(_scale.x * (2.0 - bounce), _scale.y * bounce)
	var lean := clampf(moving.x / top_speed, -1.4, 1.4) * LEAN
	if not is_finite(sprite.rotation):
		sprite.rotation = 0.0
	if not is_finite(_bob):
		_bob = 0.0
	sprite.rotation = lerp_angle(sprite.rotation, lean, 1.0 - exp(-14.0 * delta))
	if _ghost_left > 0.0:
		_ghost_left -= delta
		_ghost_tick -= delta
		if _ghost_tick <= 0.0:
			_ghost_tick = GHOST_GAP
			_spawn_ghost()


func _spawn_ghost() -> void:
	if sprite.sprite_frames == null or not body.is_inside_tree():
		return
	var ghost := Sprite2D.new()
	ghost.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	ghost.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	ghost.offset = sprite.offset
	ghost.scale = sprite.scale
	ghost.rotation = sprite.rotation
	ghost.modulate = Color(_ghost_tint, 0.5)
	body.get_parent().add_child(ghost)
	ghost.global_position = body.global_position
	ghost.z_index = -1
	var tw := ghost.create_tween()
	tw.tween_property(ghost, ^"modulate:a", 0.0, 0.22)
	tw.tween_callback(ghost.queue_free)
