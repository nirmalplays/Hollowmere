extends Node
## Global hit feel (GAME_PLAN 5.3): hit-stop (a brief freeze) and screen-shake requests.
## Both are local presentation only; in co-op each machine plays its own.

signal shake_requested(strength: float, duration: float)

## Freezes are capped so stacked hits can't stall the game.
const MAX_STOP: float = 0.2

var _stop_until_ms: int = 0


func hit_stop(seconds: float) -> void:
	if seconds <= 0.0:
		return
	seconds = minf(seconds, MAX_STOP)
	_stop_until_ms = maxi(_stop_until_ms, Time.get_ticks_msec() + int(seconds * 1000.0))
	Engine.time_scale = 0.0
	# Wait out whatever freeze is left (another hit may have extended it). Timers use
	# process_always + ignore_time_scale so they run while the game is frozen, and
	# can fire a millisecond early, hence the loop instead of one exact check.
	while true:
		var remaining := (_stop_until_ms - Time.get_ticks_msec()) / 1000.0
		if remaining <= 0.0:
			break
		await get_tree().create_timer(remaining, true, false, true).timeout
	Engine.time_scale = 1.0


func shake(strength: float, duration: float = 0.15) -> void:
	if strength > 0.0:
		shake_requested.emit(strength, duration)
