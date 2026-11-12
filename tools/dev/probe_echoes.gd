extends SceneTree
## Dev probe: kills a crawler, waits for its Echoes to arrive, kindles Vitality at the
## fire's ledger, and checks health rose. Uses slot III and deletes it.
##   godot --headless --path . --script res://tools/dev/probe_echoes.gd

var _frame: int = 0
var _hp0: float = 0.0


func _physics_process(_delta: float) -> bool:
	_frame += 1
	var save: Node = root.get_node("/root/SaveManager")
	if _frame == 5:
		save.call(&"new_game", 2, {"name": "Probe", "origin": "human", "class": "bruiser"})
	if _frame == 40:
		var area: Node = current_scene
		var player: Node2D = area.get("player")
		var crawler: Node2D = area.call(&"enemies_with_char", "c")[0]
		player.global_position = crawler.global_position + Vector2(-50, 0)
		crawler.set("hp", 0.0)
		crawler.call(&"_enter", 7)
		_hp0 = player.get("combat").max_hp
	if _frame == 160:
		var player: Node2D = current_scene.get("player")
		print("echoes after one crawler: ", player.get("echoes"))
		player.call(&"gain_echoes", 40)
		print("cost ", player.call(&"kindle_cost"), "  kindled: ", player.call(&"raise_attribute", "vitality"),
			"  health ", _hp0, " -> ", player.get("combat").max_hp, "  echoes left ", player.get("echoes"))
		var menu: Node = load("res://scripts/ui/kindle_menu.gd").new()
		menu.set("player", player)
		current_scene.add_child(menu)
	if _frame == 170:
		print("ledger opened, paused: ", paused)
		paused = false
		save.call(&"delete", 2)
		quit()
		return true
	return false
