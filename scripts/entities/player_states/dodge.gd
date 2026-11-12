extends PlayerState
## Dodge roll: a burst in the move direction (a backstep with no input), invincible
## for the first `dodge_iframes` seconds, then a short recovery lock.
## The body turns ghostly during i-frames so the safe window is readable.

const IFRAME_ALPHA: float = 0.55
const ANIM_SPEED: float = 1.8  ## the run cycle, sped up into a dash

var _dir: Vector2 = Vector2.DOWN


func enter(_msg: Dictionary) -> void:
	player.stats.spend_stamina(player.combat.dodge_stamina)
	var move := player.input.move
	_dir = move.normalized() if move != Vector2.ZERO else -player.facing
	if move != Vector2.ZERO:
		player.face(_dir)
	player.play_directional(&"run", ANIM_SPEED, true)
	player.sprite.modulate.a = IFRAME_ALPHA
	AudioManager.sfx(&"dodge", -4.0, 0.15)
	player.juice.punch(Vector2(1.3, 0.72))
	player.juice.ghosts(player.combat.dodge_duration)
	player.juice.dust(_dir, 8)


func exit() -> void:
	player.sprite.modulate.a = 1.0


func physics_update(delta: float) -> void:
	var c := player.combat
	if elapsed >= c.dodge_iframes:
		player.sprite.modulate.a = 1.0
	if elapsed < c.dodge_duration:
		var k := elapsed / c.dodge_duration
		player.velocity = _dir * c.dodge_speed * lerpf(1.0, c.dodge_end_speed_ratio, k)
		player.move_and_slide()
	elif elapsed < c.dodge_duration + c.dodge_recovery:
		player.brake(delta)
	elif not player.try_start_action():
		machine.transition(&"Idle")


func on_hit(_info: DamageInfo) -> int:
	if elapsed < player.combat.dodge_iframes:
		return DamageInfo.Result.IGNORED
	return -1


func stamina_regen_mult() -> float:
	return 0.0
