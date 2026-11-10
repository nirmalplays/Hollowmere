extends SceneTree
## Headless M1 check: godot --headless --path . --script res://tests/m1_movement.gd
## Loads the test room, walks right (moves, animates, faces right), then walks up
## into the north wall and checks the wall stops the body at its edge.

const ROOM: String = "res://scenes/world/test_room.tscn"
const RUN_FRAMES: int = 240

var _room: Node
var _player: Player
var _start: Vector2
var _frame: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_room = (load(ROOM) as PackedScene).instantiate()
	root.add_child(_room)


func _physics_process(_delta: float) -> bool:
	_frame += 1
	if _frame == 2:
		_player = _room.get_node("Entities").get_child(0) as Player
		_start = _player.global_position
		Input.action_press(&"move_right")
	elif _frame == 30:
		_check(_player.global_position.x > _start.x + 10.0, "player did not move right")
		_check(_player.get_node("Sprite").animation == &"walk_side", "walk_side not playing")
		_check(not _player.get_node("Sprite").flip_h, "facing right should not flip")
		Input.action_release(&"move_right")
		Input.action_press(&"move_up")
	elif _frame == RUN_FRAMES:
		# North wall's bottom edge is y=32 (rows 0-1 are wall); feet circle radius is 4.
		# Holding up for ~3.5s would travel ~250px without the wall.
		var y := _player.global_position.y
		_check(y >= 35.0 and y <= 37.0, "north wall did not stop the player (y=%.1f)" % y)
		_check(_player.get_node("Sprite").animation == &"idle_up", "should idle facing up against the wall (got %s, v=%s)" % [_player.get_node("Sprite").animation, _player.velocity])
		Input.action_release(&"move_up")
	elif _frame == RUN_FRAMES + 30:
		_check(_player.get_real_velocity().length() < 1.0, "friction did not stop the player")
		_check(_player.get_node("Sprite").animation == &"idle_up", "idle_up not playing")
		for f in _failures:
			printerr("FAIL: ", f)
		print("M1 movement: %s" % ("FAILED (%d)" % _failures.size() if _failures else "OK"))
		quit(1 if _failures else 0)
	return false


func _check(ok: bool, message: String) -> void:
	if not ok:
		_failures.append(message)
