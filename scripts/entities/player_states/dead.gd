extends PlayerState
## The Unlaid fall but don't stay dead (STORY_BIBLE 4): collapse, then rise at the
## last Hearth after `respawn_delay`. Hollow Pressure and Scars hook in at M7.


func enter(_msg: Dictionary) -> void:
	player.velocity = Vector2.ZERO
	player.hurtbox.enabled = false
	player.hitbox.deactivate()
	player.play_directional(&"dead", 1.0, true)
	EventBus.player_died.emit(player)


func exit() -> void:
	player.hurtbox.enabled = true


func physics_update(_delta: float) -> void:
	if elapsed >= player.combat.respawn_delay:
		player.respawn()


func on_hit(_info: DamageInfo) -> int:
	return DamageInfo.Result.IGNORED


func stamina_regen_mult() -> float:
	return 0.0
