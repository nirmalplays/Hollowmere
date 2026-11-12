extends SceneTree
## Dev probe: staggers a crawler, presses the interact key beside it mid-combo, and
## checks it was laid to rest.
##   godot --headless --path . --script res://tools/dev/probe_rest.gd

var _frame: int = 0
var _crawler: Node
var _rested: bool = false


func _initialize() -> void:
	change_scene_to_file.call_deferred("res://scenes/world/shrine_wood.tscn")


func _physics_process(_delta: float) -> bool:
	_frame += 1
	if _frame == 20:
		var area: Node = current_scene
		var player: Node2D = area.get("player")
		root.get_node("/root/GameState").flags[&"has_cradle_lantern"] = true
		_crawler = area.call(&"enemies_with_char", "c")[0]
		_crawler.connect(&"rested", func() -> void: _rested = true)
		player.global_position = _crawler.global_position + Vector2(-40, 0)
		_crawler.call(&"_stagger")
		Input.action_press(&"attack_light")  # swinging at the time, as a player would be
	if _frame == 40:
		print("can rest: ", _crawler.call(&"can_rest"), "  target found: ", current_scene.get("player").call(&"rest_target") != null)
		var ev := InputEventAction.new()
		ev.action = &"interact"
		ev.pressed = true
		Input.parse_input_event(ev)
	if _frame == 60:
		print("rested: ", _rested)
		quit()
		return true
	return false
