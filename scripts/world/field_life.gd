class_name FieldLife
extends Node2D
## The things that keep an outdoor area from standing still: leaves coming down on the
## wind, fireflies that drift and pulse, slow shafts of light, and gusts that pass over
## everything. Lives on the FX layer (outside the dark tint) and follows the camera, so
## it costs the same however large the area is.

const LEAVES: int = 46
const FLIES: int = 26
const LEAF_COLORS: Array[Color] = [Color(0.55, 0.72, 0.3), Color(0.78, 0.6, 0.22), Color(0.7, 0.38, 0.18), Color(0.42, 0.6, 0.28)]
const VIEW := Vector2(960, 540)
const MARGIN: float = 60.0

var _leaves: Array[Dictionary] = []
var _flies: Array[Dictionary] = []
var _t: float = 0.0
var _gust: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	z_index = 50
	_rng.randomize()
	for i in LEAVES:
		_leaves.append(_new_leaf(true))
	for i in FLIES:
		_flies.append({"p": Vector2(_rng.randf_range(0, VIEW.x), _rng.randf_range(0, VIEW.y)), "ph": _rng.randf() * TAU,
			"sp": _rng.randf_range(0.5, 1.3), "r": _rng.randf_range(10, 34)})


func _new_leaf(anywhere: bool) -> Dictionary:
	return {"p": Vector2(_rng.randf_range(-MARGIN, VIEW.x + MARGIN), _rng.randf_range(-MARGIN, VIEW.y) if anywhere else -MARGIN),
		"v": _rng.randf_range(14, 30), "ph": _rng.randf() * TAU, "c": LEAF_COLORS[_rng.randi() % LEAF_COLORS.size()],
		"w": _rng.randf_range(1.5, 3.0)}


func _process(delta: float) -> void:
	_t += delta
	# A gust every so often: everything in the air leans with it.
	_gust = maxf(0.0, sin(_t * 0.23) * sin(_t * 0.071 + 1.0)) * 46.0
	for leaf in _leaves:
		var flutter: float = sin(_t * 2.6 + leaf["ph"])
		leaf["p"] += Vector2(-(12.0 + _gust) + flutter * 14.0, leaf["v"] * (0.7 + 0.3 * absf(flutter))) * delta
		if leaf["p"].y > VIEW.y + MARGIN or leaf["p"].x < -MARGIN:
			var fresh := _new_leaf(false)
			fresh["p"].x += MARGIN * 2.0
			leaf.merge(fresh, true)
	for fly in _flies:
		fly["ph"] += delta * fly["sp"]
	queue_redraw()


func _draw() -> void:
	# Screen space: undo the camera so the layer's contents stay put on screen.
	var cam := get_viewport().get_camera_2d()
	var origin := cam.get_screen_center_position() - VIEW * 0.5 if cam else Vector2.ZERO
	# Shafts of low light, slanting, breathing.
	for i in 4:
		var x: float = fposmod(i * 290.0 + 80.0 - origin.x * 0.35, VIEW.x + 300.0) - 150.0
		var a: float = 0.028 + 0.022 * sin(_t * 0.4 + i * 1.7)
		var pts := PackedVector2Array([origin + Vector2(x, -20), origin + Vector2(x + 70, -20), origin + Vector2(x - 110, VIEW.y + 20), origin + Vector2(x - 220, VIEW.y + 20)])
		draw_colored_polygon(pts, Color(1.0, 0.9, 0.62, a))
	for leaf in _leaves:
		# Leaves live in world space wrapped to the screen, so walking moves through them.
		var p: Vector2 = Vector2(fposmod(leaf["p"].x - origin.x * 0.6, VIEW.x + MARGIN * 2.0) - MARGIN, fposmod(leaf["p"].y - origin.y * 0.6, VIEW.y + MARGIN * 2.0) - MARGIN)
		var turn: float = sin(_t * 2.6 + leaf["ph"])
		draw_rect(Rect2(origin + p, Vector2(leaf["w"] * (0.4 + 0.6 * absf(turn)), 2.0)), Color(leaf["c"], 0.85))
	for fly in _flies:
		var drift: Vector2 = Vector2(cos(fly["ph"] * 1.3), sin(fly["ph"] * 0.9)) * fly["r"]
		var p: Vector2 = Vector2(fposmod(fly["p"].x - origin.x, VIEW.x), fposmod(fly["p"].y - origin.y, VIEW.y)) + drift
		var glow: float = 0.5 + 0.5 * sin(fly["ph"] * 3.0)
		draw_circle(origin + p, 5.0, Color(0.85, 1.0, 0.55, 0.07 * glow))
		draw_rect(Rect2(origin + p, Vector2(1.5, 1.5)), Color(0.92, 1.0, 0.6, 0.35 + 0.6 * glow))
