extends Control
## Title screen: the Ashen Reach at dusk (MenuBackdrop) with our lantern logotype
## (TitleLogo). On first boot the lantern is lit in the dark at the centre, then the logo
## settles top-left and the choices appear beneath it. The chosen line warms from ash to
## ember with a small flame beside it; what it does is written underneath, keys bottom-left.
## Up/Down/W/S, Enter/Space, Esc, or the mouse.

const SOLO_START_SCENE: String = "res://scenes/world/shrine_wood.tscn"
const MENU_FONT: Font = preload("res://assets/fonts/PixelifySans.ttf")
const BODY_FONT: Font = preload("res://assets/fonts/Alegreya.ttf")
const TITLE_FONT: Font = preload("res://assets/fonts/Cinzel.ttf")
const GOLD := Color(0.77, 0.58, 0.2)
const CREAM := Color(0.9, 0.86, 0.76)

static var intro_played: bool = false

var _backdrop: MenuBackdrop
var _logo: TitleLogo
var _list: VBoxContainer
var _hint: Label
var _rows: Array[Dictionary] = []  # {"label", "hint", "act", "off", "node"}
var _sel: int = 0
var _screen: String = "title"
var _panel: Control
var _shade: ColorRect
var _ready_for_input: bool = false
var _overlay: Control
var _armed_slot: int = -1  ## a filled slot picked for a new journey, waiting for the second press


func _ready() -> void:
	_backdrop = MenuBackdrop.new()
	add_child(_backdrop)
	var vignette := ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.material = _vignette_material()
	add_child(vignette)
	_logo = TitleLogo.new()
	add_child(_logo)
	_shade = ColorRect.new()
	_shade.color = Color(0, 0, 0, 1)
	_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shade)
	_build_list()
	_build_corner()
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.draw.connect(func() -> void: _draw_overlay(overlay))
	add_child(overlay)
	_overlay = overlay
	AudioManager.music(&"music_menu", 2.0)
	if intro_played:
		_shade.color.a = 0.0
		_settle(true)
	else:
		_place_logo_centre()
		_logo.impact.connect(func() -> void:
			AudioManager.sfx(&"thunder", -2.0, 0.0)
			HitFeedback.shake(4.0, 0.4))
		_logo.finished.connect(func() -> void: _settle(false))
		var tw := create_tween()
		tw.tween_property(_shade, ^"color:a", 0.55, 1.2)
		tw.tween_callback(_logo.play_intro)


func _place_logo_centre() -> void:
	var s := get_viewport_rect().size
	_logo.scale = Vector2(1.3, 1.3)
	_logo.position = Vector2(s.x * 0.5 - _logo.size.x * 0.65, s.y * 0.4 - _logo.size.y * 0.65)


## The title moves to the left and the list comes in.
func _settle(instant: bool) -> void:
	intro_played = true
	var s := get_viewport_rect().size
	var to_pos := Vector2(s.x * 0.065, s.y * 0.1)
	var to_scale := Vector2(1.0, 1.0)
	if instant:
		_logo.position = to_pos
		_logo.scale = to_scale
	else:
		var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(_logo, ^"position", to_pos, 1.1)
		tw.tween_property(_logo, ^"scale", to_scale, 1.1)
		tw.tween_property(_shade, ^"color:a", 0.0, 1.2)
	_show_screen("title")
	_ready_for_input = true


# ---------------------------------------------------------------- the list

func _items(screen: String) -> Array[Dictionary]:
	match screen:
		"title":
			var latest := SaveManager.latest_slot()
			return [
				{"label": "Continue", "hint": SaveManager.describe(latest) if latest >= 0 else "No journey has been begun yet", "act": func() -> void: _begin(latest, false), "off": latest < 0},
				{"label": "New Journey", "hint": "Wake in the Underroot. Act I: The Waking", "act": func() -> void: _show_screen("new")},
				{"label": "Journeys", "hint": "Three cradles, three journeys: pick one up again", "act": func() -> void: _show_screen("load"), "off": latest < 0},
				{"label": "Co-op", "hint": "Fight beside up to 7 friends (coming later)", "act": func() -> void: pass, "off": true},
				{"label": "Settings", "hint": "Sound, screen and feel", "act": func() -> void: _open_panel(_settings_panel())},
				{"label": "Credits", "hint": "The people whose work made this", "act": func() -> void: _open_panel(_credits_panel())},
				{"label": "Quit", "hint": "Leave Orsolen for now", "act": func() -> void: get_tree().quit()},
			]
		"new", "load":
			var rows: Array[Dictionary] = []
			for i in SaveManager.SLOTS:
				var filled := SaveManager.has(i)
				var hint := SaveManager.describe(i)
				if screen == "new":
					hint = ("Begin here.  " if not filled else "Begin anew here, erasing:  ") + (hint if filled else "")
				rows.append({"label": "Journey %s%s" % [SaveManager.NUMERALS[i], "" if filled else "   (empty)"], "hint": hint,
					"act": _pick_slot.bind(i, screen == "new"), "off": screen == "load" and not filled})
			rows.append({"label": "Back", "hint": "", "act": func() -> void: _show_screen("title")})
			return rows
	return [{"label": "Back", "hint": "", "act": _close_panel}]


func _build_list() -> void:
	_list = VBoxContainer.new()
	_list.add_theme_constant_override(&"separation", 2)
	_list.custom_minimum_size = Vector2(320, 0)
	add_child(_list)
	_hint = _label(BODY_FONT, 15, Color(1, 1, 1, 0.65))
	add_child(_hint)


func _show_screen(screen: String) -> void:
	_screen = screen
	for c in _list.get_children():
		c.queue_free()
	_rows.clear()
	var s := get_viewport_rect().size
	var i := 0
	for item in _items(screen):
		var row := _MenuRow.new()
		row.text = item["label"]
		row.disabled = item.get("off", false)
		row.font = MENU_FONT
		row.custom_minimum_size = Vector2(320, 34)
		row.mouse_entered.connect(_select.bind(i))
		row.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				_activate())
		row.modulate.a = 0.0
		_list.add_child(row)
		var tw := create_tween()
		tw.tween_interval(0.15 + i * 0.07)
		tw.tween_property(row, ^"modulate:a", 1.0, 0.4)
		item["node"] = row
		_rows.append(item)
		i += 1
	_list.position = Vector2(s.x * 0.065 - 4, s.y * 0.37)
	_hint.position = Vector2(s.x * 0.065, _list.position.y + _rows.size() * 36 + 14)
	_hint.add_theme_font_size_override(&"font_size", 15)
	_sel = 0
	_armed_slot = -1
	while _sel < _rows.size() - 1 and _rows[_sel].get("off", false):
		_sel += 1
	_select(_sel)


func _select(i: int) -> void:
	if _rows.is_empty():
		return
	if i != _sel:
		AudioManager.sfx(&"ui_move", -10.0, 0.04)
	_sel = clampi(i, 0, _rows.size() - 1)
	for j in _rows.size():
		(_rows[j]["node"] as _MenuRow).selected = j == _sel
	_hint.text = _rows[_sel].get("hint", "")
	if _overlay:
		_overlay.queue_redraw()


func _activate() -> void:
	var item: Dictionary = _rows[_sel]
	if item.get("off", false):
		AudioManager.sfx(&"ui_back", -6.0, 0.0)
		return
	AudioManager.sfx(&"ui_select", -4.0, 0.0)
	(item["act"] as Callable).call()


func _unhandled_input(event: InputEvent) -> void:
	if not _ready_for_input:
		if event.is_pressed() and _logo.is_playing():
			_logo.skip()
		return
	if _panel and event.is_action_pressed(&"ui_cancel"):
		_close_panel()
	elif _screen != "title" and event.is_action_pressed(&"ui_cancel"):
		AudioManager.sfx(&"ui_back", -6.0, 0.0)
		_show_screen("title")
	elif event.is_action_pressed(&"ui_down") or event.is_action_pressed(&"move_down"):
		_select((_sel + 1) % _rows.size())
	elif event.is_action_pressed(&"ui_up") or event.is_action_pressed(&"move_up"):
		_select((_sel + _rows.size() - 1) % _rows.size())
	elif event.is_action_pressed(&"ui_accept"):
		_activate()
	else:
		return
	get_viewport().set_input_as_handled()


func _draw_overlay(c: Control) -> void:
	# The rule under the list, fading to the left like the reference.
	if _rows.is_empty() or _panel or not _list.visible:
		return
	var s := get_viewport_rect().size
	var x0 := s.x * 0.065
	var y := _list.position.y + _rows.size() * 36 + 6
	c.draw_line(Vector2(x0, y), Vector2(x0 + 240, y), Color(CREAM, 0.35), 1.0)
	# Keys, bottom-left.
	var at := Vector2(x0, s.y - 40)
	c.draw_rect(Rect2(at, Vector2(46, 18)), Color(0.96, 0.95, 0.92))
	c.draw_rect(Rect2(at + Vector2(0, 16), Vector2(46, 2)), Color(0.6, 0.58, 0.55))
	c.draw_string(MENU_FONT, at + Vector2(7, 14), "Enter", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.2, 0.16, 0.3))
	c.draw_string(MENU_FONT, at + Vector2(52, 14), "Select", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.85))


# ---------------------------------------------------------------- actions and panels

## A slot was chosen. Starting over a kept journey takes a second press.
func _pick_slot(slot: int, fresh: bool) -> void:
	if fresh and SaveManager.has(slot) and _armed_slot != slot:
		_armed_slot = slot
		_hint.text = "This journey will be erased. Press again to begin anew."
		return
	_begin(slot, fresh)


func _begin(slot: int, fresh: bool) -> void:
	_ready_for_input = false
	AudioManager.sfx(&"game_start", -4.0, 0.0)
	AudioManager.stop_music(1.0)
	var tw := create_tween()
	tw.tween_property(_shade, ^"color:a", 1.0, 0.9)
	tw.tween_callback(func() -> void:
		if fresh or not SaveManager.load_game(slot):
			SaveManager.new_game(slot))


func _open_panel(panel: Control) -> void:
	_panel = panel
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.03, 0.02, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(panel)
	add_child(dim)
	panel.position = (get_viewport_rect().size - panel.size) * 0.5
	_panel = dim
	_list.visible = false
	_hint.visible = false
	_overlay.queue_redraw()


func _close_panel() -> void:
	if _panel:
		AudioManager.sfx(&"ui_back", -6.0, 0.0)
		_panel.queue_free()
		_panel = null
	_list.visible = true
	_hint.visible = true
	_overlay.queue_redraw()


func _settings_panel() -> Control:
	var box := _parchment(Vector2(460, 330), "Settings")
	var v: VBoxContainer = box.get_child(0)
	for bus in [["Music", &"Music"], ["Ambience", &"Ambient"], ["Effects", &"SFX"], ["Interface", &"UI"]]:
		var row := HBoxContainer.new()
		var name := _label(BODY_FONT, 17, Color(0.18, 0.15, 0.2))
		name.text = bus[0]
		name.custom_minimum_size = Vector2(140, 0)
		row.add_child(name)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.custom_minimum_size = Vector2(240, 24)
		slider.value = AudioManager.get_bus_volume(bus[1])
		slider.value_changed.connect(func(val: float) -> void:
			AudioManager.set_bus_volume(bus[1], val)
			AudioManager.sfx(&"ui_move", -8.0, 0.0))
		row.add_child(slider)
		v.add_child(row)
	var fs := CheckButton.new()
	fs.text = "Fullscreen"
	fs.add_theme_font_override(&"font", BODY_FONT)
	fs.add_theme_font_size_override(&"font_size", 17)
	fs.add_theme_color_override(&"font_color", Color(0.18, 0.15, 0.2))
	fs.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fs.toggled.connect(func(on: bool) -> void:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_MAXIMIZED))
	v.add_child(fs)
	v.add_child(_back_button())
	return box


func _credits_panel() -> Control:
	var box := _parchment(Vector2(560, 380), "Credits")
	var v: VBoxContainer = box.get_child(0)
	var text := RichTextLabel.new()
	text.custom_minimum_size = Vector2(500, 230)
	text.add_theme_font_override(&"normal_font", BODY_FONT)
	text.add_theme_font_size_override(&"normal_font_size", 15)
	text.add_theme_color_override(&"default_color", Color(0.18, 0.15, 0.2))
	text.text = "Hollowmere, an early build by the team.\n\n" \
		+ "Characters, crypt tiles and props: the Liberated Pixel Cup artists (CC-BY-SA 3.0 / GPL 3.0), see LPC_CREDITS.csv.\n" \
		+ "Effects: pixelfx (MIT). Fonts: Cinzel, Alegreya, Pixelify Sans, Press Start 2P (SIL OFL).\n" \
		+ "Sound: the team's music and effect packs; RPG Sound Pack (artisticdude), 80 CC0 RPG SFX (rubberduck), " \
		+ "RPG Sound Effects (Kenney), all CC0.\n\nFull list: ASSETS.md."
	v.add_child(text)
	v.add_child(_back_button())
	return box


func _parchment(size: Vector2, title: String) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = size
	panel.size = size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.93, 0.87, 0.74)
	style.border_color = GOLD
	style.set_border_width_all(4)
	style.set_corner_radius_all(4)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 8
	panel.add_theme_stylebox_override(&"panel", style)
	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", 12)
	panel.add_child(v)
	var head := _label(TITLE_FONT, 28, Color(0.18, 0.15, 0.2))
	head.text = title
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(head)
	return panel


func _back_button() -> Button:
	var b := Button.new()
	b.text = "Back"
	b.add_theme_font_override(&"font", MENU_FONT)
	b.add_theme_font_size_override(&"font_size", 18)
	b.pressed.connect(_close_panel)
	return b


func _build_corner() -> void:
	var s := get_viewport_rect().size
	var tag := _label(MENU_FONT, 11, Color(1, 1, 1, 0.35))
	tag.text = "HOLLOWMERE  ·  EARLY BUILD"
	tag.position = Vector2(s.x - 210, s.y - 22)
	add_child(tag)
	var sound := Button.new()
	sound.text = "Sound on"
	sound.add_theme_font_override(&"font", MENU_FONT)
	sound.add_theme_font_size_override(&"font_size", 13)
	sound.position = Vector2(s.x - 100, 14)
	sound.pressed.connect(func() -> void:
		var muted := AudioServer.is_bus_mute(0)
		AudioServer.set_bus_mute(0, not muted)
		sound.text = "Sound on" if muted else "Sound off")
	add_child(sound)


func _label(font: Font, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_override(&"font", font)
	l.add_theme_font_size_override(&"font_size", font_size)
	l.add_theme_color_override(&"font_color", color)
	l.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override(&"shadow_offset_y", 2)
	return l


func _vignette_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
void fragment() {
	// Shade where the words sit (left title, right list) so they read over the forest.
	float edge = smoothstep(0.5, 0.0, UV.x) * 0.6;
	float v = smoothstep(0.35, 0.95, distance(UV, vec2(0.5))) * 0.5;
	COLOR = vec4(0.008, 0.024, 0.016, clamp(edge + v, 0.0, 0.85));
}"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	return mat


## One choice: right-aligned words; when chosen, a gold band behind them and a sword
## pointing at them.
class _MenuRow:
	extends Control
	var text: String = ""
	var font: Font
	var disabled: bool = false
	var selected: bool = false:
		set(v):
			selected = v
			_warm = 0.0 if v else _warm
			queue_redraw()
	var _t: float = 0.0
	var _warm: float = 0.0

	func _process(delta: float) -> void:
		_t += delta
		_warm = move_toward(_warm, 1.0 if selected else 0.0, delta * 5.0)
		queue_redraw()

	func _draw() -> void:
		var ash := Color(0.62, 0.6, 0.58) if not disabled else Color(0.4, 0.38, 0.38)
		var ember := Color(1.0, 0.78, 0.45)
		var col := ash.lerp(ember, _warm) if not disabled else ash
		var fs := 24
		var x := 26.0 + 6.0 * _warm
		var y := size.y * 0.5 + fs * 0.35
		if _warm > 0.01:
			# A small flame beside the chosen line.
			var f := 0.85 + 0.15 * sin(_t * 12.0) * sin(_t * 7.0)
			var c := Vector2(10, size.y * 0.5)
			draw_circle(c, 9.0 * f, Color(1.0, 0.55, 0.2, 0.15 * _warm))
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -7 * f), c + Vector2(3, 0), c + Vector2(0, 4), c + Vector2(-3, 0)]), Color(1.0, 0.7, 0.3, _warm))
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -3 * f), c + Vector2(1.5, 1), c + Vector2(0, 3), c + Vector2(-1.5, 1)]), Color(1.0, 0.95, 0.75, _warm))
		draw_string(font, Vector2(x, y + 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, 0.7))
		draw_string(font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
