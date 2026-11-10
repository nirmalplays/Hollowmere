extends IntegrationTest
## M1 (isometric): walking moves the player and plays the matching 8-direction
## animation; walking into the raised plateau never puts the feet on a cliff cell;
## friction brings the body to rest.

const ROOM: String = "res://scenes/world/greywood_glade.tscn"


func _run() -> void:
	var room := spawn_scene(ROOM)
	await wait_frames(2)
	var player := get_tree().get_first_node_in_group(&"players") as Player
	if player == null:
		fail("no player spawned in the glade")
		return
	var start := player.global_position

	Input.action_press(&"move_right")
	await wait_frames(28)
	check(player.global_position.x > start.x + 10.0, "player did not move right")
	check(player.sprite.animation == &"walk_e", "walk_e not playing (got %s)" % player.sprite.animation)
	Input.action_release(&"move_right")

	# Stand just below the plateau's lowest cliff cell and push up into it.
	var raised: TileMapLayer = room.raised_layer()
	var cliffs := raised.get_used_cells()
	check(not cliffs.is_empty(), "glade has no raised cells")
	var lowest := cliffs[0]
	for c in cliffs:
		if raised.map_to_local(c).y > raised.map_to_local(lowest).y:
			lowest = c
	player.global_position = raised.to_global(raised.map_to_local(lowest)) + Vector2(0, 26)
	player.velocity = Vector2.ZERO
	Input.action_press(&"move_up")
	await wait_frames(120)
	var feet_cell := raised.local_to_map(raised.to_local(player.global_position))
	check(not (feet_cell in cliffs), "player walked onto a cliff cell %s" % feet_cell)
	Input.action_release(&"move_up")

	await wait_frames(30)
	check(player.get_real_velocity().length() < 1.0, "friction did not stop the player")
	check(String(player.sprite.animation).begins_with("idle_"), "should be idle (got %s)" % player.sprite.animation)
