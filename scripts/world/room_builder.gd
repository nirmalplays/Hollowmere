class_name RoomBuilder
## Paints a RoomLayout into a TileMapLayer. Tiles are looked up by their
## "tile_name" custom data, so the atlas can be rearranged without code changes.

const WALL := "#"
const FLOOR := "."
const ASH := "a"
const SPAWN := "P"


class Result:
	var spawns: Array[Vector2] = []  ## world positions of 'P' cells (tile centers)
	var bounds: Rect2i  ## room rect in pixels, for camera limits


static func build(layout: RoomLayout, layer: TileMapLayer) -> Result:
	layer.tile_set = layout.tileset
	var tiles := _index_tiles(layout.tileset)
	var rng := RandomNumberGenerator.new()
	rng.seed = layout.tile_seed
	var grid := layout.lines()
	var result := Result.new()
	var width := 0
	for y in grid.size():
		var line := grid[y]
		width = maxi(width, line.length())
		for x in line.length():
			var ch := line[x]
			var cell := Vector2i(x, y)
			var tile_name := ""
			match ch:
				WALL:
					var below_is_open := y + 1 < grid.size() and x < grid[y + 1].length() and grid[y + 1][x] != WALL
					tile_name = "wall_face" if below_is_open else "wall_top"
				FLOOR:
					tile_name = _weighted_pick(layout.floor_weights, rng)
				ASH:
					tile_name = "floor_ash"
				SPAWN:
					tile_name = "floor_a"
					result.spawns.append(layer.map_to_local(cell))
			if tile_name != "" and tiles.has(tile_name):
				layer.set_cell(cell, tiles[tile_name].x, tiles[tile_name].y)
	var ts := layout.tileset.tile_size
	result.bounds = Rect2i(0, 0, width * ts.x, grid.size() * ts.y)
	return result


## tile_name -> {"x": source_id, "y": atlas coords}.
static func _index_tiles(tileset: TileSet) -> Dictionary:
	var out := {}
	for i in tileset.get_source_count():
		var source_id := tileset.get_source_id(i)
		var source := tileset.get_source(source_id) as TileSetAtlasSource
		if source == null:
			continue
		for t in source.get_tiles_count():
			var coords := source.get_tile_id(t)
			var tile_name: String = source.get_tile_data(coords, 0).get_custom_data("tile_name")
			out[tile_name] = {"x": source_id, "y": coords}
	return out


static func _weighted_pick(weights: Dictionary, rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for w in weights.values():
		total += float(w)
	var roll := rng.randf() * total
	for key in weights:
		roll -= float(weights[key])
		if roll <= 0.0:
			return key
	return weights.keys()[0]
