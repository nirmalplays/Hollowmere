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
	player.play_directional(&"walk" if player.is_moving() else &"idle")


func exit() -> void:
	_sprinting = false


func stamina_regen_mult() -> float:
	return 0.0 if _sprinting else 1.0
