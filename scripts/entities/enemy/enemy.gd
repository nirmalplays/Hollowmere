class_name Enemy
extends CharacterBody2D
## Data-driven enemy (GAME_PLAN 5.6). Chases targets in its aggro radius and walks
## home past its leash; telegraphs attacks (around itself, in front, or on the
## ground where you stand); has poise, can be parried, can carry a shield, and can be
## laid to rest with the Cradle Lantern while staggered (STORY_BIBLE 4).
## Bosses switch to phase-2 attacks and summon below a health fraction.
## All decisions run on the host only.

signal health_changed(hp: float, max_hp: float)
signal state_changed(state: int)
signal rested

enum State { IDLE, CHASE, RETURN, TELEGRAPH, ACTIVE, RECOVER, STAGGER, DEAD }

const BODY_HEIGHT: float = 18.0
const CRIT_COLOR := Color(1.0, 0.88, 0.54)
const HIT_COLOR := Color(0.96, 0.95, 0.92)
const BLOCK_COLOR := Color(0.75, 0.8, 0.9)
const ACCEL: float = 600.0
const REST_FX_COLOR := Color(1.0, 0.85, 0.5)

@export var data: EnemyData
## Set by area scripts to keep an enemy asleep until its moment (tutorial beats).
@export var dormant: bool = false

var hp: float = 0.0
var poise: float = 0.0
var state: State = State.IDLE
var state_time: float = 0.0  ## seconds in the current state
var facing: Vector2 = Vector2.DOWN
var home: Vector2 = Vector2.ZERO
var phase: int = 1

var _attack: EnemyAttackData
var _cooldowns: Dictionary = {}  # attack id -> seconds left
var _poise_delay: float = 0.0
var _last_attacker: Node
var _target: Node2D
var _target_at: Vector2 = Vector2.ZERO  ## where AT_TARGET pits land
var _was_rested: bool = false
var _announced: bool = false

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var marker: TelegraphMarker = $TelegraphMarker
@onready var _animator := CharacterAnimator.new($Sprite)


func _ready() -> void:
	add_to_group(&"enemies")
	add_child(Prop.make_shadow(0.55))
	home = global_position
	sprite.sprite_frames = SpriteFramesBuilder.build(data.sprite_sheet)
	sprite.offset = data.sprite_sheet.foot_offset()
	hitbox.hit_landed.connect(_on_hit_landed)
	marker.hide_marker()
	_reset_pools()
	_enter(State.IDLE)


func _physics_process(delta: float) -> void:
	state_time += delta
	for id: StringName in _cooldowns.keys():
		_cooldowns[id] = maxf(0.0, _cooldowns[id] - delta)
	_regen_poise(delta)
	if not NetManager.is_host() or dormant:
		return
	var ms := state_time * 1000.0
	match state:
		State.IDLE:
			_target = _nearest_player(data.aggro_radius)
			if _target and not _try_attack() and data.move_speed > 0.0:
				_enter(State.CHASE)
			_brake(delta)
		State.CHASE:
			_chase(delta)
		State.RETURN:
			_walk_toward(home, delta)
			if global_position.distance_to(home) < 6.0:
				_enter(State.IDLE)
		State.TELEGRAPH:
			marker.progress = ms / _attack.telegraph_ms
			_brake(delta)
			if ms >= _attack.telegraph_ms:
				_enter(State.ACTIVE)
		State.ACTIVE:
			_brake(delta)
			if ms >= _attack.active_ms:
				_enter(State.RECOVER)
		State.RECOVER:
			_brake(delta)
			if ms >= _attack.recovery_ms:
				_enter(State.IDLE)
		State.STAGGER:
			_brake(delta)
			if ms >= data.stagger_ms:
				_enter(State.IDLE)
		State.DEAD:
			if data.revive_ms >= 0 and not _was_rested and ms >= data.revive_ms:
				_reset_pools()
				hurtbox.enabled = true
				_enter(State.IDLE)


func is_staggered() -> bool:
	return state == State.STAGGER


func is_dead() -> bool:
	return state == State.DEAD


## True when the Cradle Lantern can lay this one to rest right now.
func can_rest() -> bool:
	return data.restable and state == State.STAGGER


## The Rest: a Lantern-lit finishing blow that lets the soul pass (lowers Pressure).
func rest(by: Node) -> void:
	if not can_rest():
		return
	_was_rested = true
	_last_attacker = by
	hp = 0.0
	health_changed.emit(hp, data.max_hp)
	Fx.text(global_position + Vector2(0, -BODY_HEIGHT - 18), "Rest", REST_FX_COLOR, self)
	AudioManager.sfx_at(&"pickup", global_position, -4.0, 0.0)
	var glow := Prop.make_light(REST_FX_COLOR, 2.0, 0.8, Vector2(0, -BODY_HEIGHT))
	add_child(glow)
	create_tween().tween_property(glow, ^"energy", 0.0, 1.5)
	create_tween().tween_property(sprite, ^"modulate", Color(1, 0.95, 0.8, 0.0), 1.6)
	EventBus.enemy_rested.emit(self, by)
	rested.emit()
	_enter(State.DEAD)


# --- decisions -----------------------------------------------------------------

func _chase(delta: float) -> void:
	if _target == null or not is_instance_valid(_target) or (_target as Player and (_target as Player).stats.is_dead()):
		_enter(State.RETURN)
		return
	if global_position.distance_to(home) > data.leash_radius:
		_enter(State.RETURN)
		return
	if _try_attack():
		return
	_walk_toward(_target.global_position, delta)


func _walk_toward(at: Vector2, delta: float) -> void:
	var to := at - global_position
	if to.length() > 2.0:
		facing = to.normalized()
	velocity = velocity.move_toward(facing * data.move_speed, ACCEL * delta)
	move_and_slide()
	_animator.play(&"walk", facing, clampf(get_real_velocity().length() / maxf(data.move_speed, 1.0), 0.5, 1.4))


func _brake(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, ACCEL * 2.0 * delta)
	move_and_slide()


func _try_attack() -> bool:
	if _target == null:
		return false
	var dist := global_position.distance_to(_target.global_position)
	var ready: Array[EnemyAttackData] = []
	var total := 0.0
	for attack in (data.phase2_attacks if phase == 2 and not data.phase2_attacks.is_empty() else data.attacks):
		if _cooldowns.get(attack.id, 0.0) <= 0.0 and dist <= attack.trigger_range:
			ready.append(attack)
			total += attack.weight
	if ready.is_empty():
		return false
	var roll := randf() * total
	for attack in ready:
		roll -= attack.weight
		if roll <= 0.0 or attack == ready.back():
			_attack = attack
			break
	facing = (_target.global_position - global_position).normalized()
	_target_at = _target.global_position
	_enter(State.TELEGRAPH)
	return true


func _nearest_player(radius: float) -> Node2D:
	var best: Node2D = null
	var best_d := radius * radius
	for p: Node2D in get_tree().get_nodes_in_group(&"players"):
		var player := p as Player
		if player and player.stats.is_dead():
			continue
		var d := global_position.distance_squared_to(p.global_position)
		if d < best_d:
			best_d = d
			best = p
	return best


func _enter(next: State) -> void:
	var engaged_before := state in [State.CHASE, State.TELEGRAPH, State.ACTIVE, State.RECOVER, State.STAGGER]
	var engaged_after := next in [State.CHASE, State.TELEGRAPH, State.ACTIVE, State.RECOVER, State.STAGGER]
	if engaged_before != engaged_after:
		EventBus.enemy_aggro.emit(self, engaged_after)
	if state == State.ACTIVE:
		hitbox.deactivate()
	if state == State.TELEGRAPH or state == State.STAGGER:
		Flash.clear(sprite)
	if next != State.TELEGRAPH:
		marker.hide_marker()
	state = next
	state_time = 0.0
	match next:
		State.IDLE:
			_animator.play(&"idle", facing)
		State.CHASE:
			if data.is_boss and not _announced:
				_announced = true
				EventBus.boss_engaged.emit(self)
		State.TELEGRAPH:
			_show_telegraph()
			_play_attack_part(0, _attack_frames() / 2, _attack.telegraph_ms)
			Flash.pulse(sprite, data.telegraph_color, _attack.telegraph_ms / 1000.0, 3, 0.55)
			AudioManager.sfx_at(&"enemy_windup", global_position, -4.0, 0.15)
		State.ACTIVE:
			var half := _attack_frames() / 2
			_play_attack_part(half, _attack_frames() - half, _attack.active_ms + _attack.recovery_ms)
			_cooldowns[_attack.id] = _attack.cooldown_ms / 1000.0
			_strike()
		State.RECOVER:
			pass  # hold the swing's last frame
		State.STAGGER:
			_animator.play(&"hurt", facing, 0.5, true)
			Flash.pulse(sprite, Color(1.0, 0.88, 0.54), data.stagger_ms / 1000.0, 3, 0.35)
		State.DEAD:
			if not _was_rested:
				_animator.play(&"dead", facing, 1.0, true)
			hurtbox.enabled = false
			velocity = Vector2.ZERO
			EventBus.enemy_killed.emit(self, _last_attacker)
	state_changed.emit(next)


func _show_telegraph() -> void:
	match _attack.shape:
		EnemyAttackData.Shape.FRONT:
			marker.show_box(_attack.box_size, facing, _attack.reach)
		EnemyAttackData.Shape.AT_TARGET:
			marker.show_pits(to_local(_target_at), _attack.aoe_radius, _attack.pits, _attack.pit_spread, facing)
		_:
			marker.show_marker(_attack.aoe_radius)


func _strike() -> void:
	match _attack.shape:
		EnemyAttackData.Shape.FRONT:
			hitbox.shape_rect(_attack.box_size, facing, _attack.reach, BODY_HEIGHT * 0.5)
			velocity = facing * _attack.lunge_speed
		EnemyAttackData.Shape.AT_TARGET:
			# The first pit lands on the target; extras are separate hitboxes made by the marker.
			hitbox.shape_circle(_attack.aoe_radius, 0.0)
			hitbox.position = to_local(_target_at)
			for at in marker.extra_pit_positions():
				_spawn_pit_hit(at)
		_:
			hitbox.shape_circle(_attack.aoe_radius, BODY_HEIGHT * 0.5)
	hitbox.activate(_make_damage_info(_attack))


func _spawn_pit_hit(local_at: Vector2) -> void:
	var extra := Hitbox.new()
	extra.team = hitbox.team
	add_child(extra)
	extra.shape_circle(_attack.aoe_radius, 0.0)
	extra.position = local_at
	extra.activate(_make_damage_info(_attack))
	get_tree().create_timer(_attack.active_ms / 1000.0).timeout.connect(extra.queue_free)


func _attack_frames() -> int:
	var anim := StringName("attack_" + CharacterAnimator.dir_name(facing))
	return sprite.sprite_frames.get_frame_count(anim) if sprite.sprite_frames.has_animation(anim) else 4


## Plays `count` frames of the attack animation starting at `first`, over `ms`.
func _play_attack_part(first: int, count: int, ms: int) -> void:
	var anim := StringName("attack_" + CharacterAnimator.dir_name(facing))
	if not sprite.sprite_frames.has_animation(anim):
		return
	var fps := sprite.sprite_frames.get_animation_speed(anim)
	sprite.play(anim)
	sprite.frame = first
	sprite.speed_scale = (count / maxf(fps, 0.01)) / maxf(ms / 1000.0, 0.01)


func _make_damage_info(attack: EnemyAttackData) -> DamageInfo:
	var info := DamageInfo.new()
	info.source = self
	info.amount = attack.damage
	info.damage_type = attack.damage_type
	info.poise_damage = attack.poise_damage
	info.knockback = attack.knockback
	info.attack_id = attack.id
	return info


# --- taking hits ---------------------------------------------------------------

## Called by the Hurtbox on the host. Staggered enemies take riposte damage.
func receive_hit(info: DamageInfo) -> int:
	if state == State.DEAD:
		return DamageInfo.Result.IGNORED
	if state == State.IDLE or state == State.RETURN:
		_target = info.source as Node2D  # being hit always wakes it
	var riposte := state == State.STAGGER
	var at := global_position + Vector2(0.0, -BODY_HEIGHT)
	if data.shielded and not riposte and facing.dot(-info.direction) > 0.2 and info.attack_id != &"heavy":
		poise -= info.poise_damage * 0.5
		_poise_delay = data.poise_regen_delay
		Fx.text(at + Vector2(0, -14), "Blocked", BLOCK_COLOR, self)
		AudioManager.sfx_at(&"block", global_position, -2.0, 0.1)
		if poise <= 0.0:
			_stagger()
		return DamageInfo.Result.BLOCKED
	var mult := data.stagger_damage_mult if riposte else DamageCalc.CRIT_MULT
	if riposte:
		info.crit = true
	var dmg := DamageCalc.from_info(info, data.defense, data.resistances, 0.0, mult)
	hp = maxf(0.0, hp - dmg)
	_last_attacker = info.source
	health_changed.emit(hp, data.max_hp)
	EventBus.damage_dealt.emit(info.source, self, dmg, info.damage_type)
	Fx.text(at + Vector2(0, -14), str(dmg) + ("!" if info.crit else ""), CRIT_COLOR if info.crit else HIT_COLOR, self)
	Fx.spawn(data.hit_fx, at, info.direction, self)
	Flash.hit(sprite, Color.WHITE, 0.12)
	AudioManager.sfx_at(&"hit_flesh", global_position, -2.0, 0.1)
	if hp <= 0.0:
		AudioManager.sfx_at(&"enemy_die", global_position)
		_enter(State.DEAD)
		return DamageInfo.Result.HIT
	AudioManager.sfx_at(&"enemy_hurt", global_position, -6.0, 0.15)
	if phase == 1 and data.phase2_at > 0.0 and hp <= data.max_hp * data.phase2_at:
		_begin_phase_two()
	if not riposte:
		poise -= info.poise_damage
		_poise_delay = data.poise_regen_delay
		if poise <= 0.0:
			_stagger()
	return DamageInfo.Result.HIT


## Our attack was parried by `_by`: the opening the player earned.
func on_parried(_by: Node) -> void:
	if state != State.DEAD:
		_stagger()


func _stagger() -> void:
	poise = data.max_poise
	_enter(State.STAGGER)


func _begin_phase_two() -> void:
	phase = 2
	HitFeedback.shake(4.0, 0.4)
	EventBus.boss_phase_changed.emit(self, 2)
	if data.phase2_summon == null:
		return
	for i in data.phase2_summon_count:
		var minion := data.phase2_summon.instantiate() as Node2D
		var ang := TAU * i / maxf(data.phase2_summon_count, 1)
		minion.position = position + Vector2(cos(ang), sin(ang) * 0.6) * 56.0
		get_parent().add_child.call_deferred(minion)


func _on_hit_landed(_target_node: Node, _result: int, _info: DamageInfo) -> void:
	pass


func _regen_poise(delta: float) -> void:
	if _poise_delay > 0.0:
		_poise_delay -= delta
	elif poise < data.max_poise:
		poise = minf(data.max_poise, poise + data.poise_regen * delta)


func _reset_pools() -> void:
	hp = data.max_hp
	poise = data.max_poise
	phase = 1
	health_changed.emit(hp, data.max_hp)
