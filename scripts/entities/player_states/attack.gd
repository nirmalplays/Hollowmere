extends PlayerState
## A committed light or heavy attack: wind-up -> active (hitbox on) -> recovery.
## Nothing interrupts it except taking a hit, or a dodge inside the cancel window.
## msg: {"attack": AttackData}

enum Phase { WINDUP, ACTIVE, RECOVERY }

var attack: AttackData

var _phase: Phase = Phase.WINDUP
var _dir: Vector2 = Vector2.DOWN


func enter(msg: Dictionary) -> void:
	attack = msg["attack"]
	player.stats.spend_stamina(attack.stamina_cost)
	_dir = player.aim_direction()
	player.face(_dir)
	_phase = Phase.WINDUP
	# One swing animation stretched over wind-up + active + recovery, so the blade
	# visibly lands when the hitbox turns on.
	player.play_timed(&"attack", (attack.windup_ms + attack.active_ms + attack.recovery_ms) / 1000.0)


func exit() -> void:
	player.hitbox.deactivate()


func physics_update(delta: float) -> void:
	var t := elapsed * 1000.0
	var active_at := float(attack.windup_ms)
	var recover_at := active_at + attack.active_ms
	var end_at := recover_at + attack.recovery_ms
	if _phase == Phase.WINDUP and t >= active_at:
		_begin_active()
	if _phase == Phase.ACTIVE and t >= recover_at:
		_phase = Phase.RECOVERY
		player.hitbox.deactivate()
	if _phase == Phase.RECOVERY:
		var can_cancel := attack.dodge_cancel_ms >= 0 and t >= recover_at + attack.dodge_cancel_ms
		if can_cancel and player.stats.can_act() and player.input.consume(&"dodge"):
			machine.transition(&"Dodge")
			return
		if t >= end_at:
			if not player.try_start_action():
				machine.transition(&"Idle")
			return
	player.brake(delta)


func _begin_active() -> void:
	_phase = Phase.ACTIVE
	player.velocity = _dir * attack.lunge_speed
	player.hitbox.shape_rect(attack.hitbox_size, _dir, attack.reach, Player.CHEST_HEIGHT)
	player.hitbox.activate(player.make_damage_info(attack))
	Fx.spawn(attack.fx, player.chest_position(), _dir, player)
