extends CanvasLayer
## F3 debug overlay (GAME_PLAN 15): FPS, node count, players, peers.

var _label: Label


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label = Label.new()
	_label.position = Vector2(4, 4)
	_label.add_theme_color_override(&"font_color", Color(1, 1, 0.6))
	_label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_label.add_theme_constant_override(&"outline_size", 2)
	_label.add_theme_font_size_override(&"font_size", 8)
	add_child(_label)
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_debug_overlay"):
		visible = not visible


func _process(_delta: float) -> void:
	if not visible:
		return
	_label.text = "FPS %d\nnodes %d\nplayers %d\nonline %s" % [
		Engine.get_frames_per_second(),
		get_tree().get_node_count(),
		GameState.players.size(),
		str(NetManager.is_online),
	]
