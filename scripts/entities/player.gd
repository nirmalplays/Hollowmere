class_name Player
extends CharacterBody2D
## The Unlaid player. Movement + a state machine of committed actions (GAME_PLAN 5).
## Host-authority aware (GAME_PLAN 9): the authority peer runs the state machine and
## resolves hits; solo is peer 1 with no other peers, through the same code path.

signal facing_changed(direction: Vector2)
signal respawned
signal flasks_changed(charges: int, max_charges: int)

const CHEST_HEIGHT: float = 18.0
const REST_RANGE: float = 40.0  ## pixels above the feet where blows land
const HIT_COLOR := Color(1.0, 0.55, 0.45)
const BLOCK_COLOR := Color(0.75, 0.8, 0.9)

@export var tuning: MovementTuning
@export var combat: CombatTuning
@export var sprite_sheet: SpriteSheetDef
@export var weapon: WeaponData
@export var hit_fx: FxDef
@export var parry_fx: FxDef

var peer_id: int = Const.SOLO_PEER_ID
var facing: Vector2 = Vector2.DOWN
var spawn_point: Vector2 = Vector2.ZERO  ## the Hearth this player rises at
var flasks: int = 3

@onready var input: PlayerInput = $Input
@onready var stats: CombatStats = $Stats
@onready var states: PlayerStateMachine = $States
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var _camera: Camera2D = $Camera
@onready var _animator := CharacterAnimator.new($Sprite)


func _ready() -> void:
	add_to_group(&"players")
	add_child(Prop.make_shadow(0.55))  # soft ground shadow under the feet
	set_multiplayer_authority(peer_id)
	spawn_point = global_position
	sprite.sprite_frames = SpriteFramesBuilder.build(sprite_sheet)
	sprite.offset = sprite_sheet.foot_offset()
	_camera.enabled = input.is_local()
	if _camera.enabled:
		_camera.make_current()
	stats.tuning = combat
	stats.reset()
	flasks = combat.flask_charges
	hitbox.hit_landed.connect(_on_hit_landed)
	states.setup(self)
	# The lantern only lights once it is carried (ACT1_MQ01 O1; the glade assumes it is).
	$Lantern.visible = GameState.flags.get(&"has_cradle_lantern", true)
	EventBus.story_flag_changed.connect(func(flag: StringName, value: Variant) -> void:
		if flag == &"has_cradle_lantern":
			$Lantern.visible = bool(value))


func _physics_process(delta: float) -> void:
	input.gather(delta)
	if not is_multiplayer_authority():
		return  # remote replicas are driven by synced state (M11)
	states.physics_update(delta)
	var regen := states.current.stamina_regen_mult()
	if regen > 0.0:
		stats.regen(delta, regen)


# --- movement helpers for states -------------------------------------------

func move_with_input(delta: float, speed_mult: float = 1.0) -> void:
	var move := input.move
	if move != Vector2.ZERO:
		var target := move.limit_length(1.0) * tuning.max_speed * speed_mult
		velocity = velocity.move_toward(target, tuning.acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, tuning.friction * delta)
	move_and_slide()


func brake(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, tuning.friction * delta)
	move_and_slide()


## Real velocity, not requested: pushing into a wall counts as standing still.
func is_moving() -> bool:
	return get_real_velocity().length() > tuning.max_speed * 0.1


## Walking decides where the character looks. The mouse only aims actions (attack,
## block), never the walk: otherwise brushing the mouse spins the character around
## mid-stride. A gamepad's right stick still turns the character on purpose.
func update_facing(aim_too: bool = false) -> void:
	var want := input.move
	if input.aim != Vector2.ZERO and (aim_too or input.aim_is_stick):
		want = input.aim
	if want != Vector2.ZERO:
		face(want)


func face(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return
	var n := direction.normalized()
	if not n.is_equal_approx(facing):
		facing = n
		facing_changed.emit(facing)


func aim_direction() -> Vector2:
	if input.aim != Vector2.ZERO:
		return input.aim
	if input.move != Vector2.ZERO:
		return input.move.normalized()
	return facing


func chest_position() -> Vector2:
	return global_position + Vector2(0.0, -CHEST_HEIGHT)


func set_camera_limits(rect: Rect2i) -> void:
	_camera.limit_left = rect.position.x
	_camera.limit_top = rect.position.y
	_camera.limit_right = rect.end.x
	_camera.limit_bottom = rect.end.y


# --- actions ------------------------------------------------------------------

## From a free state (Idle/Move): dodge, attack or block, if the input and stamina allow.
func try_start_action() -> bool:
	if try_start_attack_or_dodge():
		return true
	if input.block_held:
		states.transition(&"Block")
		return true
	return false


func try_start_attack_or_dodge() -> bool:
	if input.consume(&"interact") and _try_rest():
		return true
	if input.consume(&"heal"):
		if flasks > 0:
			states.transition(&"Heal")
			return true
		Fx.text(chest_position() + Vector2(0, -20), "Flask empty", Color(0.7, 0.7, 0.7), self)
	if not stats.can_act():
		return false
	if input.consume(&"dodge"):
		states.transition(&"Dodge")
		return true
	if input.consume(&"attack_heavy"):
		states.transition(&"Attack", {"attack": weapon.heavy})
		return true
	if input.consume(&"attack_light"):
		states.transition(&"Attack", {"attack": weapon.light})
		return true
	return false


## The Rest (STORY_BIBLE 4): with the Cradle Lantern, lay a staggered Hollowed to rest.
func _try_rest() -> bool:
	if not GameState.flags.get(&"has_cradle_lantern", false):
		return false
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy and enemy.can_rest() and enemy.global_position.distance_to(global_position) < REST_RANGE:
			face(enemy.global_position - global_position)
			play_timed(&"attack", 0.5)
			enemy.rest(self)
			return true
	return false


func make_damage_info(attack: AttackData) -> DamageInfo:
	var info := DamageInfo.new()
	info.source = self
	info.amount = attack_power() * attack.damage_mult
	info.damage_type = attack.damage_type
	info.poise_damage = attack.poise_damage
	info.knockback = attack.knockback
	info.attack_id = attack.id
	return info


## Base damage before attack multipliers. M3 adds attribute scaling.
func attack_power() -> float:
	return weapon.base_damage


# --- taking hits --------------------------------------------------------------

## Called by the Hurtbox on the host. Returns a DamageInfo.Result.
func receive_hit(info: DamageInfo) -> int:
	var result := states.current.on_hit(info)
	if result == DamageInfo.Result.IGNORED:
		return result
	if result == DamageInfo.Result.PARRIED:
		_on_parry(info)
		return result
	var blocked := result == DamageInfo.Result.BLOCKED
	var reduction := weapon.block_reduction if blocked else 0.0
	if blocked:
		stats.spend_stamina(info.amount * weapon.block_stamina_per_damage)
	AudioManager.sfx(&"block" if blocked else &"player_hurt", -2.0, 0.1)
	var dmg := DamageCalc.from_info(info, combat.defense, combat.resistances, reduction)
	stats.take_damage(dmg)
	EventBus.damage_dealt.emit(info.source, self, dmg, info.damage_type)
	Fx.text(chest_position() + Vector2(0, -16), str(dmg), BLOCK_COLOR if blocked else HIT_COLOR, self)
	Flash.hit(sprite, Color.WHITE, 0.15)
	Fx.spawn(hit_fx, chest_position(), info.direction, self)
	if stats.is_dead():
		AudioManager.sfx(&"player_death")
		states.transition(&"Dead")
		return DamageInfo.Result.HIT
	if blocked:
		if stats.exhausted:
			states.transition(&"Stagger", {"duration": combat.guard_break_duration})
			HitFeedback.shake(2.0, 0.2)
		else:
			velocity = info.direction * info.knockback * 0.4
		return DamageInfo.Result.BLOCKED
	states.transition(&"Hurt", {"knockback": info.direction * info.knockback})
	HitFeedback.hit_stop(0.06)
	HitFeedback.shake(2.0, 0.15)
	return DamageInfo.Result.HIT


func _on_parry(info: DamageInfo) -> void:
	states.transition(&"Parry")
	AudioManager.sfx(&"parry")
	AudioManager.sfx(&"block", -3.0, 0.1, 0)
	Fx.spawn(parry_fx, chest_position() - info.direction * 8.0, Vector2.RIGHT, self)
	HitFeedback.hit_stop(0.12)
	HitFeedback.shake(3.0, 0.2)
	if is_instance_valid(info.source) and info.source.has_method(&"on_parried"):
		info.source.on_parried(self)


## Our own attack connected (or was blocked/parried by the target).
func _on_hit_landed(_target: Node, result: int, _info: DamageInfo) -> void:
	var attack: AttackData = (states.current as Node).get(&"attack") if states.current_name() == &"Attack" else null
	match result:
		DamageInfo.Result.HIT, DamageInfo.Result.BLOCKED:
			if attack:
				HitFeedback.hit_stop(attack.hit_stop_ms / 1000.0)
				HitFeedback.shake(attack.shake, 0.12)
		DamageInfo.Result.PARRIED:
			states.transition(&"Stagger", {"duration": combat.parried_stagger_duration})


## Rise at the Hearth (STORY_BIBLE 4). Pressure/Scars come with M7.
func respawn() -> void:
	global_position = spawn_point
	velocity = Vector2.ZERO
	facing = Vector2.DOWN
	stats.reset()
	flasks = combat.flask_charges  # the Hearth refills the flask
	flasks_changed.emit(flasks, combat.flask_charges)
	input.clear_buffer()
	Flash.clear(sprite)
	AudioManager.sfx(&"respawn", -3.0, 0.0)
	states.transition(&"Idle")
	respawned.emit()


## A death the story demands (ACT1_MQ01 O6): no Pressure, no Scar.
func die_scripted() -> void:
	if stats.is_dead():
		return
	stats.take_damage(int(ceil(stats.hp)))
	AudioManager.sfx(&"player_death")
	states.transition(&"Dead")


# --- animation ----------------------------------------------------------------

## Plays "<base>_<dir>" for the current facing (8 directions).
func play_directional(base: StringName, speed: float = 1.0, restart: bool = false) -> void:
	_animator.play(base, facing, speed, restart)


## Plays an animation stretched to last `seconds` (attacks timed to their data).
func play_timed(base: StringName, seconds: float) -> void:
	_animator.play_timed(base, facing, seconds)
