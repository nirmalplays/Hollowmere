extends PlayerState
## Holding block. A hit inside `parry_window` of raising the guard is a parry;
## later hits from the front are blocked (reduced damage, costs stamina).
## Hits from behind get through.


func enter(_msg: Dictionary) -> void:
	player.play_directional(&"block")


func physics_update(delta: float) -> void:
	if not player.input.block_held:
		machine.transition(&"Idle")
		return
	if player.try_start_attack_or_dodge():
		return
	player.move_with_input(delta, player.combat.block_move_mult)
	player.update_facing(true)
	player.play_directional(&"block")


func on_hit(info: DamageInfo) -> int:
	if elapsed <= player.combat.parry_window:
		return DamageInfo.Result.PARRIED
	if player.facing.dot(-info.direction) > 0.0:
		return DamageInfo.Result.BLOCKED
	return -1


func stamina_regen_mult() -> float:
	return player.combat.block_regen_mult
