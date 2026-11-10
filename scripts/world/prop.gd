class_name Prop
extends StaticBody2D
## A placed world prop: sprite, a soft ground shadow, collision from its footprint,
## an optional light, and see-through fading when a local player walks behind it
## (so tall trees and ruins never hide the character).

const FADE_ALPHA: float = 0.38
const FADE_SPEED: float = 8.0
const FADE_MIN_HEIGHT: int = 36  ## only props taller than this fade
const CHECK_INTERVAL: int = 4  ## frames between occlusion checks

static var _shadow_texture: Texture2D

var sprite: Sprite2D

var _fades: bool = false
var _target_alpha: float = 1.0
var _frame_offset: int = 0


func setup(def: PropDef, index: int, flip: bool) -> void:
	collision_layer = Const.LAYER_WORLD
	collision_mask = 0
	var tex: Texture2D = def.textures[index]
	var footprint := def.footprints[index] if index < def.footprints.size() else PackedVector2Array()
	if flip:
		footprint = _mirrored(footprint)
	_add_shadow(footprint, tex)
	sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.centered = false
	sprite.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height() + def.base_inset)
	sprite.flip_h = flip
	add_child(sprite)
	if footprint.size() >= 3:
		var poly := CollisionPolygon2D.new()
		poly.polygon = footprint
		add_child(poly)
	if def.light_color.a > 0.0:
		add_child(IsoRoomBuilder.make_light(def.light_color, def.light_energy, def.light_scale, Vector2(0, -def.light_height)))
	_fades = tex.get_height() > FADE_MIN_HEIGHT
	_frame_offset = randi() % CHECK_INTERVAL
	set_process(_fades)


func _process(delta: float) -> void:
	if (Engine.get_process_frames() + _frame_offset) % CHECK_INTERVAL == 0:
		_target_alpha = FADE_ALPHA if _hides_a_player() else 1.0
	sprite.modulate.a = move_toward(sprite.modulate.a, _target_alpha, FADE_SPEED * delta)


## True when a local player is behind this prop (further from the camera) and
## inside its drawn picture.
func _hides_a_player() -> bool:
	var rect := Rect2(global_position + sprite.offset, sprite.texture.get_size())
	for node in get_tree().get_nodes_in_group(&"players"):
		var player := node as Player
		if player == null or not player.input.is_local():
			continue
		var chest := player.global_position + Vector2(0, -Player.CHEST_HEIGHT)
		var inner := rect.grow(-4) if rect.size.x > 12.0 and rect.size.y > 12.0 else rect
		if player.global_position.y < global_position.y and inner.has_point(chest):
			return true
	return false


func _add_shadow(footprint: PackedVector2Array, tex: Texture2D) -> void:
	var width := tex.get_width() * 0.5
	if footprint.size() >= 3:
		var lo := footprint[0]
		var hi := footprint[0]
		for p in footprint:
			lo = lo.min(p)
			hi = hi.max(p)
		width = maxf(hi.x - lo.x, 10.0) * 1.6
	var shadow := Sprite2D.new()
	shadow.texture = shadow_texture()
	shadow.scale = Vector2(width / 32.0, width / 32.0 * 0.5)
	shadow.position = Vector2(0, -1)
	add_child(shadow)


## A soft shadow sprite to put first under a character (drawn beneath its body).
static func make_shadow(width_scale: float) -> Sprite2D:
	var shadow := Sprite2D.new()
	shadow.name = "Shadow"
	shadow.texture = shadow_texture()
	shadow.scale = Vector2(width_scale, width_scale * 0.45)
	shadow.show_behind_parent = true
	return shadow


static func shadow_texture() -> Texture2D:
	if _shadow_texture == null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
		gradient.colors = PackedColorArray([Color(0, 0, 0, 0.45), Color(0, 0, 0, 0.3), Color(0, 0, 0, 0)])
		var tex := GradientTexture2D.new()
		tex.gradient = gradient
		tex.width = 32
		tex.height = 32
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		_shadow_texture = tex
	return _shadow_texture


static func _mirrored(points: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(points.size() - 1, -1, -1):
		out.append(Vector2(-points[i].x, points[i].y))
	return out
