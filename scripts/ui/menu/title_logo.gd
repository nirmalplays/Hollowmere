class_name TitleLogo
extends Control
## The HOLLOWMERE logotype: ash-white relic capitals where the first O is a hanging
## lantern, a thin rule, and the tagline. `play_intro()` lights the lantern in the dark
## (`impact` fires as it catches), then the letters kindle one by one, ember-hot, and
## cool to ash; `finished` fires when settled. Embers drift up from the flame.

signal impact
signal finished

const LEFT: String = "H"
const RIGHT: String = "LLOWMERE"
const TAGLINE: String = "WHAT WILL NOT STAY BURIED"
const FONT_SIZE: int = 44
const ASH := Color(0.91, 0.88, 0.82)
const INK := Color(0.07, 0.05, 0.06)
const EMBER := Color(1.0, 0.62, 0.25)
const RELIC_FONT: Font = preload("res://assets/fonts/Cinzel.ttf")
const SUB_FONT: Font = preload("res://assets/fonts/Alegreya.ttf")
const T_LIGHT: float = 0.6
const T_LETTERS: float = 1.2
const LETTER_GAP: float = 0.09
const T_DONE: float = 3.0

var _t: float = -1.0
var _font: FontVariation
var _embers: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _impacted: bool = false
var _flame: float = 1.0  ## 0..1 lantern brightness


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = FontVariation.new()
	_font.base_font = RELIC_FONT
	_font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 800}
	size = Vector2(_text_width() + 20, 110)
	custom_minimum_size = size


func play_intro() -> void:
	_t = 0.0
	_impacted = false
	_flame = 0.0


func skip() -> void:
	if _t >= 0.0:
		_t = T_DONE


func is_playing() -> bool:
	return _t >= 0.0


func _process(delta: float) -> void:
	if _t >= 0.0:
		_t += delta
		_flame = clampf((_t - T_LIGHT * 0.5) / (T_LIGHT * 0.5), 0.0, 1.0)
		if _t >= T_LIGHT and not _impacted:
			_impacted = true
			impact.emit()
		if _t >= T_DONE:
			_t = -1.0
			_flame = 1.0
			finished.emit()
	if _flame > 0.5 and _rng.randf() < delta * 5.0:
		var at := _lantern_pos() + Vector2(0, -6)
		_embers.append({"p": at, "v": Vector2(_rng.randf_range(-4, 4), -_rng.randf_range(10, 18)), "life": _rng.randf_range(1.0, 2.0)})
	for e in _embers:
		e["p"] += e["v"] * delta
		e["life"] -= delta
	_embers = _embers.filter(func(e: Dictionary) -> bool: return e["life"] > 0.0)
	queue_redraw()


func _draw() -> void:
	var x := 0.0
	var base := 64.0
	x = _draw_word(LEFT, x, base, 0)
	var lantern_w := FONT_SIZE * 0.62
	_draw_lantern(Vector2(x + lantern_w * 0.5, base - FONT_SIZE * 0.36))
	x += lantern_w + 4
	_draw_word(RIGHT, x, base, LEFT.length())
	var settled := 1.0 if _t < 0.0 else clampf((_t - T_LETTERS - LETTER_GAP * 9) / 0.6, 0.0, 1.0)
	if settled > 0.0:
		var w := _text_width()
		draw_line(Vector2(0, base + 14), Vector2(w * settled, base + 14), Color(ASH, 0.55), 1.0)
		draw_string(SUB_FONT, Vector2(2, base + 34), TAGLINE, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(ASH, 0.75 * settled))
	for e in _embers:
		var a: float = clampf(e["life"], 0.0, 1.0)
		draw_rect(Rect2(e["p"], Vector2(1.5, 1.5)), Color(1.0, 0.65 + 0.3 * a, 0.3, a))


## Letters kindle one at a time: hidden -> ember -> ash.
func _draw_word(word: String, x: float, base: float, index_offset: int) -> float:
	for i in word.length():
		var ch := word[i]
		var col := ASH
		if _t >= 0.0:
			var k := (_t - T_LETTERS - (i + index_offset) * LETTER_GAP) / 0.5
			if k <= 0.0:
				col = Color(0, 0, 0, 0)
			else:
				col = EMBER.lerp(ASH, clampf(k, 0.0, 1.0))
				col.a = clampf(k * 2.0, 0.0, 1.0)
		if col.a > 0.0:
			draw_string_outline(_font, Vector2(x, base + 3), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 7, Color(INK, col.a))
			draw_string(_font, Vector2(x, base), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, col)
		x += _font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	return x


## A small iron lantern hanging from a hook, standing in for the O.
func _draw_lantern(c: Vector2) -> void:
	var iron := Color(0.36, 0.33, 0.35)
	draw_line(c + Vector2(0, -22), c + Vector2(0, -15), iron, 2.0)
	draw_arc(c + Vector2(0, -14), 4, PI, TAU, 8, iron, 2.0)
	var body := Rect2(c + Vector2(-9, -12), Vector2(18, 24))
	var glow := 0.25 + 0.75 * _flame
	var flick := 0.85 + 0.15 * sin(Time.get_ticks_msec() * 0.011) * sin(Time.get_ticks_msec() * 0.007)
	if _flame > 0.0:
		draw_circle(c, 30.0 * flick, Color(1.0, 0.55, 0.2, 0.08 * glow))
		draw_circle(c, 16.0 * flick, Color(1.0, 0.65, 0.3, 0.14 * glow))
	draw_rect(body.grow(2), INK)
	draw_rect(body, Color(0.23, 0.17, 0.12))
	draw_rect(Rect2(body.position + Vector2(3, 3), body.size - Vector2(6, 6)), Color(1.0, 0.72, 0.32).lerp(Color(0.12, 0.08, 0.06), 1.0 - _flame))
	draw_rect(Rect2(c + Vector2(-2, -3) * flick, Vector2(4, 8) * flick), Color(1.0, 0.95, 0.75, _flame))
	for dx in [-9, 7]:
		draw_rect(Rect2(body.position + Vector2(dx + 9, 0), Vector2(2, body.size.y)), iron)
	draw_rect(Rect2(body.position + Vector2(-2, -3), Vector2(body.size.x + 4, 3)), iron)
	draw_rect(Rect2(body.position + Vector2(-2, body.size.y), Vector2(body.size.x + 4, 3)), iron)


func _lantern_pos() -> Vector2:
	var x := _font.get_string_size(LEFT, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	return Vector2(x + FONT_SIZE * 0.31, 64.0 - FONT_SIZE * 0.36)


func _text_width() -> float:
	return _font.get_string_size(LEFT, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x + FONT_SIZE * 0.62 + 4 \
		+ _font.get_string_size(RIGHT, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
