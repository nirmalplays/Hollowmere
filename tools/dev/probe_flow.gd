extends SceneTree
## Dev probe for combat flow: holds attack for 2 s next to nothing and counts swings,
## checks the player can move while swinging, throws an ember, and reads the marked wall.
##   godot --headless --path . --script res://tools/dev/probe_flow.gd

var _frame: int = 0
var _area: Node
var _swings: int = 0
var _start: Vector2
var _embers: int = 0
var _lore: Array = []


func _initialize() -> void:
	_area = (load("res://scenes/world/shrine_wood.tscn") as PackedScene).instantiate()
	root.add_child.call_deferred(_area)


func _physics_process(_delta: float) -> bool:
	_frame += 1
	if _frame < 12:
		return false
	var player: Node2D = _area.get("player")
	if _frame == 12:
		root.get_node("/root/GameState").flags[&"has_cradle_lantern"] = true
		root.get_node("/root/EventBus").lore_shown.connect(func(t: String) -> void: _lore.append(t))
		player.get("states").state_changed.connect(func(_from: StringName, to: StringName) -> void:
			if to == &"Attack":
				_swings += 1)
		player.ember_thrown.connect(func() -> void: _embers += 1)
		# stand in the open hall, away from cradles
		for node in root.get_tree().get_nodes_in_group(&"enemies"):
			node.set("dormant", true)
		var wall: Node2D
		for n in _area.get("entities").get_children():
			if n.get_meta(&"marker", "") == "I":
				wall = n
		player.global_position = wall.global_position + Vector2(0, 30)
		_start = player.global_position
		Input.action_press(&"attack_light")
		Input.action_press(&"move_down")
	if _frame == 132:
		Input.action_release(&"attack_light")
		Input.action_release(&"move_down")
		print("swings in 2.0 s: ", _swings, "   moved while swinging: ", int(player.global_position.distance_to(_start)), " px")
		Input.action_press(&"spell_1")
	if _frame == 134:
		Input.action_release(&"spell_1")
	if _frame == 150:
		print("embers thrown: ", _embers)
		player.global_position = _start
	if _frame == 156:
		var ev := InputEventAction.new()
		ev.action = &"interact"
		ev.pressed = true
		Input.parse_input_event(ev)
	if _frame == 170:
		print("wall read: ", _lore.size() > 0 and "EIGHT BREATHS" in str(_lore))
		quit()
		return true
	return false
