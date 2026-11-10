class_name IsoRoomBuilder
## Builds an IsoRoomLayout: ground tiles, raised cliff blocks (y-sorted with
## characters so they occlude correctly), props with collision/lights, and
## marker scenes. Tiles are found by their "tile_name" custom data.

const SPAWN := "P"
const GROUND_SOURCE := 0
const RAISED_SOURCE := 1


class Result:
	var spawns: Array[Vector2] = []
	var bounds: Rect2i  ## pixel rect covering the map, for camera limits
	var placements: Array[Dictionary] = []  ## {"scene": PackedScene, "position": Vector2}


static func build(layout: IsoRoomLayout, ground_layer: TileMapLayer, raised_layer: TileMapLayer, props_parent: Node2D) -> Result:
	ground_layer.tile_set = layout.tileset
	raised_layer.tile_set = layout.tileset
	var coords := _index_tiles(layout.tileset)
	var rng := RandomNumberGenerator.new()
	rng.seed = layout.tile_seed
	var result := Result.new()
	var grid := layout.lines()
	var min_p := Vector2(INF, INF)
	var max_p := Vector2(-INF, -INF)
	for y in grid.size():
		for x in grid[y].length():
			var ch := grid[y][x]
			var cell := Vector2i(x, y)
			var at := ground_layer.map_to_local(cell)
			min_p = min_p.min(at)
			max_p = max_p.max(at)
			var ground_ch := ch if layout.ground.has(ch) else layout.prop_ground
			_set_tile(ground_layer, cell, GROUND_SOURCE, coords, _pick(layout.ground.get(ground_ch, []), rng))
			if layout.raised.has(ch):
				_set_tile(raised_layer, cell, RAISED_SOURCE, coords, _pick(layout.raised[ch], rng))
			elif layout.props.has(ch):
				_place_prop(layout.props[ch], at, rng, props_parent)
			elif layout.markers.has(ch):
				result.placements.append({"scene": layout.markers[ch], "position": at})
			elif ch == SPAWN:
				result.spawns.append(at)
	result.bounds = Rect2i(Rect2(min_p - Vector2(16, 24), max_p - min_p + Vector2(32, 40)))
	return result


static func _set_tile(layer: TileMapLayer, cell: Vector2i, source: int, coords: Dictionary, tile_name: String) -> void:
	if tile_name != "" and coords.has(tile_name):
		layer.set_cell(cell, source, coords[tile_name])


static func _pick(options: Variant, rng: RandomNumberGenerator) -> String:
	var list: Array = options if options is Array else [options]
	return "" if list.is_empty() else String(list[rng.randi() % list.size()])


static func _place_prop(def: PropDef, at: Vector2, rng: RandomNumberGenerator, parent: Node2D) -> void:
	if def.textures.is_empty():
		return
	var prop := StaticBody2D.new()
	prop.collision_layer = Const.LAYER_WORLD
	prop.position = at + Vector2(rng.randf_range(-def.jitter, def.jitter), rng.randf_range(-def.jitter, def.jitter) * 0.5)
	var tex: Texture2D = def.textures[rng.randi() % def.textures.size()]
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.centered = false
	sprite.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height() + def.base_inset)
	sprite.flip_h = def.flip_randomly and rng.randf() < 0.5
	prop.add_child(sprite)
	if def.collision_radius > 0.0:
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = def.collision_radius
		shape.shape = circle
		prop.add_child(shape)
	if def.light_color.a > 0.0:
		prop.add_child(make_light(def.light_color, def.light_energy, def.light_scale, Vector2(0, -def.light_height)))
	parent.add_child(prop)


static var _light_texture: Texture2D


## A soft round 2D light (shared texture).
static func make_light(color: Color, energy: float, scale: float, offset: Vector2) -> PointLight2D:
	if _light_texture == null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
		gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.4), Color(1, 1, 1, 0)])
		var tex := GradientTexture2D.new()
		tex.gradient = gradient
		tex.width = 192
		tex.height = 192
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		_light_texture = tex
	var light := PointLight2D.new()
	light.texture = _light_texture
	light.color = color
	light.energy = energy
	light.texture_scale = scale
	light.position = offset
	return light


## tile_name -> atlas coords (same coords in both sources).
static func _index_tiles(tileset: TileSet) -> Dictionary:
	var out := {}
	var source := tileset.get_source(GROUND_SOURCE) as TileSetAtlasSource
	for t in source.get_tiles_count():
		var c := source.get_tile_id(t)
		out[String(source.get_tile_data(c, 0).get_custom_data("tile_name"))] = c
	return out
