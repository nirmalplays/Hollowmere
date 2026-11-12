class_name SlashArc
extends Node2D
## The streak a blade leaves: a crescent that sweeps through its arc in a few frames,
## bright at the leading edge, and thins out to nothing. Drawn, not animated frames, so
## every swing can differ: reach, width, colour, which way it sweeps.
## Lives on the FX layer so it glows over the dusk.

var reach: float = 26.0
var sweep: float = 2.2  ## radians of arc
var clockwise: bool = true
var color := Color(1.0, 0.95, 0.85)
var life: float = 0.16
var thick: float = 9.0

var _t: float = 0.0


static func spawn(context: Node, at: Vector2, direction: Vector2, shape: Dictionary = {}) -> void:
	if context == null or not context.is_inside_tree():
		return
	var arc := SlashArc.new()
	for key: String in shape:
		arc.set(key, shape[key])
	arc.rotation = direction.angle()
	var root := context.get_tree().get_first_node_in_group(Fx.FX_ROOT_GROUP)
	(root if root else context.get_parent()).add_child(arc)
	arc.global_position = at


func _process(delta: float) -> void:
	_t += delta
	if _t >= life:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _t / life
	# The head of the cut races ahead early, the tail catches up late.
	var head := 1.0 - pow(1.0 - minf(k * 1.9, 1.0), 3.0)
	var tail := pow(maxf(k - 0.25, 0.0) / 0.75, 1.6)
	var a0 := -sweep * 0.5 + sweep * tail
	var a1 := -sweep * 0.5 + sweep * head
	if not clockwise:
		a0 = -a0
		a1 = -a1
	var steps := 14
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in steps + 1:
		var f := float(i) / steps
		var ang := lerpf(a0, a1, f)
		var width := thick * sin(f * PI) * (1.0 - k * 0.6)  # fat in the middle, pointed at both ends
		var dir := Vector2(cos(ang), sin(ang) * 0.8)  # flattened: the view looks down a little
		outer.append(dir * (reach + width * 0.5))
		inner.append(dir * (reach - width * 0.5))
	var alpha := 1.0 - k * k
	for i in steps:
		var quad := PackedVector2Array([inner[i], outer[i], outer[i + 1], inner[i + 1]])
		var f := float(i) / steps
		var c := Color(color, alpha * (0.25 + 0.75 * f))
		draw_primitive(quad, PackedColorArray([c, c, c, c]), PackedVector2Array())
	# A hot white core along the outside edge.
	draw_polyline(outer, Color(1, 1, 1, alpha * 0.9), 1.5)
