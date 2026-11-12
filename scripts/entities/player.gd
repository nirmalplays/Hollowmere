class_name Player
extends CharacterBody2D
## The Unlaid player. Movement + a state machine of committed actions (GAME_PLAN 5).
## Host-authority aware (GAME_PLAN 9): the authority peer runs the state machine and
## resolves hits; solo is peer 1 with no other peers, through the same code path.

signal facing_changed(direction: Vector2)
signal respawned
signal flasks_changed(charges: int, max_charges: int)
signal ember_thrown
signal echoes_changed(total: int)

const CHEST_HEIGHT: float = 18.0
const REST_RANGE: float = 62.0
const EMBER_STATES: Array[StringName] = [&"Idle", &"Move", &"Attack", &"Block"]  ## pixels above the feet where blows land
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
var ember_cooldown: float = 0.0  ## seconds until the ability is ready again
var hero: Dictionary = {}  ## {"name", "origin", "class"}; empty = the plain Unlaid (tests)
var ability: String = "ember"  ## what the ability key does (the class decides)
var ability_name: String = "Lantern Ember"
var ability_cooldown: float = 0.9
var echoes: int = 0  ## what the Hollowed left behind; spent at a fire
var levels: Dictionary = {}  ## attribute id -> levels kindled

var _base_hp: float = 100.0
var _base_stamina: float = 100.0
var _base_regen: float = 45.0
var _base_cooldown: float = 0.9
var _base_flask: float = 0.4

@onready var input: PlayerInput = $Input
@onready var stats: CombatStats = $Stats
@onready var states: PlayerStateMachine = $States
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var _camera: Camera2D = $Camera
@onready var _animator := CharacterAnimator.new($Sprite)

var juice: BodyJuice  ## lean, squash, ghosts, dust


func _ready() -> void:
	add_to_group(&"players")
	add_child(Prop.make_shadow(0.55))  # soft ground shadow under the feet
	set_multiplayer_authority(peer_id)
	spawn_point = global_position
	_apply_hero(GameState.players.get(peer_id, {}))
	if combat.resource_path != "":
		combat = combat.duplicate()  # levels change it; never the shared file
	_base_hp = combat.max_hp
	_base_stamina = combat.max_stamina
	_base_regen = combat.stamina_regen
	_base_cooldown = ability_cooldown
	_base_flask = combat.flask_heal_fraction
	echoes = int(hero.get("echoes", 0))
	for key: String in hero.get("levels", {}):
		levels[key] = int(hero["levels"][key])
	_apply_levels()
	sprite.sprite_frames = SpriteFramesBuilder.build(sprite_sheet)
	sprite.offset = sprite_sheet.foot_offset()
	_camera.enabled = input.is_local()
	if _camera.enabled:
		_camera.make_current()
	add_child(Prop.make_light(Color(0.9, 0.93, 1.0), 1.25, 0.42, Vector2(0, -CHEST_HEIGHT)))
	juice = BodyJuice.new()
	add_child(juice)
	juice.setup(self, sprite, tuning.max_speed)
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
	ember_cooldown = maxf(0.0, ember_cooldown - delta)
	if input.consume(&"spell_1"):
		_throw_ember()
	if states.current_name() in EMBER_STATES and rest_target() != null and input.consume(&"interact"):
		_try_rest()
	states.physics_update(delta)
	var regen := states.current.stamina_regen_mult()
	if regen > 0.0:
		stats.regen(delta, regen)


## Who this Unlaid was: the origin shapes the body, the class the kit (data/heroes).
## Tuning resources are shared, so a hero works on its own copies.
func _apply_hero(profile: Dictionary) -> void:
	if not profile.has("class"):
		return
	hero = profile
	var o := Heroes.origin(profile.get("origin", ""))
	var c := Heroes.hero_class(profile["class"])
	combat = combat.duplicate()
	tuning = tuning.duplicate()
	combat.max_hp = roundf(combat.max_hp * float(o["hp"]) * float(c["hp"]))
	combat.max_stamina = roundf(combat.max_stamina * float(o["stamina"]) * float(c["stamina"]))
	combat.stamina_regen *= float(o["regen"])
	combat.defense += float(o["defense"])
	combat.flask_charges += int(o["flasks"])
	tuning.max_speed *= float(o["speed"]) * float(c["speed"])
	weapon = load(c["weapon"])
	ability = c["ability"]
	ability_name = c["ability_name"]
	ability_cooldown = float(c["ability_cooldown"])
	if ResourceLoader.exists(Heroes.sheet_path(profile)):
		sprite_sheet = load(Heroes.sheet_path(profile))
	sprite.scale *= float(o["scale"])


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
		states.transition(&"Attack", {"attack": weapon.combo_attack(0), "step": 0})
		return true
	return false


## The staggered Hollowed the lantern could lay to rest right now, nearest first.
func rest_target() -> Enemy:
	if not GameState.flags.get(&"has_cradle_lantern", false):
		return null
	var best: Enemy = null
	var best_d := REST_RANGE
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy and enemy.can_rest():
			var d := enemy.global_position.distance_to(global_position)
			if d < best_d:
				best_d = d
				best = enemy
	return best


## The Rest (STORY_BIBLE 4): with the Cradle Lantern, lay a staggered Hollowed to rest.
func _try_rest() -> bool:
	var enemy := rest_target()
	if enemy == null:
		return false
	face(enemy.global_position - global_position)
	if states.current_name() != &"Idle":
		states.transition(&"Idle")
	play_timed(&"attack", 0.5)
	juice.punch(Vector2(0.85, 1.18))
	HitFeedback.hit_stop(0.09)
	enemy.rest(self)
	return true


## The ability key. It never locks you in place: use it walking, between swings, behind
## your guard. What it does comes from the class; all of it runs on the Cradle Lantern.
func _throw_ember() -> void:
	if ember_cooldown > 0.0 or not states.current_name() in EMBER_STATES:
		return
	if not GameState.flags.get(&"has_cradle_lantern", false):
		return
	ember_cooldown = ability_cooldown
	var dir := aim_direction()
	match ability:
		"slam":
			_slam()
		"lance":
			throw_bolt(dir, _ability_info(24.0, 30.0, 120.0), {"speed": 430.0, "life": 1.1, "radius": 10.0})
		"fan":
			for turn: float in [-0.24, 0.0, 0.24]:
				throw_bolt(dir.rotated(turn), _ability_info(8.0, 6.0, 30.0, &"physical"), {"speed": 400.0, "life": 0.6, "radius": 5.0, "blade": true})
		_:
			throw_bolt(dir, _ability_info(10.0, 8.0, 40.0))
	AudioManager.sfx(&"hit_heavy" if ability == "slam" else &"spell_cast", -4.0, 0.2)
	ember_thrown.emit()


func _ability_info(amount: float, poise: float, knock: float, type: StringName = &"fire") -> DamageInfo:
	var info := DamageInfo.new()
	info.source = self
	info.amount = amount * (1.0 + 0.1 * attribute_level("intellect"))
	info.damage_type = type
	info.poise_damage = poise
	info.knockback = knock
	info.attack_id = &"ability"
	return info


## Looses a bolt from the chest. `shape` may set speed, life, radius, blade.
func throw_bolt(dir: Vector2, info: DamageInfo, shape: Dictionary = {}) -> void:
	var bolt := EmberBolt.new()
	bolt.direction = dir
	bolt.hit_fx = hit_fx
	bolt.info = info
	for key: String in shape:
		bolt.set(key, shape[key])
	get_parent().add_child(bolt)
	bolt.global_position = chest_position() + dir * 10.0
	bolt.reset_physics_interpolation()


## Grave Slam: a ring of force around you. Hits everything close, staggers the light.
func _slam() -> void:
	var ring := Hitbox.new()
	ring.team = hitbox.team
	add_child(ring)
	ring.shape_circle(52.0, CHEST_HEIGHT * 0.5)
	ring.activate(_ability_info(18.0, 45.0, 190.0, &"physical"))
	get_tree().create_timer(0.12).timeout.connect(ring.queue_free)
	HitFeedback.shake(4.0, 0.25)
	Fx.spawn(parry_fx, global_position + Vector2(0, -6), Vector2.RIGHT, self)
	var flash := Prop.make_light(Color(1.0, 0.7, 0.4), 2.2, 1.1, Vector2(0, -8))
	add_child(flash)
	var tw := create_tween()
	tw.tween_property(flash, ^"energy", 0.0, 0.35)
	tw.tween_callback(flash.queue_free)


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
	return weapon.base_damage * (1.0 + 0.08 * attribute_level("might"))


# --- echoes and kindling ----------------------------------------------------------

func attribute_level(id: String) -> int:
	return int(levels.get(id, 0))


func kindle_cost() -> int:
	var total := 0
	for key: String in levels:
		total += int(levels[key])
	return 30 + total * 18


func gain_echoes(amount: int) -> void:
	echoes += amount
	_store_progress()
	echoes_changed.emit(echoes)
	AudioManager.sfx(&"coins", -16.0, 0.2)


## Spend Echoes on one more level of an attribute (at a fire). False if you can't.
func raise_attribute(id: String) -> bool:
	var cost := kindle_cost()
	if echoes < cost or attribute_level(id) >= 10:
		return false
	echoes -= cost
	levels[id] = attribute_level(id) + 1
	_apply_levels()
	stats.heal(combat.max_hp)
	_store_progress()
	echoes_changed.emit(echoes)
	return true


func _apply_levels() -> void:
	combat.max_hp = _base_hp + 12.0 * attribute_level("vitality")
	combat.max_stamina = _base_stamina + 8.0 * attribute_level("agility")
	combat.stamina_regen = _base_regen * (1.0 + 0.06 * attribute_level("agility"))
	combat.flask_heal_fraction = _base_flask + 0.04 * attribute_level("spirit")
	ability_cooldown = _base_cooldown * pow(0.95, attribute_level("intellect"))
	if stats and stats.tuning:
		stats.hp_changed.emit(stats.hp, combat.max_hp)
		stats.stamina_changed.emit(stats.stamina, combat.max_stamina)


## Progress rides in the hero profile, which is what a journey saves.
func _store_progress() -> void:
	if GameState.players.has(peer_id):
		GameState.players[peer_id]["echoes"] = echoes
		GameState.players[peer_id]["levels"] = levels.duplicate()


## [label, value] rows for the fire's ledger.
func stat_lines() -> Array:
	return [
		["Health", str(int(combat.max_hp))],
		["Stamina", str(int(combat.max_stamina))],
		["Blade damage", "%.0f" % attack_power()],
		["%s every" % ability_name, "%.1f s" % ability_cooldown],
		["Flask mends", "%d%%" % int(combat.flask_heal_fraction * 100.0)],
	]


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
	AudioManager.sfx(&"hit_armor" if blocked else &"hit_flesh", -2.0, 0.1)
	if not blocked:
		AudioManager.sfx(&"voice_hurt", -4.0, 0.1, 150)
	var dmg := DamageCalc.from_info(info, combat.defense, combat.resistances, reduction)
	stats.take_damage(dmg)
	EventBus.damage_dealt.emit(info.source, self, dmg, info.damage_type)
	Fx.text(chest_position() + Vector2(0, -16), str(dmg), BLOCK_COLOR if blocked else HIT_COLOR, self)
	Flash.hit(sprite, Color.WHITE, 0.15)
	Fx.spawn(hit_fx, chest_position(), info.direction, self)
	juice.punch(Vector2(0.86, 1.14) if blocked else Vector2(1.28, 0.74))
	if stats.is_dead():
		AudioManager.sfx(&"voice_death")
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
	AudioManager.sfx(&"parry_clang")
	AudioManager.sfx(&"hit_armor", -3.0, 0.1, 0)
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
	reset_physics_interpolation()
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
	AudioManager.sfx(&"voice_death")
	states.transition(&"Dead")


# --- animation ----------------------------------------------------------------

## Plays "<base>_<dir>" for the current facing (8 directions).
func play_directional(base: StringName, speed: float = 1.0, restart: bool = false) -> void:
	_animator.play(base, facing, speed, restart)


## Plays an animation stretched to last `seconds` (attacks timed to their data).
func play_timed(base: StringName, seconds: float) -> void:
	_animator.play_timed(base, facing, seconds)
