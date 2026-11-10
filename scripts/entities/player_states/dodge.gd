extends PlayerState
## Dodge roll: a burst in the move direction (a backstep with no input), invincible
## for the first `dodge_iframes` seconds, then a short recovery lock.

var _dir: Vector2 = Vector2.DOWN


func enter(_msg: Dictionary) -> void:
	player.stats.spend_stamina(player.combat.dodge_stamina)
	var move := player.input.move
	_dir = move.normalized() if move != Vector2.ZERO else -player.facing
	player.play_once(&"dodge", _dir.x < 0.0)


func physics_update(delta: float) -> void:
	var c := player.combat
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
