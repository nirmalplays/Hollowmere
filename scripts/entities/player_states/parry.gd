extends PlayerState
## Just parried. Holds the guard briefly; after `riposte_open` an attack can start
## right away, and hits on the staggered enemy count as a riposte (crit).


func enter(_msg: Dictionary) -> void:
	player.play_directional(&"block")


func physics_update(delta: float) -> void:
	player.brake(delta)
	if elapsed >= player.combat.riposte_open and player.try_start_attack_or_dodge():
		return
	if elapsed >= player.combat.parry_recover:
		machine.transition(&"Block" if player.input.block_held else &"Idle")


func on_hit(_info: DamageInfo) -> int:
	return DamageInfo.Result.PARRIED  # still guarding: a second hit in the window is parried too
