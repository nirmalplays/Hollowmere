class_name TitleLogo
extends Control
## The HOLLOWMERE title: banded gold letters with a dark outline and drop shadow,
## a relic sword behind them, a gold rule with a gem, embers drifting up.
## `play_intro()` forges it in front of you: darkness and embers, the sword falls and
## strikes (white flash, shockwave, shake: `impact` fires), the letters burn in from the
## centre white-hot and cool to gold, the rule draws out; `finished` fires when settled.

signal impact
signal finished

const TEXT: String = "HOLLOWMERE"
const SUBTITLE: String = "A TALE OF THE UNLAID"
const FONT_SIZE: int = 32
const INK := Color(0.106, 0.059, 0.031)
const GOLD := Color(1.0, 0.84, 0.42)
const T_FALL: float = 0.45
const T_IMPACT: float = 0.8
const T_REVEAL: float = 1.6
const T_COOL: float = 2.6
const T_DONE: float = 3.1
const GOLD_SHADER: Shader = preload("res://assets/shaders/gold_text.gdshader")

var _t: float = -1.0  ## intro clock; -1 = not playing (settled)
var _ink: Label
var _gold: Label
var _sub: Label
var _sword: TextureRect
var _rule_k: float = 1.0
var _flash: float = 0.0
var _wave: float = -1.0
var _embers: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _impacted: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(340, 110)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sword = TextureRect.new()
	_sword.texture = ImageTexture.create_from_image(_paint_sword())
	_sword.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sword.scale = Vector2(2, 2)
	_sword.position = Vector2(size.x / 2 - 9, 2)
	add_child(_sword)
	_ink = _make_label(true)
	_gold = _make_label(false)
	_sub = Label.new()
	_sub.text = SUBTITLE
	_sub.add_theme_color_override(&"font_color", Color(0.95, 0.89, 0.75))
	_sub.add_theme_color_override(&"font_shadow_color", Color.BLACK)
	_sub.add_theme_constant_override(&"shadow_offset_y", 1)
	_sub.add_theme_font_size_override(&"font_size", 8)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.size = Vector2(size.x, 10)
	_sub.position = Vector2(0, 92)
	add_child(_sub)
	for i in 30:
		_embers.append(_new_ember(true))


func play_intro() -> void:
	_t = 0.0
	_impacted = false
	_rule_k = 0.0
	_set_heat(1.0)
	_ink.modulate.a = 0.0
	_gold.modulate.a = 0.0
	_sub.modulate.a = 0.0
	_sword.position.y = -120


func skip() -> void:
	if _t >= 0.0:
		_t = T_DONE


func is_playing() -> bool:
	return _t >= 0.0


func _process(delta: float) -> void:
	for e in _embers:
		e["y"] -= e["v"] * delta
		e["x"] += sin(e["y"] * 0.05 + e["p"]) * 6.0 * delta
		e["life"] -= delta
		if e["life"] <= 0.0:
			e.merge(_new_ember(false), true)
	_flash = maxf(0.0, _flash - delta * 3.0)
	if _wave >= 0.0:
		_wave += delta
		if _wave > 0.6:
			_wave = -1.0
	if _t >= 0.0:
		_t += delta
		_run_intro()
	queue_redraw()


func _run_intro() -> void:
	var ease := func(k: float) -> float: return 1.0 - pow(1.0 - clampf(k, 0.0, 1.0), 3.0)
	if _t < T_IMPACT:
		var k := clampf((_t - T_FALL) / (T_IMPACT - T_FALL), 0.0, 1.0)
		_sword.position.y = lerpf(-120.0, 2.0, k * k)
	else:
		_sword.position.y = 2.0
		if not _impacted:
			_impacted = true
			_flash = 1.0
			_wave = 0.0
			for i in 24:
				var e := _new_ember(false)
				e["x"] = size.x / 2 + _rng.randf_range(-20, 20)
				e["y"] = 60
				e["v"] = _rng.randf_range(30, 90)
				_embers.append(e)
			impact.emit()
	var reveal: float = ease.call((_t - T_IMPACT) / (T_REVEAL - T_IMPACT))
	_ink.modulate.a = reveal
	_gold.modulate.a = reveal
	_set_heat(1.0 - clampf((_t - T_REVEAL) / (T_COOL - T_REVEAL), 0.0, 1.0))
	_rule_k = ease.call((_t - T_REVEAL) / (T_COOL - T_REVEAL))
	_sub.modulate.a = clampf((_t - T_COOL) / 0.4, 0.0, 1.0)
	if _t >= T_DONE:
		_t = -1.0
		_set_heat(0.0)
		_rule_k = 1.0
		_ink.modulate.a = 1.0
		_gold.modulate.a = 1.0
		_sub.modulate.a = 1.0
		finished.emit()


func _draw() -> void:
	# The rule beneath, with a gem at its centre.
	var cx := size.x / 2
	var half := 130.0 * _rule_k
	if half > 1.0:
		draw_rect(Rect2(cx - half, 86, half * 2, 2), GOLD)
		draw_rect(Rect2(cx - half, 88, half * 2, 1), Color(0.66, 0.38, 0.1))
		draw_colored_polygon(PackedVector2Array([Vector2(cx, 82), Vector2(cx + 5, 87), Vector2(cx, 92), Vector2(cx - 5, 87)]), Color(0.55, 0.85, 1.0))
	for e in _embers:
		var a: float = clampf(e["life"], 0.0, 1.0)
		draw_rect(Rect2(e["x"], e["y"], 1, 1), Color(1.0, 0.7 + 0.3 * a, 0.3, a))
	if _wave >= 0.0:
		draw_arc(Vector2(cx, 60), 10.0 + _wave * 220.0, 0, TAU, 48, Color(1, 0.95, 0.8, 0.6 * (1.0 - _wave / 0.6)), 2.0)
	if _flash > 0.0:
		draw_rect(Rect2(-400, -300, 1200, 800), Color(1, 1, 1, _flash * 0.85))


func _make_label(ink: bool) -> Label:
	var l := Label.new()
	l.text = TEXT
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(size.x, 44)
	l.position = Vector2(0, 38)
	l.add_theme_font_size_override(&"font_size", FONT_SIZE)
	if ink:
		l.add_theme_color_override(&"font_color", INK)
		l.add_theme_color_override(&"font_outline_color", INK)
		l.add_theme_constant_override(&"outline_size", 8)
		l.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.9))
		l.add_theme_constant_override(&"shadow_offset_y", 4)
	else:
		var mat := ShaderMaterial.new()
		mat.shader = GOLD_SHADER
		mat.set_shader_parameter(&"text_top", 6.0)
		mat.set_shader_parameter(&"text_height", float(FONT_SIZE))
		l.material = mat
	add_child(l)
	return l


func _set_heat(v: float) -> void:
	(_gold.material as ShaderMaterial).set_shader_parameter(&"heat", v)


func _new_ember(anywhere: bool) -> Dictionary:
	return {
		"x": _rng.randf_range(20, size.x - 20), "y": _rng.randf_range(10, 100) if anywhere else 100.0,
		"v": _rng.randf_range(6, 18), "p": _rng.randf() * TAU, "life": _rng.randf_range(1.5, 4.0),
	}


func _paint_sword() -> Image:
	var img := Image.create(18, 50, false, Image.FORMAT_RGBA8)
	var steel := [Color("e8eef4"), Color("b9c3cf"), Color("7d8796")]
	for y in range(0, 34):  # blade, pointed tip at the bottom (it falls point-first)
		var w := 2 if y < 30 else (1 if y < 32 else 0)
		for x in range(9 - w, 10 + w):
			img.set_pixel(x, 33 - y + 12 - 12, steel[0] if x < 9 else (steel[1] if x == 9 else steel[2]))
	for x in range(2, 16):  # guard
		img.set_pixel(x, 0 + 34 - 34 + 0, Color("d9a441"))
	for y in range(34, 36):
		for x in range(2, 16):
			img.set_pixel(x, y, Color("d9a441") if y == 34 else Color("8a5a1a"))
	for y in range(36, 44):  # grip
		for x in range(8, 11):
			img.set_pixel(x, y, Color("5e3b29") if (y + x) % 2 == 0 else Color("3c2416"))
	for y in range(44, 48):  # pommel
		for x in range(7, 12):
			img.set_pixel(x, y, Color("ffd66b") if y == 44 else Color("d9a441"))
	img.flip_y()  # hilt up, point down
	return img
