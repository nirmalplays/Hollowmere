extends PlayerState
## Guard broken or parried: helpless for a moment.
## msg: {"duration": float}

var _duration: float = 0.5


func enter(msg: Dictionary) -> void:
	_duration = msg.get("duration", player.combat.guard_break_duration)
	player.play_directional(&"idle")
	Flash.pulse(player.sprite, Color(1.0, 0.85, 0.4), _duration, 2, 0.5)


func exit() -> void:
	Flash.clear(player.sprite)


func physics_update(delta: float) -> void:
	player.brake(delta)
	if elapsed >= _duration:
		machine.transition(&"Idle")
