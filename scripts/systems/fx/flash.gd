class_name Flash
## Drives assets/shaders/flash.gdshader on a sprite: a hit flash, or a pulsing telegraph.
## The sprite's ShaderMaterial must be local to scene (one per instance).

const META_TWEEN: StringName = &"_flash_tween"


static func hit(sprite: CanvasItem, color: Color = Color.WHITE, duration: float = 0.15) -> void:
	var mat := sprite.material as ShaderMaterial
	if mat == null:
		return
	_kill(sprite)
	mat.set_shader_parameter(&"flash_color", color)
	var tween := sprite.create_tween()
	tween.tween_method(func(v: float) -> void: mat.set_shader_parameter(&"flash_amount", v), 1.0, 0.0, duration)
	sprite.set_meta(META_TWEEN, tween)


## Pulses `count` times over `duration` seconds (used for enemy wind-ups).
static func pulse(sprite: CanvasItem, color: Color, duration: float, count: int = 3, strength: float = 0.6) -> void:
	var mat := sprite.material as ShaderMaterial
	if mat == null or count <= 0:
		return
	_kill(sprite)
	mat.set_shader_parameter(&"flash_color", color)
	var setter := func(v: float) -> void: mat.set_shader_parameter(&"flash_amount", v)
	var half := duration / (count * 2.0)
	var tween := sprite.create_tween()
	for i in count:
		tween.tween_method(setter, 0.0, strength, half)
		tween.tween_method(setter, strength, 0.0, half)
	sprite.set_meta(META_TWEEN, tween)


static func clear(sprite: CanvasItem) -> void:
	_kill(sprite)
	var mat := sprite.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter(&"flash_amount", 0.0)


static func _kill(sprite: CanvasItem) -> void:
	if sprite.has_meta(META_TWEEN):
		var old := sprite.get_meta(META_TWEEN) as Tween
		if old and old.is_valid():
			old.kill()
