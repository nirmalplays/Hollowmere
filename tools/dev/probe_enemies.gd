extends SceneTree
## Dev probe: stands the player next to each kind of Hollowed in an area and reports
## whether it attacks (player HP must fall). Run headless:
##   godot --headless --path . --script res://tools/dev/probe_enemies.gd -- <scene>

var _frame: int = 0
var _area: Node
var _queue: Array = []
var _current: Node2D
var _hp_before: float = 0.0
var _started: int = 0
var _failed: bool = false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var path: String = args[0] if args.size() > 0 else "res://scenes/world/underroot_caves.tscn"
	_area = (load(path) as PackedScene).instantiate()
	root.add_child.call_deferred(_area)


func _physics_process(_delta: float) -> bool:
	_frame += 1
	if _frame == 10:
		var seen := {}
		for e in root.get_tree().get_nodes_in_group(&"enemies"):
			var ch: String = e.get_meta(&"marker", "?")
			if not seen.has(ch):
				seen[ch] = true
				_queue.append(e)
	if _frame < 12:
		return false
	var player: Node2D = _area.get("player")
	if _current == null:
		if _queue.is_empty():
			print("PROBE ", "FAILED" if _failed else "OK")
			quit(1 if _failed else 0)
			return true
		_current = _queue.pop_front()
		player.call(&"respawn")
		player.global_position = _current.global_position + Vector2(60, 0)
		_hp_before = player.get("stats").hp
		_started = _frame
	elif _frame - _started > 420:
		var hp: float = player.get("stats").hp
		var ok := hp < _hp_before
		_failed = _failed or not ok
		print("%s  %s: player hp %d -> %d, enemy state %d dormant %s" % ["ok  " if ok else "FAIL", _current.get("data").display_name, _hp_before, hp, _current.get("state"), _current.get("dormant")])
		_current = null
	return false
