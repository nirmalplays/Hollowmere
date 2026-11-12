class_name CharacterCreator
extends Control
## "Who were you?" The screen between New Journey and waking. Three columns: on the left
## the two choices (origin: the body you were buried in; class: what you were buried
## with), in the middle the hero standing in lantern light, turning and swinging as you
## choose, on the right what that choice means in play: trait, weapon, ability, and
## five attribute bars. Then a name, and Wake.
## Up/Down pick, Left/Right or Tab change list, Enter moves on, Esc goes back.

const TITLE_FONT: Font = preload("res://assets/fonts/Cinzel.ttf")
const BODY_FONT: Font = preload("res://assets/fonts/Alegreya.ttf")
const MENU_FONT: Font = preload("res://assets/fonts/PixelifySans.ttf")
const ASH := Color(0.91, 0.88, 0.82)
const ASH_DIM := Color(0.6, 0.56, 0.52)
const EMBER := Color(1.0, 0.62, 0.25)
const EMBER_HOT := Color(1.0, 0.86, 0.55)
const IRON := Color(0.36, 0.32, 0.31)
const MAIN_MENU_PATH: String = "res://scenes/ui/main_menu.tscn"
const LIST_X: float = 56.0
const ORIGIN_Y: float = 150.0
const CLASS_Y: float = 300.0
const ROW_H: float = 30.0
const NAMES: Array[String] = ["Aldous", "Brannoch", "Cerys", "Dunmor", "Edda", "Hale", "Isolde", "Marrow", "Oswin", "Perrin", "Rook", "Sable", "Tamsel", "Wren"]

static var slot: int = 0  ## the journey this hero is for (set by the title screen)

var _origin: int = 0
var _class: int = 0
var _column: int = 0  # 0 origin, 1 class, 2 name
var _t: float = 0.0
var _hero: AnimatedSprite2D
var _name: LineEdit
var _leaving: bool = false
var _facing: int = 0
var _swing_left: float = 0.0
var _embers: Array[Dictionary] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_hero = AnimatedSprite2D.new()
	_hero.scale = Vector2(3, 3)
	_hero.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_hero)
	_name = LineEdit.new()
	_name.max_length = 14
	_name.placeholder_text = "a name"
	_name.text = NAMES[randi() % NAMES.size()]
	_name.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.add_theme_font_override(&"font", TITLE_FONT)
	_name.add_theme_font_size_override(&"font_size", 20)
	_name.add_theme_color_override(&"font_color", ASH)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.07, 0.06, 0.06, 0.9)
	box.border_color = IRON
	box.set_border_width_all(1)
	box.border_width_bottom = 2
	box.set_content_margin_all(6)
	_name.add_theme_stylebox_override(&"normal", box)
	var lit := box.duplicate() as StyleBoxFlat
	lit.border_color = EMBER
	_name.add_theme_stylebox_override(&"focus", lit)
	_name.text_submitted.connect(func(_text: String) -> void: _wake())
	_name.focus_entered.connect(func() -> void: _column = 2)
	add_child(_name)
	AudioManager.music(&"music_menu", 1.0)
	_layout()
	get_viewport().size_changed.connect(_layout)
	_refresh(true)
	modulate.a = 0.0
	create_tween().tween_property(self, ^"modulate:a", 1.0, 0.5)


func _layout() -> void:
	var s := get_viewport_rect().size
	_hero.position = Vector2(s.x * 0.5, s.y * 0.5 + 44)
	_name.size = Vector2(220, 34)
	_name.position = Vector2(s.x * 0.5 - 110, s.y - 118)


func _profile() -> Dictionary:
	return {"name": _name.text.strip_edges() if _name.text.strip_edges() != "" else "Unlaid",
		"origin": Heroes.origins()[_origin]["id"], "class": Heroes.classes()[_class]["id"]}


func _refresh(first: bool = false) -> void:
	var path := Heroes.sheet_path(_profile())
	if ResourceLoader.exists(path):
		var sheet: SpriteSheetDef = load(path)
		_hero.sprite_frames = SpriteFramesBuilder.build(sheet)
		_hero.offset = sheet.foot_offset()
	_hero.scale = Vector2(3, 3) * float(Heroes.origins()[_origin]["scale"])
	_facing = 0
	if first:
		_hero.play(&"idle_s")
	else:
		_swing()


## Show the class off: a swing toward the viewer, then back to standing.
func _swing() -> void:
	if _hero.sprite_frames and _hero.sprite_frames.has_animation(&"attack_s"):
		_hero.speed_scale = 1.0
		_hero.play(&"attack_s")
		_swing_left = 0.55


func _process(delta: float) -> void:
	_t += delta
	if _swing_left > 0.0:
		_swing_left -= delta
		if _swing_left <= 0.0:
			_hero.play(&"idle_s")
	if randf() < delta * 5.0:
		var s := get_viewport_rect().size
		_embers.append({"p": Vector2(s.x * 0.5 + randf_range(-70, 70), s.y * 0.5 + 60), "v": Vector2(randf_range(-6, 6), -randf_range(12, 26)), "life": randf_range(1.5, 3.0)})
	for e in _embers:
		e["p"] += e["v"] * delta
		e["life"] -= delta
	_embers = _embers.filter(func(e: Dictionary) -> bool: return e["life"] > 0.0)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _leaving:
		return
	if event.is_action_pressed(&"ui_cancel"):
		_leave(MAIN_MENU_PATH)
	elif event.is_action_pressed(&"ui_down"):
		_step(1)
	elif event.is_action_pressed(&"ui_up"):
		_step(-1)
	elif event.is_action_pressed(&"ui_right") or event.is_action_pressed(&"ui_focus_next"):
		_set_column(_column + 1)
	elif event.is_action_pressed(&"ui_left"):
		_set_column(_column - 1)
	elif event.is_action_pressed(&"ui_accept"):
		if _column < 2:
			_set_column(_column + 1)
		else:
			_wake()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_click(event.position)
	else:
		return
	get_viewport().set_input_as_handled()


func _set_column(c: int) -> void:
	_column = clampi(c, 0, 2)
	AudioManager.sfx(&"ui_hover", -10.0, 0.04)
	if _column == 2:
		_name.grab_focus()
		_name.caret_column = _name.text.length()
	else:
		_name.release_focus()


func _step(by: int) -> void:
	if _column == 0:
		_origin = posmod(_origin + by, Heroes.origins().size())
	elif _column == 1:
		_class = posmod(_class + by, Heroes.classes().size())
	else:
		return
	AudioManager.sfx(&"ui_hover", -8.0, 0.04)
	_refresh()


func _click(at: Vector2) -> void:
	var s := get_viewport_rect().size
	if Rect2(s.x * 0.5 - 90, s.y - 70, 180, 40).has_point(at):
		_wake()
		return
	for col in 2:
		var top := ORIGIN_Y if col == 0 else CLASS_Y
		var count: int = Heroes.origins().size() if col == 0 else Heroes.classes().size()
		for i in count:
			if Rect2(LIST_X - 24, top + i * ROW_H - 20, 230, ROW_H).has_point(at):
				_name.release_focus()
				_column = col
				if col == 0:
					_origin = i
				else:
					_class = i
				AudioManager.sfx(&"ui_click", -8.0, 0.0)
				_refresh()
				return


func _wake() -> void:
	var hero := _profile()
	_leaving = true
	AudioManager.sfx(&"game_start", -4.0, 0.0)
	AudioManager.stop_music(1.0)
	var tw := create_tween()
	tw.tween_property(self, ^"modulate:a", 0.0, 0.8)
	tw.tween_callback(func() -> void: SaveManager.new_game(slot, hero))


func _leave(path: String) -> void:
	_leaving = true
	AudioManager.sfx(&"ui_back", -6.0, 0.0)
	var tw := create_tween()
	tw.tween_property(self, ^"modulate:a", 0.0, 0.3)
	tw.tween_callback(func() -> void: get_tree().change_scene_to_file(path))


# ---------------------------------------------------------------- drawing

func _draw() -> void:
	var s := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.035, 0.03, 0.035))
	var c := Vector2(s.x * 0.5, s.y * 0.5 + 44)
	# The pool of lantern light the hero stands in, and the stone under their feet.
	var flick := 0.92 + 0.08 * sin(_t * 9.0) * sin(_t * 5.7)
	for i in 7:
		draw_circle(c + Vector2(0, -50), (250.0 - i * 30.0) * flick, Color(1.0, 0.6, 0.25, 0.022))
	for i in 5:
		var w := 150.0 - i * 16.0
		_ellipse(c + Vector2(0, 6), w, w * 0.32, Color(0.2 + i * 0.03, 0.17 + i * 0.025, 0.15 + i * 0.02))
	_ellipse(c + Vector2(0, 2), 34, 9, Color(0, 0, 0, 0.45))
	for e in _embers:
		var a: float = clampf(e["life"], 0.0, 1.0)
		draw_rect(Rect2(e["p"], Vector2(2, 2)), Color(1.0, 0.65 + 0.3 * a, 0.3, a * 0.8))
	# Heading.
	_text(TITLE_FONT, Vector2(0, 62), "WHO WERE YOU?", 30, ASH, HORIZONTAL_ALIGNMENT_CENTER, s.x)
	_text(BODY_FONT, Vector2(0, 86), "The cradle kept your body. It did not keep your name.", 15, ASH_DIM, HORIZONTAL_ALIGNMENT_CENTER, s.x)
	draw_rect(Rect2(s.x * 0.5 - 60, 96, 120, 1), Color(EMBER, 0.7))
	_draw_list("ORIGIN", "the body you were buried in", Heroes.origins(), _origin, ORIGIN_Y, _column == 0)
	_draw_list("CLASS", "what you were buried with", Heroes.classes(), _class, CLASS_Y, _column == 1)
	_draw_details(s)
	# Name and the way on.
	_text(TITLE_FONT, Vector2(0, s.y - 126), "NAME", 11, EMBER if _column == 2 else ASH_DIM, HORIZONTAL_ALIGNMENT_CENTER, s.x)
	var wake := Rect2(s.x * 0.5 - 90, s.y - 70, 180, 36)
	var hot := _column == 2
	draw_rect(wake.grow(1), EMBER if hot else IRON)
	draw_rect(wake, Color(0.16, 0.1, 0.07) if hot else Color(0.08, 0.07, 0.07))
	_text(TITLE_FONT, wake.position + Vector2(0, 25), "WAKE", 20, EMBER_HOT if hot else ASH_DIM, HORIZONTAL_ALIGNMENT_CENTER, wake.size.x)
	_text(BODY_FONT, Vector2(LIST_X, s.y - 12), "Up / Down  choose     Left / Right  change list     Enter  next     Esc  back", 14, ASH_DIM)


func _draw_list(head: String, sub: String, rows: Array, picked: int, top: float, active: bool) -> void:
	_text(TITLE_FONT, Vector2(LIST_X, top - 36), head, 13, EMBER if active else ASH_DIM)
	_text(BODY_FONT, Vector2(LIST_X + 70, top - 36), sub, 13, Color(ASH_DIM, 0.8))
	draw_rect(Rect2(LIST_X, top - 28, 210, 1), Color(EMBER if active else IRON, 0.7))
	for i in rows.size():
		var y := top + i * ROW_H
		var on := i == picked
		if on:
			var flick := 0.8 + 0.2 * sin(_t * 12.0)
			var flame := EMBER if active else ASH_DIM
			draw_rect(Rect2(LIST_X - 16, y - 11 - 3 * flick, 4, 6 + 3 * flick), flame)
		_text(MENU_FONT, Vector2(LIST_X, y), rows[i]["name"], 22, (EMBER_HOT if active else ASH) if on else ASH_DIM)


func _draw_details(s: Vector2) -> void:
	var o: Dictionary = Heroes.origins()[_origin]
	var c: Dictionary = Heroes.classes()[_class]
	var x := s.x - 330.0
	var w := 290.0
	var y := 150.0
	_text(TITLE_FONT, Vector2(x, y), Heroes.title(_profile()).to_upper(), 20, ASH)
	y += 18
	_text(BODY_FONT, Vector2(x, y), c["role"], 14, EMBER)
	y += 10
	draw_rect(Rect2(x, y, 90, 1), EMBER)
	draw_rect(Rect2(x + 94, y, w - 94, 1), Color(IRON, 0.7))
	y += 20
	y = _para(Vector2(x, y), (o if _column == 0 else c)["blurb"], w, ASH, 15) + 10
	for line: Array in [[o["trait"], o["trait_text"]], [c["weapon_name"], c["attack_text"]], [c["ability_name"] + "  [" + Keys.label(&"spell_1") + "]", c["ability_text"]]]:
		draw_rect(Rect2(x, y - 9, 3, 3), EMBER)
		_text(TITLE_FONT, Vector2(x + 10, y - 3), String(line[0]).to_upper(), 11, EMBER_HOT)
		y = _para(Vector2(x + 10, y + 13), line[1], w - 10, ASH_DIM, 14) + 8
	# Attribute bars: six pips each.
	y += 4
	var stats := Heroes.attributes(_profile())
	for a in Heroes.ATTRIBUTES:
		_text(TITLE_FONT, Vector2(x, y), a.to_upper(), 10, ASH_DIM)
		for i in 6:
			var pip := Rect2(x + 86 + i * 20, y - 8, 16, 7)
			draw_rect(pip, Color(0.16, 0.14, 0.14))
			if i < int(stats[a]):
				draw_rect(pip, EMBER if i < 4 else EMBER_HOT)
		y += 16


## Draws wrapped text; returns the y below it.
func _para(at: Vector2, t: String, w: float, col: Color, sz: int) -> float:
	var line := ""
	var y := at.y
	for word in t.split(" "):
		var trial := word if line == "" else line + " " + word
		if line != "" and BODY_FONT.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > w:
			_text(BODY_FONT, Vector2(at.x, y), line, sz, col)
			y += sz + 3
			line = word
		else:
			line = trial
	if line != "":
		_text(BODY_FONT, Vector2(at.x, y), line, sz, col)
		y += sz + 3
	return y


func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 28:
		pts.append(c + Vector2(cos(TAU * i / 28.0) * rx, sin(TAU * i / 28.0) * ry))
	draw_colored_polygon(pts, col)


func _text(font: Font, at: Vector2, t: String, sz: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0) -> void:
	draw_string(font, at + Vector2(1, 1), t, align, w, sz, Color(0, 0, 0, 0.85 * col.a))
	draw_string(font, at, t, align, w, sz, col)
