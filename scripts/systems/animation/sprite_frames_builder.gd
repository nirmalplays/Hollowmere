class_name SpriteFramesBuilder
## Turns a SpriteSheetDef into SpriteFrames at runtime, cached per definition.

static var _cache: Dictionary = {}  # SpriteSheetDef -> SpriteFrames


static func build(def: SpriteSheetDef) -> SpriteFrames:
	if _cache.has(def):
		return _cache[def]
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for anim: SpriteAnimRow in def.animations:
		frames.add_animation(anim.name)
		frames.set_animation_speed(anim.name, anim.fps)
		frames.set_animation_loop(anim.name, anim.loop)
		for i in anim.frame_count:
			var atlas := AtlasTexture.new()
			atlas.atlas = def.texture
			atlas.region = Rect2(
				Vector2(i * def.frame_size.x, anim.row * def.frame_size.y), Vector2(def.frame_size)
			)
			frames.add_frame(anim.name, atlas)
	_cache[def] = frames
	return frames
