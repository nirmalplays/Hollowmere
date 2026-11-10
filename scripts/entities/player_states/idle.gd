extends PlayerState
## Standing still. Any action or movement leaves this state.


func enter(_msg: Dictionary) -> void:
	player.play_directional(&"idle")


func physics_update(delta: float) -> void:
	if player.try_start_action():
		return
	if player.input.move != Vector2.ZERO:
		machine.transition(&"Move")
		return
	player.brake(delta)
	player.update_facing()
	player.play_directional(&"idle")
