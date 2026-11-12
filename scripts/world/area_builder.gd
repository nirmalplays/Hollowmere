class_name AreaBuilder
## Builds an AreaLayout on a square grid. Walls show their faces like the reference:
## a wall cell directly above floor is the base row of the face, the next one up the
## middle, the next the capped top; a wall below floor is a ledge; walls beside floor
## get a trim; everything else is the dark mass behind the walls.

const SPAWN := "P"
const FACE_ROWS: Array[String] = ["base", "mid", "cap"]


class Result:
	var spawns: Array[Vector2] = []
	var bounds: Rect2i
	var placements: Array[Dictionary] = []  ## {"scene", "position", "char"}


static func build(layout: AreaLayout, floor_layer: TileMapLayer, wall_layer: TileMapLayer, props_parent: Node2D) -> Result:
	floor_layer.tile_set = layout.tileset
	wall_layer.tile_set = layout.tileset
	var tiles := _index(layout.tileset)
	var rng := RandomNumberGenerator.new()
	rng.seed = layout.tile_seed
	var grid := layout.lines()
	var painted := layout.ground != null
	wall_layer.visible = not painted
	var result := Result.new()
	var width := 0
	for y in grid.size():
		width = maxi(width, grid[y].length())
		for x in grid[y].length():
			var ch := grid[y][x]
			var cell := Vector2i(x, y)
			var at := floor_layer.map_to_local(cell)
			if ch == layout.wall_char:
				_set_tile(wall_layer, cell, tiles, layout.wall_set + "_void" if painted else _wall_tile(layout, grid, x, y, rng))
				continue
			var floor_ch := ch if layout.floors.has(ch) else layout.prop_floor
			if not painted:
				_set_tile(floor_layer, cell, tiles, _pick(layout.floors.get(floor_ch, []), rng))
			if layout.props.has(ch):
				var prop := Prop.new()
				prop.position = at
				var def: PropDef = layout.props[ch]
				prop.position += Vector2(rng.randf_range(-def.jitter, def.jitter), rng.randf_range(-def.jitter, def.jitter) * 0.5)
				prop.setup(def, rng.randi() % def.textures.size(), def.flip_randomly and rng.randf() < 0.5)
				props_parent.add_child(prop)
			elif layout.markers.has(ch):
				result.placements.append({"scene": layout.markers[ch], "position": at, "char": ch})
			elif ch == SPAWN:
				result.spawns.append(at)
	for i in layout.scatter_points.size():
		var sdef: PropDef = layout.scatter_defs[layout.scatter_index[i]]
		var sprop := Prop.new()
		sprop.position = layout.scatter_points[i]
		sprop.setup(sdef, rng.randi() % sdef.textures.size(), sdef.flip_randomly and rng.randf() < 0.5)
		props_parent.add_child(sprop)
	var ts := layout.tileset.tile_size
	result.bounds = Rect2i(0, 0, width * ts.x, grid.size() * ts.y)
	return result


static func _wall_tile(layout: AreaLayout, grid: PackedStringArray, x: int, y: int, rng: RandomNumberGenerator) -> String:
	var prefix := layout.wall_set + "_"
	var variant := str(rng.randi() % 3)
	for i in FACE_ROWS.size():
		if _is_floor(layout, grid, x, y + 1 + i):
			# Only a face if the cells between are wall (a 1-high wall is all base).
			var all_wall := true
			for j in i:
				all_wall = all_wall and not _is_floor(layout, grid, x, y + 1 + j)
			if all_wall:
				return prefix + "wall_" + FACE_ROWS[i] + "_" + variant
	if _is_floor(layout, grid, x, y - 1):
		return prefix + "ledge_" + variant
	if _is_floor(layout, grid, x - 1, y):
		return prefix + "trim_left"
	if _is_floor(layout, grid, x + 1, y):
		return prefix + "trim_right"
	return prefix + "void"


static func _is_floor(layout: AreaLayout, grid: PackedStringArray, x: int, y: int) -> bool:
	if y < 0 or y >= grid.size() or x < 0 or x >= grid[y].length():
		return false
	return grid[y][x] != layout.wall_char


static func _set_tile(layer: TileMapLayer, cell: Vector2i, tiles: Dictionary, tile_name: String) -> void:
	if tiles.has(tile_name):
		var t: Array = tiles[tile_name]
		layer.set_cell(cell, t[0], t[1])


static func _pick(options: Variant, rng: RandomNumberGenerator) -> String:
	var list: Array = options if options is Array else [options]
	return "" if list.is_empty() else String(list[rng.randi() % list.size()])


## tile_name -> [source_id, atlas coords]
static func _index(tileset: TileSet) -> Dictionary:
	var out := {}
	for i in tileset.get_source_count():
		var sid := tileset.get_source_id(i)
		var source := tileset.get_source(sid) as TileSetAtlasSource
		if source == null:
			continue
		for t in source.get_tiles_count():
			var c := source.get_tile_id(t)
			out[String(source.get_tile_data(c, 0).get_custom_data("tile_name"))] = [sid, c]
	return out
