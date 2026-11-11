extends AreaScene
## ACT1_MQ01 The Waking (QUESTS.md section 2): the tutorial crypt under the shrine.
## Objectives run strictly in order; each one wakes the next room's Hollowed and
## shows the matching tutorial prompt (QUESTS.md section 7).

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
var _crawlers_down: int = 0
var _grunts_down: int = 0
var _died_early: bool = false
var _sexton: Enemy
var _white: ColorRect


func _start() -> void:
	QuestLog.start("The Waking", OBJECTIVES)
	EventBus.lore_shown.emit("Cold stone. Your lungs remember a breath you did not take.")
	EventBus.tip_shown.emit(TIPS[0])
	GameState.flags[&"has_cradle_lantern"] = false
	EventBus.story_flag_changed.emit(&"has_cradle_lantern", false)
	_sleep(["c", "g", "v", "S"], true)
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
				(node as Inscription).read.connect(func() -> void: _advance(0))
			"I":
				(node as Inscription).read.connect(func() -> void: _advance(3))
			"R", "D", "E":
				(node as Trigger).triggered.connect(_on_trigger)
	EventBus.enemy_killed.connect(_on_enemy_down)
	EventBus.enemy_rested.connect(func(e: Node, _by: Node) -> void: _on_enemy_down(e, null, true))
	EventBus.player_died.connect(func(_p: Node) -> void:
		if _step < 5:
			_died_early = true)


func _advance(index: int) -> void:
	if index != _step:
		return
	QuestLog.complete(index)
	_step += 1
	EventBus.tip_shown.emit(TIPS[_step] if _step < TIPS.size() else "")
	if CARDS.has(_step):
		EventBus.tutorial_card.emit(StringName("waking_%d" % _step), CARDS[_step][0], CARDS[_step][1])
	match _step:
		2:
			_sleep(["c"], false)
		4:
			_sleep(["g"], false)
		5:
			if _died_early:  # QUESTS edge case: a natural death already taught resurrection
				_advance(5)
		8:
			_sleep(["S"], false)
		11:
			_finish()


func _on_trigger(id: StringName) -> void:
	match id:
		&"R":
			_advance(1)
		&"D":
			if _step == 5:
				_collapse()
		&"E":
			_advance(10)


func _on_enemy_down(enemy: Node, _killer: Node, rested: bool = false) -> void:
	var ch: String = enemy.get_meta(&"marker", "")
	if ch == "c" and _step == 2:
		_crawlers_down += 1
		QuestLog.set_step_text(2, "Put down the crawling Hollowed (%d/3)" % _crawlers_down)
		if _crawlers_down >= 3:
			_advance(2)
	elif ch == "g" and _step == 4:
		_grunts_down += 1
		QuestLog.set_step_text(4, "Defeat the Hollowed in the old corridor (%d/2)" % _grunts_down)
		if _grunts_down >= 2:
			_advance(4)
	elif ch == "h" and _step == 6:
		_advance(6)
		if rested:
			_advance(7)
		else:
			_sleep(["v"], false)  # two crawlers to practise the Rest on
	elif rested and _step == 7:
		_advance(7)
	elif enemy == _sexton and _step == 8:
		var key := Pickup.new()
		key.position = _sexton.position
		key.picked.connect(func(_id: StringName) -> void: _advance(9))
		entities.add_child.call_deferred(key)
		if rested:
			EventBus.lore_shown.emit("\"...plot four. Thank you.\"")
			GameState.flags[&"sexton_rested"] = true
		_advance(8)


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
		EventBus.tip_shown.emit("You rose at the Hearth. The Unlaid cannot stay dead.\nEvery death feeds the Hollow and may leave a Scar.\nThis one was free.")
		_advance(5), CONNECT_ONE_SHOT)


func _finish() -> void:
	GameState.flags[&"tutorial_done"] = true
	GameState.flags[&"act"] = 1
	EventBus.toast_shown.emit("Quest complete", "The Waking")
	EventBus.area_entered.emit("The Ashen Reach")
	var tw := create_tween()
	tw.tween_interval(2.5)
	tw.tween_property(_white, ^"color", Color(0, 0, 0, 1), 1.0)
	tw.tween_callback(func() -> void: get_tree().change_scene_to_file(NEXT_AREA))


func _sleep(chars: Array, asleep: bool) -> void:
	for ch: String in chars:
		for e in enemies_with_char(ch):
			e.dormant = asleep
			e.visible = true


func _name_cradles() -> void:
	var names: Array = []
	for node in entities.get_children():
		if node.get_meta(&"marker", "") == "n":
			names.append(node)
	names.sort_custom(func(a: Node2D, b: Node2D) -> bool: return a.position.y < b.position.y or (a.position.y == b.position.y and a.position.x < b.position.x))
	for i in names.size():
		(names[i] as Inscription).text = CRADLE_NAMES[i % CRADLE_NAMES.size()]
