class_name MenuBackdrop
extends Node2D
## The title screen's world, painted as pixel art on a 320x180 canvas and shown at 2x:
## a deep forest, a ruined arch of mossy stone with a rune burning on its keystone,
## shafts of light with dust, a stream, and the Unlaid with a lantern on its bank.
## Fireflies wander, leaves fall, the stream glitters; the layers part as the mouse moves.
## Still layers are painted once (dithered, small palette); only what moves is drawn per frame.

const W: int = 320
const H: int = 180
const M: int = 16  ## extra width per layer for parallax
const SCALE: float = 3.0  ## 320x180 painted canvas shown at 960x540
const BAYER: Array[float] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
const ARCH_CX: int = 168 + M
const HERO_SHEET: Texture2D = preload("res://assets/art/characters/unlaid.png")
const HERO_FRAME: int = 128

## Parallax depth per layer (how far it slides with the mouse).
const DEPTH := {"sky": 0.1, "far": 0.25, "mid": 0.55, "near": 1.0}

var look: Vector2 = Vector2.ZERO  ## -0.5..0.5 each way, from the mouse

var _layers: Dictionary = {}  # name -> Sprite2D
var _rng := RandomNumberGenerator.new()
var _fireflies: Array[Dictionary] = []
var _leaves: Array[Dictionary] = []
var _motes: Array[Dictionary] = []
var _t: float = 0.0
var _hero: Sprite2D
var _fx: Node2D


func _ready() -> void:
	_rng.seed = 11
	scale = Vector2(SCALE, SCALE)
	for layer_name in ["sky", "far", "mid", "near"]:
		var s := Sprite2D.new()
		s.centered = false
		s.texture = ImageTexture.create_from_image(call("_paint_" + layer_name))
		s.position = Vector2(-M, 0)
		add_child(s)
		_layers[layer_name] = s
		if layer_name == "mid":
			_add_hero()
	_fx = Node2D.new()
	_fx.draw.connect(_draw_fx)
	add_child(_fx)
	for i in 26:
		_fireflies.append({"x": _rng.randf_range(0, W), "y": _rng.randf_range(60, 160), "p": _rng.randf() * TAU, "s": _rng.randf_range(0.4, 1.0)})
	for i in 14:
		_leaves.append({"x": _rng.randf_range(0, W), "y": _rng.randf_range(-H, H), "v": _rng.randf_range(8, 16), "p": _rng.randf() * TAU})
	for i in 40:
		_motes.append({"x": _rng.randf_range(110, 230), "y": _rng.randf_range(20, 150), "p": _rng.randf() * TAU})


func _process(delta: float) -> void:
	_t += delta
	var vp := get_viewport_rect().size
	if vp.x > 0.0:
		var mouse := get_viewport().get_mouse_position()
		look = look.lerp(Vector2(mouse.x / vp.x - 0.5, mouse.y / vp.y - 0.5), 1.0 - exp(-3.0 * delta))
	for layer_name in _layers:
		var d: float = DEPTH[layer_name]
		(_layers[layer_name] as Sprite2D).position = Vector2(-M - look.x * M * d * 2.0, -look.y * 4.0 * d)
	_hero.position = Vector2(ARCH_CX + 44 - M - look.x * M * 1.4, 152 - look.y * 4.0 * 0.8)
	_hero.frame_coords.x = int(_t * 2.0) % 2
	for f in _fireflies:
		f["x"] = wrapf(f["x"] + sin(_t * f["s"] + f["p"]) * 6.0 * delta + 3.0 * delta, -4, W + 4)
		f["y"] += cos(_t * 0.7 * f["s"] + f["p"]) * 5.0 * delta
	for l in _leaves:
		l["y"] += l["v"] * delta
		l["x"] += sin(_t + l["p"]) * 10.0 * delta
		if l["y"] > H + 4:
			l["y"] = -4
			l["x"] = _rng.randf_range(0, W)
	for m in _motes:
		m["y"] -= 2.0 * delta
		if m["y"] < 20:
			m["y"] = 150
	_fx.queue_redraw()


# ---------------------------------------------------------------- moving bits

func _draw_fx() -> void:
	var off := Vector2(-look.x * M * 1.2, 0)
	# Light shafts falling through the canopy onto the arch.
	for i in 3:
		var x0 := 120.0 + i * 34.0 + off.x * 0.6
		var a := 0.06 + 0.03 * sin(_t * 0.6 + i)
		_fx.draw_colored_polygon(PackedVector2Array([Vector2(x0, 0), Vector2(x0 + 14, 0), Vector2(x0 + 44, 150), Vector2(x0 + 22, 150)]), Color(1.0, 0.95, 0.75, a))
	for m in _motes:
		var tw := 0.5 + 0.5 * sin(_t * 2.0 + m["p"])
		_fx.draw_rect(Rect2(m["x"] + off.x * 0.6, m["y"], 1, 1), Color(1, 0.95, 0.8, 0.5 * tw))
	# The rune on the keystone and the light waiting inside the arch.
	var pulse := 0.6 + 0.4 * sin(_t * 1.7)
	var rune := Vector2(ARCH_CX - M + off.x * 0.55, 66)
	_fx.draw_circle(rune, 6.0, Color(0.5, 0.85, 1.0, 0.18 * pulse))
	_fx.draw_rect(Rect2(rune - Vector2(1, 3), Vector2(3, 7)), Color(0.75, 0.95, 1.0, 0.8 * pulse))
	_fx.draw_rect(Rect2(rune - Vector2(3, 1), Vector2(7, 3)), Color(0.75, 0.95, 1.0, 0.6 * pulse))
	_fx.draw_circle(Vector2(ARCH_CX - M + off.x * 0.55, 116), 16.0, Color(0.45, 0.8, 1.0, 0.07 * pulse))
	# The lantern's glow at the wanderer's side.
	var lantern := _hero.position + Vector2(9, -14)
	_fx.draw_circle(lantern, 18.0, Color(1.0, 0.7, 0.35, 0.08 + 0.02 * sin(_t * 9.0)))
	_fx.draw_circle(lantern, 6.0, Color(1.0, 0.8, 0.45, 0.2))
	_fx.draw_rect(Rect2(lantern - Vector2(1, 1), Vector2(2, 3)), Color(1.0, 0.9, 0.55))
	# Stream glitter.
	for i in 18:
		var gx := fmod(i * 23.0 + _t * 9.0 * (1 + i % 3), W + 20.0) - 10.0 + off.x
		var gy := 160.0 + (i * 7) % 12
		if sin(_t * 3.0 + i) > 0.4:
			_fx.draw_rect(Rect2(gx, gy, 2 + i % 2, 1), Color(0.75, 0.95, 1.0, 0.7))
	for f in _fireflies:
		var glow := 0.5 + 0.5 * sin(_t * 3.0 * f["s"] + f["p"])
		var p := Vector2(f["x"], f["y"]) + off * 0.8
		_fx.draw_circle(p, 2.5, Color(0.85, 1.0, 0.5, 0.12 * glow))
		_fx.draw_rect(Rect2(p, Vector2(1, 1)), Color(0.9, 1.0, 0.6, glow))
	for l in _leaves:
		var c := Color(0.75, 0.55, 0.2) if int(l["p"] * 10) % 2 == 0 else Color(0.55, 0.65, 0.25)
		_fx.draw_rect(Rect2(l["x"] + off.x, l["y"], 2, 1), c)


func _add_hero() -> void:
	_hero = Sprite2D.new()
	_hero.texture = HERO_SHEET
	_hero.hframes = HERO_SHEET.get_width() / HERO_FRAME
	_hero.vframes = HERO_SHEET.get_height() / HERO_FRAME
	_hero.frame_coords = Vector2i(0, 4)  # idle facing away (n): looking toward the arch
	_hero.centered = true
	_hero.offset = Vector2(0, -30)  # feet sit 30 px below the 128 px frame's centre
	_hero.scale = Vector2(0.5, 0.5)  # a small figure against the ruin, like the reference
	add_child(_hero)


# ---------------------------------------------------------------- painting

func _img() -> Image:
	return Image.create(W + M * 2, H, false, Image.FORMAT_RGBA8)


func _mix(img: Image, x: int, y: int, a: Color, b: Color, k: float) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, b if k > (BAYER[(y % 4) * 4 + (x % 4)] + 0.5) / 16.0 else a)


func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in h:
		for xx in w:
			_px(img, x + xx, y + yy, c)


func _disc(img: Image, cx: int, cy: int, r: int, c: Color, top: Color) -> void:
	for y in range(-r, r + 1):
		for x in range(-r, r + 1):
			if x * x + y * y <= r * r + r * 0.6:
				_px(img, cx + x, cy + y, top if y < -r * 0.35 and (x + y) % 2 == 0 else c)


func _paint_sky() -> Image:
	var img := _img()
	var stops: Array[Color] = [Color("050f0c"), Color("0a1d17"), Color("10302a"), Color("1b4a3a"), Color("2a6a52")]
	for y in H:
		var t := minf(0.999, pow(y / 128.0, 1.3)) * (stops.size() - 1)
		var n := int(t)
		for x in img.get_width():
			_mix(img, x, y, stops[n], stops[mini(n + 1, stops.size() - 1)], t - n)
	return img


func _paint_far() -> Image:
	var img := _img()
	var trunk := Color("0f2a22")
	var trunk_lit := Color("17382d")
	for n in 26:
		var x := _rng.randi_range(0, img.get_width())
		var w := _rng.randi_range(2, 6)
		_rect(img, x, 0, w, 150, trunk)
		_rect(img, x + w - 1, 0, 1, 150, trunk_lit)
	for n in 22:
		_disc(img, _rng.randi_range(0, img.get_width()), _rng.randi_range(-4, 22), _rng.randi_range(10, 24), Color("0b2219"), Color("123329"))
	var haze := Color("2a6a52")
	for y in range(86, 132):
		for x in img.get_width():
			if (BAYER[(y % 4) * 4 + (x % 4)] + 0.5) / 16.0 < 0.18 * sin((y - 86) / 46.0 * PI):
				_px(img, x, y, haze)
	return img


func _paint_mid() -> Image:
	var img := _img()
	var st: Array[Color] = [Color("3d4a3e"), Color("56655a"), Color("6f8070"), Color("8c9c88")]
	var dark := Color("1a2219")
	var moss: Array[Color] = [Color("2f5a24"), Color("4a7f2e"), Color("74a63a")]
	var cx := ARCH_CX
	# The doorway's darkness.
	for y in range(72, 140):
		for x in range(cx - 18, cx + 19):
			if y > 90 or pow(x - cx, 2) + pow(y - 90, 2) <= 18 * 18:
				_px(img, x, y, Color("0a120f"))
	# Pillars laid in blocks.
	for px0 in [cx - 32, cx + 19]:
		for y in range(88, 140):
			var row := (y - 88) / 7
			for x in range(px0, px0 + 13):
				var edge: bool = (y - 88) % 7 == 0 or (x - px0 + (row % 2) * 6) % 13 == 0
				_px(img, x, y, st[0] if edge else (st[3] if x == px0 else (st[1] if x > px0 + 9 else st[2])))
			_px(img, px0 - 1, y, dark)
			_px(img, px0 + 13, y, dark)
	# The arch: a ring of stones, one missing on the right.
	for y in range(60, 96):
		for x in range(cx - 34, cx + 35):
			var d := Vector2(x - cx, y - 92).length()
			if d >= 22 and d <= 34 and y <= 92:
				var ang := atan2(y - 92, x - cx)
				if ang > -0.55 and ang < -0.25:
					continue  # the fallen stone
				var block := int((ang + PI) * 7.0) % 2 == 0
				_px(img, x, y, dark if absf(d - 22) < 1 or absf(d - 34) < 1 else (st[2] if block else st[1]))
	# Moss on the stones, rubble and ground at their feet.
	for n in 70:
		var x := _rng.randi_range(cx - 36, cx + 34)
		var y := _rng.randi_range(62, 138)
		if img.get_pixel(x, y).a > 0.0 and img.get_pixel(x, y) != Color("0a120f"):
			_px(img, x, y, moss[_rng.randi_range(0, 2)])
	for n in 9:
		_disc(img, cx + _rng.randi_range(-50, 50), _rng.randi_range(138, 144), _rng.randi_range(2, 4), st[1], st[3])
	for y in range(140, 156):
		for x in img.get_width():
			_mix(img, x, y, Color("1e3b22"), Color("2c5a2c"), 0.5 + 0.3 * sin(x * 0.2 + y))
	return img


func _paint_near() -> Image:
	var img := _img()
	# The stream across the foreground, with a dark bank.
	for y in range(154, 172):
		for x in img.get_width():
			var k := (y - 154) / 18.0
			_mix(img, x, y, Color("0e2f3a"), Color("1f5a6a"), 0.7 - k * 0.6 + 0.15 * sin(x * 0.3))
	for x in img.get_width():
		_px(img, x, 154, Color("2c5a2c"))
		_px(img, x, 155, Color("1a3a20"))
	for y in range(172, H):
		for x in img.get_width():
			_mix(img, x, y, Color("0b1a10"), Color("15301a"), 0.4)
	# Foreground trees framing the scene, darkest and closest.
	for side in [0, 1]:
		var base_x := 12 if side == 0 else img.get_width() - 30
		_rect(img, base_x, 0, 16, 180, Color("0a1510"))
		_rect(img, base_x + (13 if side == 0 else 0), 0, 3, 180, Color("142a1e"))
		for n in 9:
			_disc(img, base_x + _rng.randi_range(-24, 36), _rng.randi_range(-6, 40), _rng.randi_range(10, 18), Color("08130c"), Color("0f2418"))
	# Grass tufts along the bank.
	for n in 120:
		var x := _rng.randi_range(0, img.get_width())
		var hgt := _rng.randi_range(2, 6)
		for y in hgt:
			_px(img, x, 153 - y, Color("3d7a34") if y < hgt - 1 else Color("74a63a"))
	return img
