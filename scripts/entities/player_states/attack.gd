extends PlayerState
## A sword swing that flows: wind-up -> active (hitbox on) -> recovery, but you keep
## your feet (slowed by the attack's `move_mult`), each swing re-aims at the cursor,
## a dash cancels it at any moment, and pressing or holding attack during recovery
## chains straight into the next step of the weapon's combo.
## msg: {"attack": AttackData, "step": int}  (step = index in the light combo, -1 for heavy)

enum Phase { WINDUP, ACTIVE, RECOVERY }

var attack: AttackData
var step: int = -1

var _phase: Phase = Phase.WINDUP
var _dir: Vector2 = Vector2.DOWN


func enter(msg: Dictionary) -> void:
	attack = msg["attack"]
	step = msg.get("step", -1)
	player.stats.spend_stamina(attack.stamina_cost)
	_dir = player.aim_direction()
	player.face(_dir)
	_phase = Phase.WINDUP
	player.juice.punch(Vector2(0.92, 1.08))  # a breath in before the cut
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
	# A dash gets you out of any swing, any time.
	if player.stats.can_act() and player.input.consume(&"dodge"):
		machine.transition(&"Dodge")
		return
	if _phase == Phase.WINDUP and t >= active_at:
		_begin_active()
	if _phase == Phase.ACTIVE and t >= recover_at:
		_phase = Phase.RECOVERY
		player.hitbox.deactivate()
	if _phase == Phase.RECOVERY:
		if t >= recover_at + attack.chain_ms and player.stats.can_act() and _chain():
			return
		if t >= end_at:
			if not player.try_start_action():
				machine.transition(&"Idle")
			return
	player.move_with_input(delta, attack.move_mult)


## The next swing, if one is asked for: light continues the combo, heavy breaks into a heavy.
func _chain() -> bool:
	if player.input.consume(&"attack_heavy"):
		machine.transition(&"Attack", {"attack": player.weapon.heavy})
		return true
	if player.input.consume(&"attack_light"):
		var next := player.weapon.combo_step(step + 1)
		machine.transition(&"Attack", {"attack": player.weapon.combo_attack(next), "step": next})
		return true
	return false


func _begin_active() -> void:
	_phase = Phase.ACTIVE
	player.velocity += _dir * attack.lunge_speed
	if attack.projectile:
		player.throw_bolt(_dir, player.make_damage_info(attack))
	else:
		player.hitbox.shape_rect(attack.hitbox_size, _dir, attack.reach, Player.CHEST_HEIGHT)
		player.hitbox.activate(player.make_damage_info(attack))
	AudioManager.sfx(attack.sound, -2.0, 0.1)
	var big := attack.damage_mult > 1.3
	player.juice.punch(Vector2(1.22, 0.82) if big else Vector2(1.13, 0.9))
	if not attack.projectile:
		# Alternate the sweep each step so a combo reads as left, right, then the big one.
		SlashArc.spawn(player, player.chest_position() + _dir * 4.0, _dir, {"reach": attack.reach + attack.hitbox_size.x * 0.45,
			"clockwise": step % 2 == 0, "thick": 13.0 if big else 8.0, "sweep": 2.9 if big else 2.2,
			"life": 0.2 if big else 0.15, "color": Color(1.0, 0.82, 0.5) if big else Color(0.9, 0.95, 1.0)})
	if attack.lunge_speed > 100.0:
		player.juice.ghosts(0.12, Color(1.0, 0.85, 0.6))
		player.juice.dust(_dir, 4)
