class_name Enemy
extends CharacterBody2D
## Data-driven enemy (GAME_PLAN 5.6). M2: stands its ground, telegraphs attacks at
## targets in range, has poise (breaks into stagger) and can be parried.
## M4 adds movement (patrol/chase/reposition), more attack shapes and loot.
## All decisions run on the host only.

signal health_changed(hp: float, max_hp: float)
signal state_changed(state: int)

enum State { IDLE, TELEGRAPH, ACTIVE, RECOVER, STAGGER, DEAD }

const BODY_HEIGHT: float = 10.0
const CRIT_COLOR := Color(1.0, 0.88, 0.54)
const HIT_COLOR := Color(0.96, 0.95, 0.92)

@export var data: EnemyData

var hp: float = 0.0
var poise: float = 0.0
var state: State = State.IDLE
var state_time: float = 0.0  ## seconds in the current state
var facing: Vector2 = Vector2.DOWN

var _attack: EnemyAttackData
var _cooldowns: Dictionary = {}  # attack id -> seconds left
var _poise_delay: float = 0.0
var _last_attacker: Node

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var marker: TelegraphMarker = $TelegraphMarker
@onready var _animator := CharacterAnimator.new($Sprite)

## The swing animation's 4 frames: the first half winds up during the telegraph,
## the second half lands during active + recovery.
const WINDUP_FRAMES: int = 2


func _ready() -> void:
	add_to_group(&"enemies")
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
	if not NetManager.is_host():
		return
	var ms := state_time * 1000.0
	match state:
		State.IDLE:
			_choose_attack()
		State.TELEGRAPH:
			marker.progress = ms / _attack.telegraph_ms
			if ms >= _attack.telegraph_ms:
				_enter(State.ACTIVE)
		State.ACTIVE:
			if ms >= _attack.active_ms:
				_enter(State.RECOVER)
		State.RECOVER:
			if ms >= _attack.recovery_ms:
				_enter(State.IDLE)
		State.STAGGER:
			if ms >= data.stagger_ms:
				_enter(State.IDLE)
		State.DEAD:
			if data.revive_ms >= 0 and ms >= data.revive_ms:
				_reset_pools()
				hurtbox.enabled = true
				_enter(State.IDLE)


func is_staggered() -> bool:
	return state == State.STAGGER


# --- decisions ---------------------------------------------------------------

func _choose_attack() -> void:
	var target := _nearest_player()
	if target == null:
		return
	var dist := global_position.distance_to(target.global_position)
	for attack in data.attacks:
		if _cooldowns.get(attack.id, 0.0) <= 0.0 and dist <= attack.trigger_range:
			_attack = attack
			facing = (target.global_position - global_position).normalized()
			_enter(State.TELEGRAPH)
			return


func _nearest_player() -> Node2D:
	var best: Node2D = null
	var best_d := INF
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
		State.TELEGRAPH:
			_play_attack_part(0, WINDUP_FRAMES, _attack.telegraph_ms)
			marker.show_marker(_attack.aoe_radius)
			Flash.pulse(sprite, data.telegraph_color, _attack.telegraph_ms / 1000.0, 3, 0.55)
		State.ACTIVE:
			_play_attack_part(WINDUP_FRAMES, WINDUP_FRAMES, _attack.active_ms + _attack.recovery_ms)
			_cooldowns[_attack.id] = _attack.cooldown_ms / 1000.0
			hitbox.shape_circle(_attack.aoe_radius, BODY_HEIGHT * 0.5)
			hitbox.activate(_make_damage_info(_attack))
		State.RECOVER:
			pass  # hold the swing's last frame
		State.STAGGER:
			_animator.play(&"hurt", facing, 0.5, true)
			Flash.pulse(sprite, Color(1.0, 0.88, 0.54), data.stagger_ms / 1000.0, 3, 0.35)
		State.DEAD:
			_animator.play(&"dead", facing, 1.0, true)
			hurtbox.enabled = false
			EventBus.enemy_killed.emit(self, _last_attacker)
	state_changed.emit(next)


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
	var riposte := state == State.STAGGER
	var mult := data.stagger_damage_mult if riposte else DamageCalc.CRIT_MULT
	if riposte:
		info.crit = true
	var dmg := DamageCalc.from_info(info, data.defense, data.resistances, 0.0, mult)
	hp = maxf(0.0, hp - dmg)
	_last_attacker = info.source
	health_changed.emit(hp, data.max_hp)
	EventBus.damage_dealt.emit(info.source, self, dmg, info.damage_type)
	var at := global_position + Vector2(0.0, -BODY_HEIGHT)
	Fx.text(at + Vector2(0, -14), str(dmg) + ("!" if info.crit else ""), CRIT_COLOR if info.crit else HIT_COLOR, self)
	Fx.spawn(data.hit_fx, at, info.direction, self)
	Flash.hit(sprite, Color.WHITE, 0.12)
	if hp <= 0.0:
		_enter(State.DEAD)
		return DamageInfo.Result.HIT
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


func _on_hit_landed(_target: Node, _result: int, _info: DamageInfo) -> void:
	pass  # M4: enemy-side reactions (e.g. combo follow-ups)


func _regen_poise(delta: float) -> void:
	if _poise_delay > 0.0:
		_poise_delay -= delta
	elif poise < data.max_poise:
		poise = minf(data.max_poise, poise + data.poise_regen * delta)


func _reset_pools() -> void:
	hp = data.max_hp
	poise = data.max_poise
	health_changed.emit(hp, data.max_hp)
