extends SceneTree
## Dev: a bot plays The Waking from the character creator's output to the road out,
## the way a player would (it only presses inputs), and keeps a diary: a log line and
## a screenshot at every stage, every death, and any time it gets stuck.
##   godot --path . --script res://tools/dev/playtest.gd -- <out folder> [class] [origin]
## Read <out>/diary.txt afterwards.

const SLOT: int = 2
const TILE: float = 32.0
const TIME_LIMIT: float = 420.0
## The trail, in cells, as a player would walk it. Strings are things to do on the way.
const ROUTE: Array = [
	"lantern", Vector2(13, 33), Vector2(11, 28), Vector2(13, 22), Vector2(14, 18), Vector2(15, 13),
	"clear", Vector2(22, 11), "stone", Vector2(25, 11), Vector2(30, 10), Vector2(35, 8), "clear", Vector2(39, 11),
	Vector2(40, 16), "clear", Vector2(38, 21), Vector2(39, 27), Vector2(39, 33), Vector2(40, 39), "clear",
	Vector2(48, 37), Vector2(53, 32), Vector2(56, 27), Vector2(56, 20), Vector2(57, 14), "clear", "key",
	Vector2(57, 5), Vector2(57, 2),
]

var _out: String = "user://playtest"
var _hero := {"name": "Tester", "origin": "human", "class": "bruiser"}
var _t: float = 0.0
var _frame: int = 0
var _step: int = 0
var _shots: int = 0
var _last_pos: Vector2 = Vector2.ZERO
var _still: float = 0.0
var _deaths: int = 0
var _quest_done: int = -1
var _was_dead: bool = false
var _pressed: Dictionary = {}
var _tap_release: Dictionary = {}
var _place: String = ""
var _log: PackedStringArray = []
var _dodge_cd: float = 0.0
var _ability_cd: float = 0.0
var _swings: int = 0
var _hits_taken: int = 0
var _hp_last: float = -1.0
var _path: Array[Vector2] = []  ## waypoints (px) to the current goal
var _path_goal: Vector2 = Vector2(-1, -1)
var _grid: PackedStringArray = []
## Layout characters whose props block movement.
const SOLID: String = "#MCKGXTOuolsWNtk"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	if args.size() > 1:
		_hero["class"] = args[1]
	if args.size() > 2:
		_hero["origin"] = args[2]
	DirAccess.make_dir_recursive_absolute(_out)


func _note(text: String, shot: bool = true) -> void:
	var line := "%5.1fs  %s" % [_t, text]
	if shot and DisplayServer.get_name() != "headless":  # headless runs keep only the log
		_shots += 1
		var name := "%02d.png" % _shots
		root.get_texture().get_image().save_png(_out.path_join(name))
		line += "   [" + name + "]"
	print(line)
	_log.append(line)


func _hold(action: StringName, on: bool) -> void:
	if _pressed.get(action, false) == on:
		return
	_pressed[action] = on
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = on
	Input.parse_input_event(ev)


func _tap(action: StringName) -> void:
	_hold(action, true)
	_tap_release[action] = _frame + 3


func _finish(result: String) -> void:
	_note("RESULT: " + result)
	_note("deaths %d, hits taken %d, swings %d, quest steps done %d of %d" % [_deaths, _hits_taken, _swings, _quest_done + 1, root.get_node("/root/QuestLog").steps.size()], false)
	var f := FileAccess.open(_out.path_join("diary.txt"), FileAccess.WRITE)
	f.store_string("\n".join(_log) + "\n")
	f.close()
	root.get_node("/root/SaveManager").call(&"delete", SLOT)
	quit()


func _physics_process(delta: float) -> bool:
	_frame += 1
	for action: StringName in _tap_release.keys():
		if _frame >= _tap_release[action]:
			_tap_release.erase(action)
			_hold(action, false)
	if _frame == 5:
		root.get_node("/root/SaveManager").call(&"new_game", SLOT, _hero)
	if _frame < 50:
		return false
	var area: Node = current_scene
	if area == null or area.get("player") == null:
		if _frame > 200:
			_finish("left the area (scene is %s)" % [area.scene_file_path if area else "none"])
			return true
		return false
	var player: Node2D = area.get("player")
	_t += delta
	if _frame == 50:
		_note("woke as %s %s" % [_hero["origin"], _hero["class"]])
		_last_pos = player.global_position
	if paused:  # a tutorial card or the fire's ledger: read it, then dismiss it
		if _frame % 90 == 0:
			_note("a card is up (paused)")
			_tap(&"ui_cancel")
		return false
	# --- diary
	var stats: Node = player.get("stats")
	var hp: float = stats.hp
	if _hp_last >= 0.0 and hp < _hp_last - 0.5:
		_hits_taken += 1
	_hp_last = hp
	var dead: bool = stats.is_dead()
	if dead and not _was_dead:
		_deaths += 1
		_note("DIED at %s (cell %d,%d)" % [area.get("place"), int(player.global_position.x / TILE), int(player.global_position.y / TILE)])
	if _was_dead and not dead:  # risen at a fire: pick the trail up from the nearest point behind us
		var best := 0
		var best_d := INF
		for i in mini(_step + 1, ROUTE.size()):
			if ROUTE[i] is Vector2:
				var d: float = ((ROUTE[i] as Vector2) * TILE).distance_to(player.global_position)
				if d < best_d:
					best_d = d
					best = i
		_step = best
		_note("rose at the fire; back on the trail at step %d" % _step)
	_was_dead = dead
	if dead:
		for a: StringName in [&"move_left", &"move_right", &"move_up", &"move_down", &"attack_light"]:
			_hold(a, false)
		return false
	var steps: Array = root.get_node("/root/QuestLog").steps
	var done := -1
	for i in steps.size():
		if steps[i]["done"]:
			done = i
	if done != _quest_done:
		_quest_done = done
		_note("objective %d done; now: %s" % [done + 1, steps[mini(done + 1, steps.size() - 1)]["text"]])
	if String(area.get("place")) != _place and String(area.get("place")) != "":
		_place = area.get("place")
		_note("entered " + _place)
	if _t > TIME_LIMIT:
		_finish("ran out of time at route step %d" % _step)
		return true
	_dodge_cd -= delta
	_ability_cd -= delta
	# --- survive
	if hp < player.get("combat").max_hp * 0.45 and int(player.get("flasks")) > 0 and player.get("states").current_name() in [&"Idle", &"Move"]:
		_tap(&"heal")
	# --- fight whatever is near
	var foe: Node2D = null
	var foe_d := 170.0
	for e: Node2D in root.get_tree().get_nodes_in_group(&"enemies"):
		if e.call(&"is_dead"):
			continue
		var d := e.global_position.distance_to(player.global_position)
		if d < foe_d:
			foe_d = d
			foe = e
	if foe:
		var to := foe.global_position - player.global_position
		if foe.call(&"can_rest") and foe_d < 56.0:
			_move(Vector2.ZERO)
			_hold(&"attack_light", false)
			_tap(&"interact")
			_note("pressed Rest on a staggered %s" % foe.get("data").display_name, false)
			return false
		var state: int = foe.get("state")
		if (state == 3 or state == 4) and foe_d < 70.0 and _dodge_cd <= 0.0:  # it is winding up: get out
			_move(-to)
			_tap(&"dodge")
			_dodge_cd = 0.9
			return false
		_move(to if foe_d > 30.0 else Vector2.ZERO)
		var close: bool = foe_d < 44.0 or (_hero["class"] == "arcanist" and foe_d < 150.0)
		if close and not _pressed.get(&"attack_light", false):
			_swings += 1
		_hold(&"attack_light", close)
		if foe_d < 120.0 and _ability_cd <= 0.0 and GameState_flag(&"has_cradle_lantern"):
			_tap(&"spell_1")
			_ability_cd = 3.0
		_stuck_check(player, delta, "fighting")
		return false
	_hold(&"attack_light", false)
	# --- otherwise follow the route
	if _step >= ROUTE.size():
		_move(Vector2.ZERO)
		if _frame % 120 == 0:
			_note("at the end of the route, waiting")
		return false
	var goal: Variant = ROUTE[_step]
	if goal is String:
		_do(goal, area, player)
		return false
	var target: Vector2 = (goal as Vector2) * TILE + Vector2(16, 16)
	if player.global_position.distance_to(target) < 20.0:
		_step += 1
	else:
		_go(area, player, target)
	_stuck_check(player, delta, "walking to cell %s" % str(goal))
	return false


func GameState_flag(flag: StringName) -> bool:
	return root.get_node("/root/GameState").flags.get(flag, false)


func _do(what: String, area: Node, player: Node2D) -> void:
	match what:
		"lantern", "stone":
			var marker := "L" if what == "lantern" else "I"
			for n: Node in area.get("entities").get_children():
				if n.get_meta(&"marker", "") == marker:
					var at: Vector2 = (n as Node2D).global_position + Vector2(0, 18)
					# Close enough for its prompt (a player presses as soon as it shows).
					if (n as Node2D).global_position.distance_to(player.global_position) > 34.0:
						_go(area, player, at)
						_stuck_check(player, 1.0 / 60.0, "walking to the " + what)
					else:
						_move(Vector2.ZERO)
						_tap(&"interact")
						_note("pressed interact at the %s" % what)
						_step += 1
					return
			_note("no %s marker found" % what)
			_step += 1
		"clear":
			_step += 1  # fights happen on their own when anything is near
		"key":
			for n: Node in area.get("entities").get_children():
				if n is Pickup:
					_go(area, player, (n as Node2D).global_position)
					return
			_step += 1


## Walk toward `target` along a grid path round trees, cradles and stones.
func _go(area: Node, player: Node2D, target: Vector2) -> void:
	if _grid.is_empty():
		_grid = (area.get("layout") as AreaLayout).lines()
	if _path_goal.distance_to(target) > 8.0 or _path.is_empty():
		_path_goal = target
		_path = _find_path(_cell(player.global_position), _cell(target))
		_path.append(target)
	while _path.size() > 1 and player.global_position.distance_to(_path[0]) < 14.0:
		_path.pop_front()
	_move(_path[0] - player.global_position)


func _cell(p: Vector2) -> Vector2i:
	return Vector2i(int(p.x / TILE), int(p.y / TILE))


func _open(c: Vector2i) -> bool:
	if c.y < 0 or c.y >= _grid.size() or c.x < 0 or c.x >= _grid[c.y].length():
		return false
	return not SOLID.contains(_grid[c.y][c.x])


## Breadth-first over cells (8-way, no corner cutting). Returns pixel waypoints.
func _find_path(from: Vector2i, to: Vector2i) -> Array[Vector2]:
	var came := {from: from}
	var todo: Array[Vector2i] = [from]
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
	while not todo.is_empty():
		var c: Vector2i = todo.pop_front()
		if c == to:
			break
		for d: Vector2i in dirs:
			var n: Vector2i = c + d
			if came.has(n) or not (_open(n) or n == to):
				continue
			if d.x != 0 and d.y != 0 and not (_open(c + Vector2i(d.x, 0)) and _open(c + Vector2i(0, d.y))):
				continue
			came[n] = c
			todo.append(n)
	var out: Array[Vector2] = []
	if not came.has(to):
		return out
	var c := to
	while c != from:
		out.push_front(Vector2(c) * TILE + Vector2(16, 18))
		c = came[c]
	return out


func _move(dir: Vector2) -> void:
	_hold(&"move_right", dir.x > 6.0)
	_hold(&"move_left", dir.x < -6.0)
	_hold(&"move_down", dir.y > 6.0)
	_hold(&"move_up", dir.y < -6.0)


func _stuck_check(player: Node2D, delta: float, doing: String) -> void:
	if player.global_position.distance_to(_last_pos) > 6.0:
		_last_pos = player.global_position
		_still = 0.0
		return
	_still += delta
	if _still > 6.0:
		_still = 0.0
		_note("STUCK for 6 s while %s (cell %d,%d)" % [doing, int(player.global_position.x / TILE), int(player.global_position.y / TILE)])
		_path.clear()
		_step = mini(_step + 1, ROUTE.size())  # try the next point rather than stand forever
