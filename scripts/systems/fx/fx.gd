class_name Fx
## Spawns one-shot visual effects and floating text on the room's FX layer.
## The FX layer is a CanvasLayer that follows the camera but sits outside the
## room's CanvasModulate, so effects keep their glow in dark rooms.

const FX_ROOT_GROUP: StringName = &"fx_root"
const TEXT_RISE: float = 14.0
const TEXT_TIME: float = 0.7


static func spawn(def: FxDef, at: Vector2, direction: Vector2, context: Node) -> AnimatedSprite2D:
	if def == null or context == null or not context.is_inside_tree():
		return null
	var sprite := AnimatedSprite2D.new()
	sprite.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # placed once: never slide in from the origin
	sprite.sprite_frames = def.frames()
	sprite.centered = false
	sprite.offset = -def.anchor
	if def.rotates and direction != Vector2.ZERO:
		sprite.rotation = direction.angle()
	_root(context).add_child(sprite)
	sprite.global_position = at
	sprite.animation_finished.connect(sprite.queue_free)
	sprite.play(&"default")
	return sprite


static func text(at: Vector2, value: String, color: Color, context: Node) -> void:
	if context == null or not context.is_inside_tree():
		return
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(48, 10)
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_color_override(&"font_outline_color", Color(0.1, 0.08, 0.13))
	label.add_theme_constant_override(&"outline_size", 2)
	_root(context).add_child(label)
	label.global_position = at - label.size * 0.5
	var tween := label.create_tween()
	tween.tween_property(label, ^"position:y", label.position.y - TEXT_RISE, TEXT_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tween.parallel().tween_property(label, ^"modulate:a", 0.0, TEXT_TIME * 0.5).set_delay(TEXT_TIME * 0.5)
	tween.tween_callback(label.queue_free)


static func _root(context: Node) -> Node:
	var root := context.get_tree().get_first_node_in_group(FX_ROOT_GROUP)
	return root if root else context.get_tree().current_scene
