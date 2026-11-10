extends SceneTree
## Renders a scene and saves a PNG (needs a window, not --headless).
##   godot --path . --script res://tools/dev/screenshot.gd -- <scene> <out.png> [frames] [action:from:to ...]
## Each action is held from frame `from` to frame `to`, e.g. move_right:5:40 attack_light:60:62

var _frame: int = 0
var _capture_at: int = 45
var _out: String = "user://screenshot.png"
var _inputs: Array[Dictionary] = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var scene_path: String = args[0] if args.size() > 0 else "res://scenes/ui/main_menu.tscn"
	if args.size() > 1:
		_out = args[1]
	if args.size() > 2:
		_capture_at = int(args[2])
	for i in range(3, args.size()):
		var parts := args[i].split(":")
		_inputs.append({"action": StringName(parts[0]), "from": int(parts[1]), "to": int(parts[2]) if parts.size() > 2 else int(parts[1]) + 2})
	root.add_child.call_deferred((load(scene_path) as PackedScene).instantiate())


func _physics_process(_delta: float) -> bool:
	_frame += 1
	for input in _inputs:
		if _frame == input["from"]:
			Input.action_press(input["action"])
		elif _frame == input["to"]:
			Input.action_release(input["action"])
	if _frame == _capture_at:
		var img := root.get_texture().get_image()
		img.save_png(_out)
		print("saved ", _out, " ", img.get_size())
		quit()
	return false
