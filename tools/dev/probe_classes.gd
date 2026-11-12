extends SceneTree
## Dev probe: starts a journey as each class in turn, swings and uses the ability next
## to a crawler, and reports the damage dealt. Uses slot III and deletes it.
##   godot --headless --path . --script res://tools/dev/probe_classes.gd

const SLOT: int = 2
const HEROES: Array = [["human", "bruiser"], ["bullhorn", "arcanist"], ["sylvan", "prowler"]]

var _frame: int = 0
var _index: int = -1
var _start: int = 0
var _crawler: Node
var _hp0: float = 0.0


func _physics_process(_delta: float) -> bool:
	_frame += 1
	var save: Node = root.get_node("/root/SaveManager")
	if _frame == 5 or (_index >= 0 and _frame - _start == 150):
		if _index >= 0:
			var player: Node2D = current_scene.get("player")
			print("%-18s hp %d  speed %d  dealt %d to the crawler  (%s)" % [HEROES[_index][0] + " " + HEROES[_index][1], player.get("combat").max_hp,
				player.get("tuning").max_speed, _hp0 - (_crawler.get("hp") if is_instance_valid(_crawler) else 0.0), player.get("ability_name")])
			Input.action_release(&"attack_light")
		_index += 1
		if _index >= HEROES.size():
			save.call(&"delete", SLOT)
			quit()
			return true
		save.call(&"new_game", SLOT, {"name": "Probe", "origin": HEROES[_index][0], "class": HEROES[_index][1]})
		_start = _frame
	if _index >= 0 and _frame - _start == 30:
		var area: Node = current_scene
		var player: Node2D = area.get("player")
		root.get_node("/root/GameState").flags[&"has_cradle_lantern"] = true
		_crawler = area.call(&"enemies_with_char", "c")[0]
		_crawler.set("dormant", true)
		_hp0 = _crawler.get("hp")
		player.global_position = _crawler.global_position + Vector2(-30, 0)
		player.call(&"face", Vector2.RIGHT)
		Input.action_press(&"attack_light")
	if _index >= 0 and _frame - _start == 60:
		Input.action_press(&"spell_1")
	if _index >= 0 and _frame - _start == 63:
		Input.action_release(&"spell_1")
	return false
