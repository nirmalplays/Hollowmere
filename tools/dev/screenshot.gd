extends SceneTree
## Renders a scene for a moment and saves a PNG (needs a window, not --headless).
## godot --path . --script res://tools/dev/screenshot.gd -- <scene> <out.png> [frames] [hold_action]

var _frames_left: int = 45
var _out: String = "user://screenshot.png"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var scene_path: String = args[0] if args.size() > 0 else "res://scenes/ui/main_menu.tscn"
	if args.size() > 1:
		_out = args[1]
	if args.size() > 2:
		_frames_left = int(args[2])
	if args.size() > 3:
		Input.action_press(StringName(args[3]))
	root.add_child((load(scene_path) as PackedScene).instantiate())


func _process(_delta: float) -> bool:
	_frames_left -= 1
	if _frames_left == 0:
		var img := root.get_texture().get_image()
		img.save_png(_out)
		print("saved ", _out, " ", img.get_size())
		quit()
	return false
