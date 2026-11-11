extends IntegrationTest
## M1: walking moves the player and plays the matching 8-direction animation;
## walking into a wall stops the feet at the wall's edge; friction brings the body to rest.

const ROOM: String = "res://tests/arena.tscn"
const NORTH_WALL_EDGE: float = 96.0  ## rows 0-2 of the arena are wall (32 px tiles)


func _run() -> void:
	spawn_scene(ROOM)
	await wait_frames(2)
	var player := get_tree().get_first_node_in_group(&"players") as Player
	if player == null:
		fail("no player spawned in the arena")
		return
	var start := player.global_position

	Input.action_press(&"move_right")
	await wait_frames(28)
	check(player.global_position.x > start.x + 10.0, "player did not move right")
	check(player.sprite.animation == &"walk_e", "walk_e not playing (got %s)" % player.sprite.animation)
	Input.action_release(&"move_right")

	Input.action_press(&"move_up")
	await wait_frames(150)
	var y := player.global_position.y
	check(y >= NORTH_WALL_EDGE and y <= NORTH_WALL_EDGE + 10.0, "north wall did not stop the player (y=%.1f)" % y)
	Input.action_release(&"move_up")

	await wait_frames(30)
	check(player.get_real_velocity().length() < 1.0, "friction did not stop the player")
	check(String(player.sprite.animation).begins_with("idle_"), "should be idle (got %s)" % player.sprite.animation)
