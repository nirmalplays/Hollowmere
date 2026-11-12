class_name PauseMenu
extends CanvasLayer
## Esc in the field: the world stops and dims, and a short list comes up on the left in
## the title screen's hand (flame cursor, ash to ember). On the right, where you are and
## what you were doing. Sound levels are adjusted in place with Left/Right.
## Leaving through here keeps the journey.

const MENU_FONT: Font = preload("res://assets/fonts/PixelifySans.ttf")
const BODY_FONT: Font = preload("res://assets/fonts/Alegreya.ttf")
const TITLE_FONT: Font = preload("res://assets/fonts/Cinzel.ttf")
const ASH := Color(0.91, 0.88, 0.82)
const ASH_DIM := Color(0.62, 0.58, 0.54)
const EMBER := Color(1.0, 0.62, 0.25)
const EMBER_HOT := Color(1.0, 0.86, 0.55)
const MAIN_MENU_PATH: String = "res://scenes/ui/main_menu.tscn"
const ROW_H: float = 32.0
const LEFT: float = 70.0
const TOP: float = 190.0
const BUSES: Array = [["Music", &"Music"], ["Ambience", &"Ambient"], ["Effects", &"SFX"], ["Interface", &"UI"]]

var area: AreaScene

var _canvas: Control
var _rows: Array[Dictionary] = []  # {"label", "act"} or {"label", "bus"}
var _sel: int = 0
var _screen: String = "main"
var _t: float = 0.0
var _fade: float = 0.0


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.draw.connect(_draw_menu)
	add_child(_canvas)
	get_tree().paused = true
	AudioManager.sfx(&"ui_click", -8.0, 0.0)
	_show("main")


func _show(screen: String) -> void:
	_screen = screen
	_sel = 0
	if screen == "main":
		_rows = [
			{"label": "Resume", "act": close},
			{"label": "Sound", "act": func() -> void: _show("sound")},
			{"label": "Fullscreen", "act": _toggle_fullscreen},
			{"label": "Save and leave", "act": _leave},
			{"label": "Quit to desktop", "act": _quit},
		]
	else:
		_rows = []
		for bus in BUSES:
			_rows.append({"label": bus[0], "bus": bus[1]})
		_rows.append({"label": "Back", "act": func() -> void: _show("main")})


func close() -> void:
	get_tree().paused = false
	AudioManager.sfx(&"ui_back", -8.0, 0.0)
	queue_free()


func _toggle_fullscreen() -> void:
	var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)


func _leave() -> void:
	SaveManager.save_game()
	SaveManager.current_slot = -1
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func _quit() -> void:
	SaveManager.save_game()
	get_tree().quit()


func _process(delta: float) -> void:
	_t += delta
	_fade = minf(1.0, _fade + delta * 6.0)
	_canvas.queue_redraw()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_cancel"):
		if _screen == "main":
			close()
		else:
			_show("main")
	elif event.is_action_pressed(&"ui_down") or event.is_action_pressed(&"move_down"):
		_move(1)
	elif event.is_action_pressed(&"ui_up") or event.is_action_pressed(&"move_up"):
		_move(-1)
	elif event.is_action_pressed(&"ui_left") or event.is_action_pressed(&"move_left"):
		_nudge(-0.1)
	elif event.is_action_pressed(&"ui_right") or event.is_action_pressed(&"move_right"):
		_nudge(0.1)
	elif event.is_action_pressed(&"ui_accept"):
		_activate()
	elif event is InputEventMouseMotion:
		var i := _row_at(event.position)
		if i >= 0 and i != _sel:
			_sel = i
			AudioManager.sfx(&"ui_hover", -12.0, 0.04)
		return
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var i := _row_at(event.position)
		if i >= 0:
			_sel = i
			if _rows[i].has("bus"):
				AudioManager.set_bus_volume(_rows[i]["bus"], clampf((event.position.x - (LEFT + 150.0)) / 160.0, 0.0, 1.0))
			else:
				_activate()
	else:
		return
	get_viewport().set_input_as_handled()


func _row_at(at: Vector2) -> int:
	if at.x < LEFT - 30.0 or at.x > LEFT + 330.0:
		return -1
	var i := int(floor((at.y - TOP + ROW_H * 0.7) / ROW_H))
	return i if i >= 0 and i < _rows.size() else -1


func _move(by: int) -> void:
	_sel = (_sel + by + _rows.size()) % _rows.size()
	AudioManager.sfx(&"ui_hover", -10.0, 0.04)


func _nudge(by: float) -> void:
	var row: Dictionary = _rows[_sel]
	if row.has("bus"):
		AudioManager.set_bus_volume(row["bus"], clampf(AudioManager.get_bus_volume(row["bus"]) + by, 0.0, 1.0))
		AudioManager.sfx(&"ui_hover", -8.0, 0.0)


func _activate() -> void:
	var row: Dictionary = _rows[_sel]
	if row.has("act"):
		AudioManager.sfx(&"ui_click", -6.0, 0.0)
		(row["act"] as Callable).call()


func _draw_menu() -> void:
	var s := _canvas.get_viewport_rect().size
	var a := _fade
	_canvas.draw_rect(Rect2(Vector2.ZERO, s), Color(0.02, 0.015, 0.02, 0.72 * a))
	for i in 30:  # darker toward the list
		_canvas.draw_rect(Rect2(i * 14.0, 0, 14, s.y), Color(0, 0, 0, 0.5 * a * (1.0 - i / 30.0)))
	_shadowed(TITLE_FONT, Vector2(LEFT, TOP - 70), "PAUSED" if _screen == "main" else "SOUND", 30, Color(ASH, a))
	_canvas.draw_rect(Rect2(LEFT, TOP - 58, 120, 1), Color(EMBER, 0.8 * a))
	_canvas.draw_rect(Rect2(LEFT + 124, TOP - 58, 120, 1), Color(ASH_DIM, 0.4 * a))
	for i in _rows.size():
		var row: Dictionary = _rows[i]
		var y := TOP + i * ROW_H
		var on := i == _sel
		var col := (EMBER_HOT if on else ASH_DIM)
		col.a = a
		if on:
			var flick := 0.8 + 0.2 * sin(_t * 12.0)
			_canvas.draw_rect(Rect2(LEFT - 18, y - 11 - 3 * flick, 4, 6 + 3 * flick), Color(EMBER, a))
			_canvas.draw_rect(Rect2(LEFT - 17, y - 9, 2, 4), Color(EMBER_HOT, a))
		var label: String = row["label"]
		if label == "Fullscreen":
			label += "   " + ("on" if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else "off")
		_shadowed(MENU_FONT, Vector2(LEFT, y), label, 22, col)
		if row.has("bus"):
			var v := AudioManager.get_bus_volume(row["bus"])
			var bar := Rect2(LEFT + 150, y - 9, 160, 6)
			_canvas.draw_rect(bar.grow(1), Color(0.36, 0.32, 0.31, a))
			_canvas.draw_rect(bar, Color(0.09, 0.08, 0.09, a))
			_canvas.draw_rect(Rect2(bar.position, Vector2(bar.size.x * v, bar.size.y)), Color(EMBER if on else ASH_DIM, a))
	# Right: where you are and what you were doing.
	var right := s.x - 70.0
	var w := 340.0
	var place := ""
	var title := ""
	if area:
		place = area.place if area.place != "" else area.area_title
		title = area.area_title
	_shadowed(TITLE_FONT, Vector2(right - w, TOP - 70), place.to_upper(), 20, Color(ASH, a), HORIZONTAL_ALIGNMENT_RIGHT, w)
	if title != place:
		_shadowed(BODY_FONT, Vector2(right - w, TOP - 48), title, 15, Color(ASH_DIM, a), HORIZONTAL_ALIGNMENT_RIGHT, w)
	_canvas.draw_rect(Rect2(right - 160, TOP - 34, 160, 1), Color(EMBER, 0.6 * a))
	_shadowed(TITLE_FONT, Vector2(right - w, TOP - 8), QuestLog.title.to_upper(), 12, Color(EMBER, a), HORIZONTAL_ALIGNMENT_RIGHT, w)
	var y := TOP + 14.0
	for step: Dictionary in QuestLog.steps:
		if step["done"]:
			continue
		_shadowed(BODY_FONT, Vector2(right - w, y), step["text"], 17, Color(ASH, a), HORIZONTAL_ALIGNMENT_RIGHT, w)
		break
	var done := 0
	for step: Dictionary in QuestLog.steps:
		done += 1 if step["done"] else 0
	if not QuestLog.steps.is_empty():
		_shadowed(BODY_FONT, Vector2(right - w, y + 22), "%d of %d done" % [done, QuestLog.steps.size()], 14, Color(ASH_DIM, a), HORIZONTAL_ALIGNMENT_RIGHT, w)
	if SaveManager.current_slot >= 0:
		_shadowed(BODY_FONT, Vector2(right - w, s.y - 40), "Journey %s  ·  %s played  ·  kept when you leave" % [SaveManager.NUMERALS[SaveManager.current_slot], SaveManager.clock(SaveManager.play_time)], 14, Color(ASH_DIM, a), HORIZONTAL_ALIGNMENT_RIGHT, w)
	var hint := "Up / Down  choose     Enter  confirm     Esc  back" if _screen == "main" else "Left / Right  adjust     Esc  back"
	_shadowed(BODY_FONT, Vector2(LEFT, s.y - 40), hint, 14, Color(ASH_DIM, a))


func _shadowed(font: Font, at: Vector2, t: String, sz: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0) -> void:
	_canvas.draw_string(font, at + Vector2(1, 1), t, align, w, sz, Color(0, 0, 0, 0.85 * col.a))
	_canvas.draw_string(font, at, t, align, w, sz, col)
