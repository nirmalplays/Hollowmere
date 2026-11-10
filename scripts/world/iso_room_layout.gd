class_name IsoRoomLayout
extends Resource
## An isometric area authored as text (GAME_PLAN 0.3: content is data).
## Each character is one map cell (Godot diamond-down layout: +x runs down-right
## on screen, +y runs down-left). Legend dictionaries map characters to content:
##   ground: char -> Array of tile names (one picked per cell)
##   raised: char -> Array of tile names for one-block-high cliffs (solid)
##   props:  char -> PropDef placed on `prop_ground`
##   markers: char -> PackedScene (enemies, NPCs, interactables), also on `prop_ground`
## 'P' is the player spawn.

@export_multiline var rows: String = ""
@export var tileset: TileSet
@export var tile_seed: int = 1
@export var ground: Dictionary = {}
@export var raised: Dictionary = {}
@export var props: Dictionary = {}
@export var markers: Dictionary = {}
## Ground character used under props, markers, cliffs and the spawn.
@export var prop_ground: String = "."


func lines() -> PackedStringArray:
	var out := PackedStringArray()
	for line in rows.split("\n"):
		var trimmed := line.strip_edges(false, true)
		if not trimmed.is_empty():
			out.append(trimmed)
	return out
