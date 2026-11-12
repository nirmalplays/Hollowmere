class_name ShakeCamera
extends Camera2D
## Camera that answers HitFeedback.shake_requested with a whole-pixel jitter that decays.
## Uses wall-clock time so the shake keeps playing during hit-stop (time_scale 0).

var _strength: float = 0.0
var _start_ms: int = 0
var _end_ms: int = 0
var _rng := RandomNumberGenerator.new()
var _look: Vector2 = Vector2.ZERO

const LOOK_AHEAD: float = 0.14  ## how far toward the cursor the view leans
const LOOK_MAX: float = 46.0


func _ready() -> void:
	HitFeedback.shake_requested.connect(_on_shake)


func _on_shake(strength: float, duration: float) -> void:
	if not enabled:
		return
	var now := Time.get_ticks_msec()
	_strength = maxf(_current_amplitude(now), strength)
	_start_ms = now
	_end_ms = now + int(duration * 1000.0)


func _process(delta: float) -> void:
	if enabled:
		var want: Vector2 = (get_global_mouse_position() - (get_parent() as Node2D).global_position) * LOOK_AHEAD
		_look = _look.lerp(want.limit_length(LOOK_MAX), 1.0 - exp(-5.0 * delta))
		position = _look.round()
	var amp := _current_amplitude(Time.get_ticks_msec())
	if amp <= 0.0:
		offset = Vector2.ZERO
		return
	offset = Vector2(roundf(_rng.randf_range(-amp, amp)), roundf(_rng.randf_range(-amp, amp)))


func _current_amplitude(now: int) -> float:
	if now >= _end_ms:
		return 0.0
	return _strength * float(_end_ms - now) / float(maxi(_end_ms - _start_ms, 1))
