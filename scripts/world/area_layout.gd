class_name AreaLayout
extends Resource
## A top-down 3/4 area authored as text, one character per 32 px cell (docs/ART_DIRECTION.md).
##   wall_char: solid mass; the builder picks faces/ledges/trims from its neighbours
##   floors:    char -> Array of floor tile names (one picked per cell)
##   props:     char -> PropDef placed on `prop_floor`
##   markers:   char -> PackedScene (enemies, triggers, interactables) on `prop_floor`
## 'P' is the player spawn (the first Hearth).

@export_multiline var rows: String = ""
@export var tileset: TileSet
@export var tile_seed: int = 1
@export var wall_char: String = "#"
@export var wall_set: String = "crypt"  ## tile name prefix: <set>_wall_cap_0 ...
@export var floors: Dictionary = {}
@export var props: Dictionary = {}
@export var markers: Dictionary = {}
@export var prop_floor: String = "."
## Outdoor areas: one painted picture for the whole ground instead of floor tiles, and
## the wall cells keep their collision but are not drawn (the forest stands on them).
@export var ground: Texture2D
## Props placed freely in pixels (not on the grid): the forest wall, tufts, stones.
## scatter_points[i] uses scatter_defs[scatter_index[i]].
@export var scatter_defs: Array[PropDef] = []
@export var scatter_points: PackedVector2Array = []
@export var scatter_index: PackedInt32Array = []
## Named places inside the area, in cells: walking into one announces it, the way a
## zone is really a string of named spots. Same index in both arrays.
@export var place_names: PackedStringArray = []
@export var place_rects: Array[Rect2i] = []


func lines() -> PackedStringArray:
	var out := PackedStringArray()
	for line in rows.split("\n"):
		var trimmed := line.strip_edges(false, true)
		if not trimmed.is_empty():
			out.append(trimmed)
	return out
