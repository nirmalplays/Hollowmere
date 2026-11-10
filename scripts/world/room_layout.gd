class_name RoomLayout
extends Resource
## A hand-authored room as text, so rooms are data (GAME_PLAN 0.3).
## Legend: '#' wall, '.' floor (weighted random variant), 'a' ash floor,
## 'P' player spawn (floor underneath). Characters listed in `markers` place a scene
## on floor (e.g. 'D' -> training dummy). Anything else is left empty.

@export_multiline var rows: String = ""
@export var tileset: TileSet
@export var tile_seed: int = 1
## tile_name -> weight for '.' cells.
@export var floor_weights: Dictionary = {"floor_a": 6, "floor_b": 2, "floor_c": 1}
## layout character -> PackedScene spawned at that cell (enemies, props, interactables).
@export var markers: Dictionary = {}


func lines() -> PackedStringArray:
	var out := PackedStringArray()
	for line in rows.split("\n"):
		var trimmed := line.strip_edges(false, true)
		if not trimmed.is_empty():
			out.append(trimmed)
	return out
