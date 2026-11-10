extends IntegrationTest
## M0: autoloads, input actions, pixel settings, main menu loads.

const REQUIRED_ACTIONS: Array[StringName] = [
	&"move_up", &"move_down", &"move_left", &"move_right", &"aim_up", &"aim_down",
	&"aim_left", &"aim_right", &"attack_light", &"attack_heavy", &"dodge", &"block",
	&"sprint", &"spell_1", &"spell_2", &"spell_3", &"spell_4", &"spell_5", &"interact",
	&"inventory", &"skill_tree", &"map", &"pause", &"ui_debug_overlay",
]
const REQUIRED_AUTOLOADS: Array[String] = [
	"EventBus", "DataRegistry", "GameState", "NetManager", "SaveManager", "HitFeedback", "DebugOverlay",
]


func _run() -> void:
	for action in REQUIRED_ACTIONS:
		check(InputMap.has_action(action) and not InputMap.action_get_events(action).is_empty(), "input action %s" % action)
	for autoload_name in REQUIRED_AUTOLOADS:
		check(get_tree().root.has_node(autoload_name), "autoload %s" % autoload_name)
	check(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter") == 0, "Nearest filter")
	check(ProjectSettings.get_setting("display/window/size/viewport_width") == 960, "viewport 960 wide")
	check(load("res://scenes/ui/main_menu.tscn") != null, "main menu loads")
