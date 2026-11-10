extends SceneTree
## Headless M0 check: godot --headless --path . --script res://tests/m0_smoke.gd
## Exits non-zero on failure so it can gate commits/CI.

const REQUIRED_ACTIONS: Array[StringName] = [
	&"move_up", &"move_down", &"move_left", &"move_right", &"aim_up", &"aim_down",
	&"aim_left", &"aim_right", &"attack_light", &"attack_heavy", &"dodge", &"block",
	&"sprint", &"spell_1", &"spell_2", &"spell_3", &"spell_4", &"spell_5", &"interact",
	&"inventory", &"skill_tree", &"map", &"pause", &"ui_debug_overlay",
]
const REQUIRED_AUTOLOADS: Array[String] = ["EventBus", "DataRegistry", "GameState", "NetManager", "SaveManager"]


func _initialize() -> void:
	var failures: Array[String] = []
	for action in REQUIRED_ACTIONS:
		if not InputMap.has_action(action) or InputMap.action_get_events(action).is_empty():
			failures.append("missing/empty input action: %s" % action)
	for autoload_name in REQUIRED_AUTOLOADS:
		if not ProjectSettings.has_setting("autoload/%s" % autoload_name):
			failures.append("missing autoload: %s" % autoload_name)
	if ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter") != 0:
		failures.append("default texture filter is not Nearest")
	if ProjectSettings.get_setting("display/window/size/viewport_width") != 480:
		failures.append("viewport width is not 480")
	if load("res://scenes/ui/main_menu.tscn") == null:
		failures.append("main menu scene failed to load")
	for f in failures:
		printerr("FAIL: ", f)
	print("M0 smoke: %s" % ("FAILED (%d)" % failures.size() if failures else "OK"))
	quit(1 if failures else 0)
