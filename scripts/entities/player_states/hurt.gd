extends PlayerState
## Flinch after taking a hit: knocked back, can't act until it ends.
## msg: {"knockback": Vector2}


func enter(msg: Dictionary) -> void:
	player.velocity = msg.get("knockback", Vector2.ZERO)
	player.play_directional(&"idle")


func physics_update(delta: float) -> void:
	player.brake(delta)
	if elapsed >= player.combat.hurt_duration:
		machine.transition(&"Idle")
