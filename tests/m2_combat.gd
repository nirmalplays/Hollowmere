extends IntegrationTest
## M2 "done when": every action costs stamina and is committed; dodge has i-frames;
## a timed block parries the dummy's sweep and staggers it; a riposte on the
## staggered dummy crits; an unguarded sweep hurts the player.

const ROOM: String = "res://scenes/world/greywood_glade.tscn"
const SAFE_OFFSET := Vector2(-90, 0)  ## out of the dummy's trigger range
const MELEE_OFFSET := Vector2(-20, 0)  ## inside its sweep, facing it
const BLOCK_LEAD_MS: float = 70.0  ## raise the guard this long before the sweep lands

var player: Player
var dummy: Enemy
var _player_states: Array[StringName] = []


func _run() -> void:
	spawn_scene(ROOM)
	await wait_frames(2)
	player = get_tree().get_first_node_in_group(&"players") as Player
	dummy = get_tree().get_first_node_in_group(&"enemies") as Enemy
	if player == null or dummy == null:
		fail("room needs a player and a training dummy")
		return
	player.states.state_changed.connect(func(_from: StringName, to: StringName) -> void: _player_states.append(to))

	await _test_dodge_iframes()
	await _test_light_attack_costs_stamina_and_commits()
	await _test_parry_staggers_dummy()
	await _test_riposte_crits()
	await _test_unguarded_hit_hurts()


func _place(offset: Vector2) -> void:
	player.global_position = dummy.global_position + offset
	player.velocity = Vector2.ZERO
	player.face(Vector2.RIGHT)
	player.states.transition(&"Idle")


func _sweep_info() -> DamageInfo:
	var info := DamageInfo.new()
	info.source = dummy
	info.amount = 14.0
	info.direction = Vector2.LEFT
	return info


func _test_dodge_iframes() -> void:
	_place(SAFE_OFFSET)
	await wait_frames(2)
	var stamina := player.stats.stamina
	await tap(&"dodge")
	check(player.states.current_name() == &"Dodge", "dodge did not start")
	check(player.stats.stamina < stamina, "dodge did not cost stamina")
	var hp := player.stats.hp
	check(player.receive_hit(_sweep_info()) == DamageInfo.Result.IGNORED, "hit during i-frames was not ignored")
	check(player.stats.hp == hp, "took damage during i-frames")
	await wait_until(func() -> bool: return player.states.current_name() == &"Idle", 120)


func _test_light_attack_costs_stamina_and_commits() -> void:
	_place(SAFE_OFFSET)
	await wait_until(func() -> bool: return player.stats.stamina >= player.combat.max_stamina, 240)
	var stamina := player.stats.stamina
	await tap(&"attack_light")
	check(player.states.current_name() == &"Attack", "light attack did not start")
	check(player.stats.stamina < stamina, "light attack did not cost stamina")
	# Commitment: movement input mid-swing must not move the player out of the attack.
	Input.action_press(&"move_up")
	await wait_frames(6)
	check(player.states.current_name() == &"Attack", "movement interrupted the attack")
	Input.action_release(&"move_up")
	await wait_until(func() -> bool: return player.states.current_name() != &"Attack", 120)


func _test_parry_staggers_dummy() -> void:
	await wait_until(func() -> bool: return dummy.state == Enemy.State.IDLE, 300)
	_place(MELEE_OFFSET)
	var telegraphed := await wait_until(func() -> bool: return dummy.state == Enemy.State.TELEGRAPH, 120)
	check(telegraphed, "dummy never telegraphed at a player in range")
	var hp := player.stats.hp
	var lead := func() -> bool:
		return dummy.state == Enemy.State.TELEGRAPH and dummy.state_time * 1000.0 >= dummy.data.attacks[0].telegraph_ms - BLOCK_LEAD_MS
	await wait_until(lead, 120)
	Input.action_press(&"block")
	var staggered := await wait_until(func() -> bool: return dummy.state == Enemy.State.STAGGER, 60)
	check(staggered, "parry did not stagger the dummy (dummy state %d)" % dummy.state)
	check(&"Parry" in _player_states, "player never entered Parry")
	check(player.stats.hp == hp, "parried hit still did damage")
	Input.action_release(&"block")


func _test_riposte_crits() -> void:
	if dummy.state != Enemy.State.STAGGER:
		fail("riposte skipped: dummy not staggered")
		return
	await wait_until(func() -> bool: return player.states.current_name() in [&"Idle", &"Block"], 60)
	var hp := dummy.hp
	await tap(&"attack_light")
	await wait_until(func() -> bool: return dummy.hp < hp, 60)
	var expected := DamageCalc.compute(player.attack_power(), DamageCalc.PHYSICAL, dummy.data.defense, {}, 0.0, true, dummy.data.stagger_damage_mult)
	check(int(hp - dummy.hp) == expected, "riposte did %d, expected crit %d" % [hp - dummy.hp, expected])


func _test_unguarded_hit_hurts() -> void:
	await wait_until(func() -> bool: return dummy.state == Enemy.State.IDLE, 300)
	_place(MELEE_OFFSET)
	_player_states.clear()
	var hp := player.stats.hp
	var hit := await wait_until(func() -> bool: return player.stats.hp < hp, 180)
	check(hit, "unguarded sweep did not damage the player")
	check(&"Hurt" in _player_states, "player did not flinch (Hurt)")
