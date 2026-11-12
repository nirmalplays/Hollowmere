extends SceneTree
## Dev: starts a Bruiser in the Shrine Wood, walks and swings, saves a screenshot.
##   godot --path . --script res://tools/dev/shot_hero.gd -- <out.png>

var _frame: int = 0


func _physics_process(_delta: float) -> bool:
	_frame += 1
	if _frame == 5:
		root.get_node("/root/SaveManager").call(&"new_game", 2, {"name": "Shot", "origin": "human", "class": "bruiser"})
	if _frame == 60:
		Input.action_press(&"move_right")
	if _frame == 100:
		Input.action_press(&"attack_light")
	if _frame == 124:
		var img := root.get_texture().get_image()
		img.save_png(OS.get_cmdline_user_args()[0])
		root.get_node("/root/SaveManager").call(&"delete", 2)
		quit()
		return true
	return false
