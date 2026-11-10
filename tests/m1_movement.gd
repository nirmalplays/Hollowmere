extends IntegrationTest
## M1: walking right moves, animates and faces right; walking up into the north
## wall stops the body exactly at the wall's edge; friction brings it to rest.

const ROOM: String = "res://scenes/world/test_room.tscn"
const NORTH_WALL_EDGE: float = 32.0  ## rows 0-1 are wall
const FEET_RADIUS: float = 4.0


func _run() -> void:
	var room := spawn_scene(ROOM)
	await wait_frames(2)
	var player := get_tree().get_first_node_in_group(&"players") as Player
	var start := player.global_position

	Input.action_press(&"move_right")
	await wait_frames(28)
	check(player.global_position.x > start.x + 10.0, "player did not move right")
	check(player.sprite.animation == &"walk_side", "walk_side not playing (got %s)" % player.sprite.animation)
	check(not player.sprite.flip_h, "facing right should not flip")
	Input.action_release(&"move_right")

	Input.action_press(&"move_up")
	await wait_frames(200)
	var y := player.global_position.y
	check(absf(y - (NORTH_WALL_EDGE + FEET_RADIUS)) <= 1.0, "north wall did not stop the player (y=%.1f)" % y)
	check(player.sprite.animation == &"idle_up", "should idle facing up against the wall (got %s)" % player.sprite.animation)
	Input.action_release(&"move_up")

	await wait_frames(30)
	check(player.get_real_velocity().length() < 1.0, "friction did not stop the player")
	room.queue_free()
