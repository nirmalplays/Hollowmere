extends SceneTree
## Dev: stands a Bruiser beside a crawler, lands a heavy hit, and saves a screenshot
## during the hit-stop and another half a second later (do the bodies stay on screen?).
##   godot --path . --script res://tools/dev/shot_hit.gd -- <out prefix>

var _frame: int = 0
var _stopped: int = 0
var _hit_frame: int = -1
var _saved: bool = false


func _process(_delta: float) -> bool:
	if Engine.time_scale < 0.5:
		_stopped += 1
		if _stopped == 2 and not _saved:
			_saved = true
			root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0] + "_stop.png")
			var p: Node2D = current_scene.get("player")
			print("during stop: sprite scale ", p.get("sprite").scale, " pos ", p.global_position, " visible ", p.visible)
	return false


func _physics_process(_delta: float) -> bool:
	_frame += 1
	if _frame == 5:
		root.get_node("/root/SaveManager").call(&"new_game", 2, {"name": "Shot", "origin": "human", "class": "bruiser"})
	if _frame == 60:
		var area: Node = current_scene
		var player: Node2D = area.get("player")
		root.get_node("/root/GameState").flags[&"has_cradle_lantern"] = true
		var crawler: Node2D = area.call(&"enemies_with_char", "c")[0]
		player.global_position = crawler.global_position + Vector2(-34, 0)
		player.reset_physics_interpolation()
		player.call(&"face", Vector2.RIGHT)
		Input.action_press(&"attack_heavy")
	if _frame == 64:
		Input.action_release(&"attack_heavy")
	if _saved and _hit_frame < 0:
		_hit_frame = _frame
	if _hit_frame > 0 and _frame == _hit_frame + 30:
		root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0] + "_after.png")
		var p: Node2D = current_scene.get("player")
		print("after: sprite scale ", p.get("sprite").scale, " pos ", p.global_position)
		for e in root.get_tree().get_nodes_in_group(&"enemies"):
			if e.global_position.distance_to(p.global_position) < 120:
				print("  enemy scale ", e.get("sprite").scale, " pos ", e.global_position, " hp ", e.get("hp"))
		root.get_node("/root/SaveManager").call(&"delete", 2)
		quit()
		return true
	if _frame > 400:
		print("no hit-stop seen")
		quit()
		return true
	return false
