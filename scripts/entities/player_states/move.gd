extends PlayerState
## Walking, or sprinting while sprint is held (drains stamina, no regen).

var _sprinting: bool = false


func physics_update(delta: float) -> void:
	if player.try_start_action():
		return
	if player.input.move == Vector2.ZERO:
		machine.transition(&"Idle")
		return
	_sprinting = player.input.sprint_held and player.stats.can_act()
	if _sprinting:
		player.stats.spend_stamina(player.combat.sprint_stamina_per_sec * delta)
	player.move_with_input(delta, player.combat.sprint_mult if _sprinting else 1.0)
	player.update_facing()
	if player.is_moving():
		# Stride follows real speed, so feet don't slide when slowed or sprinting.
		var ratio := player.get_real_velocity().length() / player.tuning.max_speed
		player.play_directional(&"walk", clampf(ratio, 0.6, 1.6))
	else:
		player.play_directional(&"idle")


func exit() -> void:
	_sprinting = false


func stamina_regen_mult() -> float:
	return 0.0 if _sprinting else 1.0
