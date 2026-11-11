class_name MenuBackdrop
extends Node2D
## Title screen scene: the Ashen Reach at dusk, painted as pixel art on a 320x180
## canvas shown at 3x. The Unlaid sits on a rock with his back to us, lantern at his
## side, looking across a grey valley of dead trees toward a faint blue light on the
## horizon (the Sunken Lantern, where the story ends). A ruined shrine tower stands on
## the hill. Ash drifts down, embers rise from the lantern, the far light breathes,
## clouds crawl; layers part slightly with the mouse.

const W: int = 320
const H: int = 180
const M: int = 16  ## extra width per layer for parallax
const SCALE: float = 3.0
const BAYER: Array[float] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
const HERO_SHEET: Texture2D = preload("res://assets/art/characters/unlaid.png")
const HERO_FRAME: int = 128
const HORIZON: int = 112
const FAR_LIGHT := Vector2(214, 104)  ## the Sunken Lantern on the horizon
const HERO_AT := Vector2(238, 160)
const DEPTH := {"sky": 0.08, "far": 0.25, "mid": 0.55, "near": 1.0}

var look: Vector2 = Vector2.ZERO

var _layers: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _ash: Array[Dictionary] = []
var _embers: Array[Dictionary] = []
var _t: float = 0.0
var _hero: Sprite2D
var _fx: Node2D
var _clouds: Sprite2D


func _ready() -> void:
	_rng.seed = 23
	scale = Vector2(SCALE, SCALE)
	for layer_name in ["sky", "far", "mid"]:
		_add_layer(layer_name)
	_clouds = Sprite2D.new()
	_clouds.centered = false
	_clouds.texture = ImageTexture.create_from_image(_paint_clouds())
	_clouds.modulate.a = 0.5
	add_child(_clouds)
	move_child(_clouds, 1)
	_add_hero()
	_add_layer("near")
	_fx = Node2D.new()
	_fx.draw.connect(_draw_fx)
	add_child(_fx)
	for i in 70:
		_ash.append({"x": _rng.randf_range(-20, W + 20), "y": _rng.randf_range(0, H), "v": _rng.randf_range(4, 11), "p": _rng.randf() * TAU, "s": _rng.randi_range(1, 2)})


func _add_layer(layer_name: String) -> void:
	var s := Sprite2D.new()
	s.centered = false
	s.texture = ImageTexture.create_from_image(call("_paint_" + layer_name))
	s.position = Vector2(-M, 0)
	add_child(s)
	_layers[layer_name] = s


func _process(delta: float) -> void:
	_t += delta
	var vp := get_viewport_rect().size
	if vp.x > 0.0:
		var mouse := get_viewport().get_mouse_position()
		look = look.lerp(Vector2(mouse.x / vp.x - 0.5, mouse.y / vp.y - 0.5), 1.0 - exp(-2.5 * delta))
	for layer_name in _layers:
		var d: float = DEPTH[layer_name]
		(_layers[layer_name] as Sprite2D).position = Vector2(-M - look.x * M * d * 2.0, -look.y * 3.0 * d)
	_clouds.position.x = fmod(-_t * 1.5, W) - look.x * M * 0.3
	_hero.position = HERO_AT + Vector2(-look.x * M * 1.6, -look.y * 3.0)
	for a in _ash:
		a["y"] += a["v"] * delta
		a["x"] += (sin(_t * 0.8 + a["p"]) * 4.0 - 3.0) * delta
		if a["y"] > H + 2:
			a["y"] = -2
			a["x"] = _rng.randf_range(-10, W + 20)
	if _rng.randf() < delta * 6.0:
		_embers.append({"x": _hero.position.x + 9, "y": _hero.position.y - 12, "vx": _rng.randf_range(-3, 3), "life": _rng.randf_range(1.2, 2.4)})
	for e in _embers:
		e["y"] -= 9.0 * delta
		e["x"] += (e["vx"] + sin(_t * 3.0 + e["life"]) * 2.0) * delta
		e["life"] -= delta
	_embers = _embers.filter(func(e: Dictionary) -> bool: return e["life"] > 0.0)
	_fx.queue_redraw()


func _draw_fx() -> void:
	var off := Vector2(-look.x * M, 0)
	# The far light breathes: a cold glow on the horizon.
	var pulse := 0.55 + 0.45 * sin(_t * 0.9)
	var fl := FAR_LIGHT + off * 0.25
	for r in [16.0, 10.0, 5.0]:
		_fx.draw_circle(fl, r, Color(0.45, 0.72, 1.0, 0.05 * pulse * (20.0 / r)))
	_fx.draw_rect(Rect2(fl - Vector2(0, 2), Vector2(1, 3)), Color(0.8, 0.92, 1.0, 0.9 * pulse))
	_fx.draw_line(fl + Vector2(0, -2), fl + Vector2(0, -40), Color(0.6, 0.8, 1.0, 0.06 * pulse), 1.0)
	# Lantern glow at the wanderer's side.
	var lantern := _hero.position + Vector2(9, -10)
	var flick := 0.9 + 0.1 * sin(_t * 11.0) * sin(_t * 7.3)
	_fx.draw_circle(lantern, 26.0 * flick, Color(1.0, 0.62, 0.28, 0.06))
	_fx.draw_circle(lantern, 12.0 * flick, Color(1.0, 0.7, 0.35, 0.12))
	_fx.draw_rect(Rect2(lantern - Vector2(1, 2), Vector2(3, 4)), Color(1.0, 0.86, 0.5))
	for e in _embers:
		var a: float = clampf(e["life"], 0.0, 1.0)
		_fx.draw_rect(Rect2(e["x"], e["y"], 1, 1), Color(1.0, 0.6 + 0.3 * a, 0.25, a))
	for a in _ash:
		_fx.draw_rect(Rect2(a["x"] + off.x * 0.4, a["y"], a["s"], 1), Color(0.78, 0.76, 0.74, 0.55))


func _add_hero() -> void:
	_hero = Sprite2D.new()
	_hero.texture = HERO_SHEET
	_hero.hframes = HERO_SHEET.get_width() / HERO_FRAME
	_hero.vframes = HERO_SHEET.get_height() / HERO_FRAME
	_hero.frame_coords = Vector2i(0, 4)  # idle, facing away: watching the far light
	_hero.offset = Vector2(0, -30)
	_hero.scale = Vector2(0.5, 0.5)
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


func _ridge(img: Image, base: float, amp: float, freq: float, seed_off: float, c: Color, top: Color) -> void:
	for x in img.get_width():
		var h := base - amp * (0.6 * sin(x * freq + seed_off) + 0.4 * sin(x * freq * 2.7 + seed_off * 1.7))
		for y in range(int(h), H):
			_px(img, x, y, top if y == int(h) else c)


func _paint_sky() -> Image:
	var img := _img()
	# Dusk: violet at the top, a sick amber band low down where the ash catches the sun.
	var stops: Array[Color] = [Color("120d1c"), Color("231629"), Color("3d2131"), Color("6a3330"), Color("a3532c"), Color("c98a4a")]
	for y in H:
		var t := minf(0.999, pow(float(y) / HORIZON, 1.6)) * (stops.size() - 1)
		var n := int(t)
		for x in img.get_width():
			_mix(img, x, y, stops[n], stops[mini(n + 1, stops.size() - 1)], t - n)
	# A pale, ash-veiled sun low on the left.
	for y in range(40, 80):
		for x in range(50, 110):
			var d := Vector2(x - 80, y - 66).length()
			if d < 9:
				_px(img, x, y, Color("d9a46c") if d > 7.5 else Color("e7b77a"))
			elif d < 20:
				_mix(img, x, y, img.get_pixel(x, y), Color("b8703e"), 0.45 * (1.0 - (d - 9.0) / 11.0))
	return img


func _paint_clouds() -> Image:
	var img := Image.create(W * 2, H, false, Image.FORMAT_RGBA8)
	for n in 26:
		var cx := _rng.randi_range(0, W * 2)
		var cy := _rng.randi_range(18, 70)
		var w := _rng.randi_range(30, 70)
		for y in range(-6, 7):
			for x in range(-w / 2, w / 2):
				if (x * x) / float(w * w / 4) + (y * y) / 36.0 < 1.0:
					_mix(img, (cx + x) % (W * 2), cy + y, Color(0, 0, 0, 0), Color("4a2a33"), 0.55)
	return img


func _paint_far() -> Image:
	var img := _img()
	_ridge(img, 100, 10, 0.035, 1.0, Color("3a2533"), Color("553241"))
	_ridge(img, 108, 6, 0.06, 4.0, Color("2d1e2a"), Color("432a36"))
	# Ash haze sitting in the valley.
	for y in range(96, 120):
		for x in img.get_width():
			if (BAYER[(y % 4) * 4 + (x % 4)] + 0.5) / 16.0 < 0.22 * sin((y - 96) / 24.0 * PI):
				_px(img, x, y, Color("7d5a55"))
	return img


func _paint_mid() -> Image:
	var img := _img()
	_ridge(img, 126, 8, 0.02, 2.0, Color("1d1520"), Color("2b1f2a"))
	# Dead trees across the valley floor: grey, branching, leafless.
	for n in 22:
		var x := _rng.randi_range(0, img.get_width())
		var base := 128 + _rng.randi_range(-4, 6)
		var h := _rng.randi_range(14, 34)
		_dead_tree(img, x, base, h, Color("2a2027"))
	# The ruined shrine tower on the hill to the left: the Underroot lies beneath it.
	var tx := 70 + M
	for y in range(92, 128):
		for x in range(tx - 6, tx + 7):
			var broken := y < 98 and (x > tx + 2 or (x + y) % 3 == 0)
			if not broken:
				_px(img, x, y, Color("221a22") if x < tx + 4 else Color("2e232b"))
	for y in range(100, 112):  # an empty arched window
		for x in range(tx - 2, tx + 3):
			if y > 102 or absi(x - tx) < 2:
				_px(img, x, y, Color("6a3330"))
	return img


func _paint_near() -> Image:
	var img := _img()
	# The rock the wanderer sits on, and the dark hillside in front of us.
	_ridge(img, 160, 6, 0.05, 7.0, Color("0d0a0f"), Color("1a1418"))
	var rx := int(HERO_AT.x) + M
	for y in range(156, 172):
		for x in range(rx - 16, rx + 18):
			if pow((x - rx) / 17.0, 2) + pow((y - 166) / 9.0, 2) < 1.0:
				_px(img, x, y, Color("1f1a20") if y > 160 else Color("2c262c"))
	for n in 140:
		var x := _rng.randi_range(0, img.get_width())
		var h := _rng.randi_range(2, 7)
		for y in h:
			_px(img, x, 162 - y + _rng.randi_range(0, 1), Color("17121a") if y < h - 1 else Color("3a2d33"))
	# A dead branch reaching in from the right edge.
	_dead_tree(img, img.get_width() - 8, 178, 120, Color("0b080c"))
	return img


func _dead_tree(img: Image, x: int, base: int, h: int, c: Color) -> void:
	for y in h:
		var w := 1 if y > h * 0.5 else 2
		for i in w:
			_px(img, x + i, base - y, c)
	for b in 4:
		var by := base - int(h * (0.4 + 0.15 * b))
		var dir := -1 if b % 2 == 0 else 1
		for i in int(h * 0.25):
			_px(img, x + dir * i, by - i / 2, c)
