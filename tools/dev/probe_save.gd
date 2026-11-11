extends SceneTree
## Dev probe: new journey in slot III, take the lantern, kill a crawler, save, reload,
## and check the journey came back. Leaves slot III deleted.
##   godot --headless --path . --script res://tools/dev/probe_save.gd

const SLOT: int = 2

var _frame: int = 0
var _stage: int = 0
var _pos: Vector2


func _initialize() -> void:
	pass


func _physics_process(_delta: float) -> bool:
	_frame += 1
	var save: Node = root.get_node("/root/SaveManager")
	var area: Node = current_scene
	if _frame == 5:
		save.call(&"new_game", SLOT)
	if _frame == 40:
		var player: Node2D = area.get("player")
		for n in area.get("entities").get_children():
			if n.get_meta(&"marker", "") == "L":
				n.emit_signal(&"read")
		var crawler: Node = area.call(&"enemies_with_char", "c")[0]
		crawler.set("hp", 0.0)
		crawler.call(&"_enter", 7)
		player.global_position += Vector2(40, 10)
		player.set("flasks", 1)
		_pos = player.global_position
	if _frame == 50:
		save.call(&"save_game")
		print("saved: ", save.call(&"has", SLOT), "  ", save.call(&"describe", SLOT))
		save.set("current_slot", -1)
		print("load ok: ", save.call(&"load_game", SLOT))
	if _frame == 90:
		var player: Node2D = area.get("player")
		var flags: Dictionary = root.get_node("/root/GameState").flags
		var alive := 0
		for e in area.call(&"enemies_with_char", "c"):
			if is_instance_valid(e) and not e.is_queued_for_deletion():
				alive += 1
		print("position kept: ", player.global_position.distance_to(_pos) < 2.0)
		print("flasks kept: ", player.get("flasks") == 1)
		print("lantern kept: ", flags.get(&"has_cradle_lantern", false))
		print("crawlers alive (want 2): ", alive)
		print("objective: ", root.get_node("/root/QuestLog").steps[1]["done"], " / step0 done ", root.get_node("/root/QuestLog").steps[0]["done"])
		save.call(&"delete", SLOT)
		quit()
		return true
	return false
