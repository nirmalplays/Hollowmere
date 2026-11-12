extends Node
## Journeys: three save slots in user://saves/. A journey is saved on its own whenever
## something worth keeping happens (an objective, a rise at the Hearth, leaving through
## the pause menu), never by hand: a souls game doesn't let you scum a save.
## A save holds the area, where you stood, your vitals, the story flags, which Hollowed
## are down, and the area's own quest state. Co-op world/character split (GAME_PLAN 9.3)
## comes with M10; this is the solo slot it will grow from.

signal saved(slot: int)

const SAVE_VERSION: int = 2  ## 2: the journey opens in the Shrine Wood (cave saves are retired)
const SLOTS: int = 3
const DIR: String = "user://saves/"
const START_SCENE: String = "res://scenes/world/shrine_wood.tscn"
const NUMERALS: Array[String] = ["I", "II", "III"]

var current_slot: int = -1  ## the journey being played; -1 = none (menus, tests)
var pending: Dictionary = {}  ## a loaded save waiting for its area to finish building
var play_time: float = 0.0  ## seconds played on the current journey


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(DIR)


func _process(delta: float) -> void:
	if current_slot >= 0 and not get_tree().paused and get_tree().current_scene is AreaScene:
		play_time += delta


func path(slot: int) -> String:
	return "%sjourney_%d.json" % [DIR, slot + 1]


func has(slot: int) -> bool:
	return FileAccess.file_exists(path(slot))


## The slot's data, or {} when empty or unreadable.
func read(slot: int) -> Dictionary:
	if not has(slot):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path(slot)))
	if parsed is Dictionary and int(parsed.get("version", 0)) == SAVE_VERSION:
		return parsed
	return {}


## The most recently played slot, or -1.
func latest_slot() -> int:
	var best := -1
	var best_time := -1.0
	for i in SLOTS:
		var t := float(read(i).get("saved_at", -1.0))
		if t > best_time:
			best_time = t
			best = i
	return best


## One line for menus: "The Nameless Hall  ·  The Waking  ·  0:14".
func describe(slot: int) -> String:
	var data := read(slot)
	if data.is_empty():
		return "An empty cradle"
	var where: String = data.get("place", "")
	if where == "":
		where = data.get("area_title", "")
	var hero: Dictionary = data.get("hero", {})
	var who := "%s, %s  ·  " % [hero.get("name", "Unlaid"), Heroes.title(hero)] if hero.has("class") else ""
	return "%s%s  ·  %s" % [who, where, clock(float(data.get("play_time", 0.0)))]


static func clock(seconds: float) -> String:
	var m := int(seconds) / 60
	return "%d:%02d" % [m / 60, m % 60]


func delete(slot: int) -> void:
	if has(slot):
		DirAccess.remove_absolute(path(slot))


func new_game(slot: int, hero: Dictionary = {}) -> void:
	delete(slot)
	current_slot = slot
	pending = {}
	play_time = 0.0
	GameState.start_solo()
	GameState.players[Const.SOLO_PEER_ID] = hero.duplicate()
	get_tree().paused = false
	get_tree().change_scene_to_file(START_SCENE)


func load_game(slot: int) -> bool:
	var data := read(slot)
	if data.is_empty():
		return false
	current_slot = slot
	pending = data
	play_time = float(data.get("play_time", 0.0))
	GameState.start_solo()
	GameState.players[Const.SOLO_PEER_ID] = (data.get("hero", {}) as Dictionary).duplicate()
	var flags: Dictionary = data.get("flags", {})
	for key: String in flags:
		GameState.flags[StringName(key)] = flags[key]
	get_tree().paused = false
	var area := String(data.get("area", START_SCENE))
	if not ResourceLoader.exists(area):  # a place that no longer exists: begin its road again
		area = START_SCENE
		pending = {}
	get_tree().change_scene_to_file(area)
	return true


## Writes the current journey. Quietly does nothing outside a journey (tests, menus).
func save_game() -> void:
	var area := get_tree().current_scene as AreaScene
	if current_slot < 0 or area == null or area.player == null:
		return
	if area.player.stats.is_dead():
		return  # never keep a corpse: the Hearth save comes right after
	var data := area.capture()
	data["version"] = SAVE_VERSION
	data["saved_at"] = Time.get_unix_time_from_system()
	data["play_time"] = play_time
	data["hero"] = GameState.players.get(Const.SOLO_PEER_ID, {})
	var flags := {}
	for key: Variant in GameState.flags:
		flags[String(key)] = GameState.flags[key]
	data["flags"] = flags
	var file := FileAccess.open(path(current_slot), FileAccess.WRITE)
	if file == null:
		push_warning("Could not write %s" % path(current_slot))
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	saved.emit(current_slot)
