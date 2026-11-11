extends AreaScene
## ACT1_MQ01 The Waking (QUESTS.md section 2): the tutorial crypt under the shrine.
## Objectives are shown in order with their tutorial prompts (QUESTS.md section 7),
## but each is a condition that can be met early: nothing in here waits on the quest.

const NEXT_AREA: String = "res://scenes/ui/main_menu.tscn"  # TODO: Thornwick gate (ACT1_MQ02) once built
const OBJECTIVES: PackedStringArray = [
	"Take the lantern from beside your cradle",
	"Find a way out of the cradle chamber",
	"Put down the crawling Hollowed (0/3)",
	"Read the cracked wall",
	"Defeat the Hollowed in the old corridor (0/2)",
	"Follow the old corridor south",
	"Defeat the shielded Hollowed",
	"Lay a staggered Hollowed to rest",
	"Defeat the Gaunt Sexton",
	"Take the Sexton's Key",
	"Climb the stairwell",
]
## Unoccupied cradles carry the other Unlaid's names (QUESTS.md MQ01 key scenes).
const CRADLE_NAMES: Array[String] = [
	"Carved into the stone: SORREL.", "Carved into the stone: TOBIAS.", "Carved into the stone: LYSA.",
	"Carved into the stone: ANSELM. Someone has scratched a tally beside it.",
	"Carved into the stone: MIREILLE.", "Carved into the stone: HALDOR. Moss has grown into the letters.",
	"A name was carved here. It has been scratched out, again and again, until the stone is raw.",
]
const TIPS: Array[String] = [
	"Move with [{move_up}][{move_left}][{move_down}][{move_right}]   Sprint: hold [{sprint}]
Take the lantern: [{interact}]",
	"Follow the corridor north",
	"Light attack [{attack_light}]   Heavy attack [{attack_heavy}]
Every swing spends stamina: watch the pale bar",
	"Read the cracked wall: [{interact}]",
	"Roll with [{dodge}] when the ground flashes red
The start of a roll can't be hit",
	"",
	"Hold [{block}] to block. Tap [{block}] as a blow lands to parry
Drink from your flask with [{heal}]",
	"Stagger a Hollowed, then [{interact}] beside it to lay it to rest",
	"",
	"Take the Sexton's Key",
	"Climb the stairwell",
]
## One-time explainers (QUESTS.md 7), shown when the concept first matters.
const CARDS := {
	1: ["The Cradle Lantern", "It was lit before you woke, and it has not gone out.

The lantern is your light in the dark, and it lets you lay a Hollowed to rest: when one is staggered, stand beside it and press {interact}. A rested soul passes on, and the Hollow loosens its grip on the land."],
	2: ["The Hollowed", "Things that should have ended, and didn't. The Hollowed are the dead who could not pass on: hungry, forgetful, still carrying echoes of who they were.

Watch them. Every attack is shown before it lands: a flash, and red on the ground."],
	7: ["Rest", "Parry an attack or break a Hollowed's guard, and it staggers. Now press {interact} beside it.

Resting is slower than killing, but a rested soul does not come back, and the Hollow Pressure in this place falls."],
}

var _step: int = 0
var _done: Dictionary = {}  ## objective index -> true once its condition is met, in any order
var _crawlers_down: int = 0
var _grunts_down: int = 0
var _sexton: Enemy
var _white: ColorRect


func _start() -> void:
	QuestLog.start("The Waking", OBJECTIVES)
	EventBus.lore_shown.emit("Cold stone. Your lungs remember a breath you did not take.")
	EventBus.tip_shown.emit(TIPS[0])
	GameState.flags[&"has_cradle_lantern"] = false
	EventBus.story_flag_changed.emit(&"has_cradle_lantern", false)
	for e in enemies_with_char("S"):
		_sexton = e
	_name_cradles()
	_white = ColorRect.new()
	_white.color = Color(1, 1, 1, 0)
	_white.set_anchors_preset(Control.PRESET_FULL_RECT)
	_white.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var layer := CanvasLayer.new()
	layer.layer = 20
	layer.add_child(_white)
	add_child(layer)
	for node in entities.get_children():
		match node.get_meta(&"marker", ""):
			"L":
				(node as Inscription).read.connect(func() -> void: _mark(0))
			"I":
				(node as Inscription).read.connect(func() -> void: _mark(3))
			"R", "D", "E":
				(node as Trigger).triggered.connect(_on_trigger)
	EventBus.enemy_killed.connect(_on_enemy_down)
	EventBus.enemy_rested.connect(func(e: Node, _by: Node) -> void: _on_enemy_down(e, null, true))
	EventBus.player_died.connect(func(_p: Node) -> void:
		if not _done.has(5):
			_mark(5))  # QUESTS edge case: a natural death already taught resurrection


## The Hollowed here are never asleep waiting for the quest: they attack whoever comes
## near, in whatever order the player finds them. So objectives are conditions, not a
## script: `_mark` records one as met, and the tracker walks forward through every
## objective that is already satisfied.
func _mark(index: int) -> void:
	if _done.has(index):
		return
	_done[index] = true
	var moved := false
	while _step < OBJECTIVES.size() and _done.has(_step):
		QuestLog.complete(_step)
		_step += 1
		moved = true
	if not moved:
		return
	EventBus.tip_shown.emit(TIPS[_step] if _step < TIPS.size() else "")
	if CARDS.has(_step):
		EventBus.tutorial_card.emit(StringName("waking_%d" % _step), CARDS[_step][0], CARDS[_step][1])
	if _step >= OBJECTIVES.size():
		_finish()


func _on_trigger(id: StringName) -> void:
	match id:
		&"R":
			_mark(1)
			if not _done.has(0):
				EventBus.lore_shown.emit("The dark ahead is total. Behind you, beside your cradle, something is still burning.")
		&"D":
			if not _done.has(5):
				_collapse()
		&"E":
			if _done.has(9):
				_mark(10)
			else:
				EventBus.lore_shown.emit("An iron gate, locked. The Sexton kept the key.")
				for node in entities.get_children():  # let the gate be tried again
					if node is Trigger and node.get_meta(&"marker", "") == "E":
						(node as Trigger).rearm()


func _on_enemy_down(enemy: Node, _killer: Node, rested: bool = false) -> void:
	var ch: String = enemy.get_meta(&"marker", "")
	if rested:
		_mark(7)
	if ch == "c":
		_crawlers_down += 1
		QuestLog.set_step_text(2, "Put down the crawling Hollowed (%d/3)" % mini(_crawlers_down, 3))
		if _crawlers_down >= 3:
			_mark(2)
	elif ch == "g":
		_grunts_down += 1
		QuestLog.set_step_text(4, "Defeat the Hollowed in the old corridor (%d/2)" % mini(_grunts_down, 2))
		if _grunts_down >= 2:
			_mark(4)
	elif ch == "h":
		_mark(6)
	elif enemy == _sexton:
		var key := Pickup.new()
		key.position = _sexton.position
		key.picked.connect(func(_id: StringName) -> void: _mark(9))
		entities.add_child.call_deferred(key)
		if rested:
			EventBus.lore_shown.emit("\"...plot four. Thank you.\"")
			GameState.flags[&"sexton_rested"] = true
		_mark(8)


## O6: the ceiling gives way. A white-out, a voice, and you rise at the Hearth.
func _collapse() -> void:
	HitFeedback.shake(6.0, 0.8)
	AudioManager.sfx(&"thunder", 0.0, 0.0)
	EventBus.tip_shown.emit("")
	var tw := create_tween()
	tw.tween_property(_white, ^"color:a", 1.0, 0.35)
	tw.tween_callback(func() -> void:
		player.die_scripted()
		EventBus.lore_shown.emit("A voice that is not a voice: \"Again.\""))
	tw.tween_property(_white, ^"color:a", 0.0, 1.2)
	player.respawned.connect(func() -> void:
		_mark(5)
		EventBus.tip_shown.emit("You rose at the Hearth. The Unlaid cannot stay dead.
Every death feeds the Hollow and may leave a Scar.
This one was free."), CONNECT_ONE_SHOT)


func _finish() -> void:
	GameState.flags[&"tutorial_done"] = true
	GameState.flags[&"act"] = 1
	EventBus.toast_shown.emit("Quest complete", "The Waking")
	EventBus.area_entered.emit("The Ashen Reach")
	var tw := create_tween()
	tw.tween_interval(2.5)
	tw.tween_property(_white, ^"color", Color(0, 0, 0, 1), 1.0)
	tw.tween_callback(func() -> void: get_tree().change_scene_to_file(NEXT_AREA))


func _name_cradles() -> void:
	var names: Array = []
	for node in entities.get_children():
		if node.get_meta(&"marker", "") == "n":
			names.append(node)
	names.sort_custom(func(a: Node2D, b: Node2D) -> bool: return a.position.y < b.position.y or (a.position.y == b.position.y and a.position.x < b.position.x))
	for i in names.size():
		(names[i] as Inscription).text = CRADLE_NAMES[i % CRADLE_NAMES.size()]
