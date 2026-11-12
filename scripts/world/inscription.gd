class_name Inscription
extends Node2D
## Something readable in the world: a carved stone, a ledger page, a grave.
## Walk close and press Interact; the text shows in the HUD's lore whisper
## (STORY_BIBLE 9: lore is anchored to objects, one fact at a time).
## A `marked` inscription is one the player is meant to find: its carving glows on
## the wall and lights the floor in front of it, so "read the wall" has a wall to read.

signal read  ## the first time only
signal used  ## every time

const GLYPH := Color(0.62, 0.82, 1.0)
const KEY_FONT: Font = preload("res://assets/fonts/PixelifySans.ttf")
const TEXT_FONT: Font = preload("res://assets/fonts/Alegreya.ttf")

@export_multiline var text: String = ""
@export var radius: float = 34.0
@export var prompt: String = "Read"
## Draw glowing carved lines above this spot and light it.
@export var marked: bool = false
@export var mark_offset: Vector2 = Vector2(0, -40)

var _near: bool = false
var _was_read: bool = false
var _t: float = 0.0
var _light: PointLight2D


func _ready() -> void:
	if marked:
		_light = Prop.make_light(GLYPH, 1.1, 0.7, mark_offset * 0.5)
		add_child(_light)


func _process(delta: float) -> void:
	_t += delta
	var player := get_tree().get_first_node_in_group(&"players") as Node2D
	var near := player != null and player.global_position.distance_to(global_position) < radius
	if near != _near or marked or near:
		queue_redraw()
	_near = near
	if _light:
		_light.energy = (0.5 if _was_read else 1.1) * (0.85 + 0.15 * sin(_t * 2.2))


func _draw() -> void:
	if marked:
		_draw_carving()
	if not _near:
		return
	# A key cap floating over the thing, then the verb.
	var key := Keys.label(&"interact")
	var kw := maxf(14.0, KEY_FONT.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 8.0)
	var tw := TEXT_FONT.get_string_size(prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var bob := sin(_t * 3.0) * 1.5
	var at := Vector2(-(kw + 5.0 + tw) * 0.5, -58.0 + bob) + (mark_offset * 0.4 if marked else Vector2.ZERO)
	var cap := Rect2(at, Vector2(kw, 14))
	draw_rect(cap.grow(1), Color(0.36, 0.32, 0.31))
	draw_rect(cap, Color(0.12, 0.1, 0.1))
	draw_rect(Rect2(cap.position, Vector2(kw, 1)), Color(1.0, 0.62, 0.25))
	draw_string(KEY_FONT, at + Vector2(0, 11), key, HORIZONTAL_ALIGNMENT_CENTER, kw, 10, Color(1.0, 0.86, 0.55))
	draw_string(TEXT_FONT, at + Vector2(kw + 6, 12), prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0, 0, 0, 0.9))
	draw_string(TEXT_FONT, at + Vector2(kw + 5, 11), prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.91, 0.88, 0.82))


## Three short rows of cut marks and a crack running through them.
func _draw_carving() -> void:
	var a := (0.45 if _was_read else 0.8) + 0.2 * sin(_t * 2.2)
	var o := mark_offset
	for row in 3:
		var x := -13.0
		var i := 0
		while x < 13.0:
			var w := 2.0 + float((row * 7 + i * 3) % 4)
			draw_rect(Rect2(o.x + x, o.y + row * 5.0 - 6.0, w, 2), Color(GLYPH, a))
			x += w + 2.0
			i += 1
	draw_polyline(PackedVector2Array([o + Vector2(-3, -14), o + Vector2(1, -6), o + Vector2(-2, 1), o + Vector2(3, 9), o + Vector2(0, 16)]), Color(0.03, 0.03, 0.05, 0.9), 1.5)


func _unhandled_input(event: InputEvent) -> void:
	if _near and event.is_action_pressed(&"interact"):
		EventBus.lore_shown.emit(text)
		AudioManager.sfx(&"ui_click", -6.0, 0.0)
		if not _was_read:
			_was_read = true
			read.emit()
		used.emit()
		get_viewport().set_input_as_handled()
