extends Node
## Runtime session state: current world, difficulty, flags, connected players.
## Solo play is a host with zero connected peers (GAME_PLAN 9.0), so this node
## always describes a "session" even when only one player exists.

enum Difficulty { NORMAL, HARD }

var difficulty: Difficulty = Difficulty.NORMAL  # fixed at world creation (GAME_PLAN 7)
var world_id: String = ""
var flags: Dictionary = {}  # mirrors WorldSave.flags (STORY_BIBLE 10); host-owned
var players: Dictionary = {}  # peer_id (int) -> player data; solo = { 1: ... }


func reset() -> void:
	difficulty = Difficulty.NORMAL
	world_id = ""
	flags.clear()
	players.clear()
