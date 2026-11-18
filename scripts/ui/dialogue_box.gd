class_name DialogueBox
extends CanvasLayer
## A conversation. The world holds still behind a dark band along the bottom of the
## screen: the speaker's name and epithet on an iron plate, the line typing itself out,
## and when the speaker is done, your answers as a numbered list.
## Conversations are data (data/dialogue/*.json):
##   {"<conversation id>": {"start": "<node>", "nodes": {"<node>": {
##       "speaker": "halsey" | "you", "text": "...",
##       "next": "<node>" | "",                       (no choices: continue on)
##       "choices": [{"text": "...", "next": "<node>", "flags": {"name": value}, "event": "name"}],
##       "flags": {...}, "event": "name"}}}}
##   "speakers": {"halsey": {"name": "Elder Halsey Pruitt", "epithet": "Head of Thornwick"}}
## Flags land in GameState.flags; events are emitted as `event(name)` for the area's script.
## Number keys, Up/Down + Enter, or the mouse choose; Enter or interact skips the typing.

signal event(name: String)
signal finished(conversation: String)

const TITLE_FONT: Font = preload("res://assets/fonts/Cinzel.ttf")
const BODY_FONT: Font = preload("res://assets/fonts/Alegreya.ttf")
const MENU_FONT: Font = preload("res://assets/fonts/PixelifySans.ttf")
const ASH := Color(0.91, 0.88, 0.82)
const ASH_DIM := Color(0.6, 0.56, 0.52)
const EMBER := Color(1.0, 0.62, 0.25)
const EMBER_HOT := Color(1.0, 0.86, 0.55)
const IRON := Color(0.36, 0.32, 0.31)
const CHARS_PER_SEC: float = 55.0
const BAND_H: float = 168.0

static var _cache: Dictionary = {}

var conversation: String = ""
var source: String = ""  ## data/dialogue/<source>.json

var _data: Dictionary = {}
var _node: Dictionary = {}
var _shown: float = 0.0
var _sel: int = 0
var _t: float = 0.0
var _canvas: Control
var _history: Array[String] = []  ## the last line said, shown faint above the current one


## Opens a conversation over the current scene. Returns the box (connect to its signals).
static func open(context: Node, from_file: String, id: String) -> DialogueBox:
	var box := DialogueBox.new()
	box.source = from_file
	box.conversation = id
	context.get_tree().current_scene.add_child(box)
	return box


static func load_file(name: String) -> Dictionary:
	if not _cache.has(name):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue/%s.json" % name))
		_cache[name] = parsed if parsed is Dictionary else {}
	return _cache[name]


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.draw.connect(_draw_box)
	add_child(_canvas)
	_data = load_file(source)
	var conv: Dictionary = _data.get(conversation, {})
	get_tree().paused = true
	AudioManager.sfx(&"ui_click", -8.0, 0.0)
	_go(conv.get("start", ""))


func _go(node_id: String) -> void:
	var conv: Dictionary = _data.get(conversation, {})
	var nodes: Dictionary = conv.get("nodes", {})
	if node_id == "" or not nodes.has(node_id):
		_close()
		return
	if not _node.is_empty():
		_history = [_line_of(_node)]
	_node = nodes[node_id]
	_apply(_node)
	_shown = 0.0
	_sel = 0


func _line_of(node: Dictionary) -> String:
	return "%s: %s" % [_speaker(node).get("name", ""), node.get("text", "")]


func _apply(thing: Dictionary) -> void:
	var flags: Dictionary = thing.get("flags", {})
	for key: String in flags:
		GameState.flags[StringName(key)] = flags[key]
		EventBus.story_flag_changed.emit(StringName(key), flags[key])
	if thing.has("event"):
		event.emit(String(thing["event"]))


func _speaker(node: Dictionary) -> Dictionary:
	var id: String = node.get("speaker", "")
	if id == "you":
		var hero: Dictionary = GameState.players.get(Const.SOLO_PEER_ID, {})
		return {"name": hero.get("name", "You"), "epithet": "the Unlaid"}
	return _data.get("speakers", {}).get(id, {"name": id.capitalize(), "epithet": ""})


func _choices() -> Array:
	var out: Array = []
	for c: Dictionary in _node.get("choices", []):
		var need: String = c.get("if", "")
		if need == "" or GameState.flags.get(StringName(need), false):
			out.append(c)
	return out


func _typing() -> bool:
	return _shown < String(_node.get("text", "")).length()


func _process(delta: float) -> void:
	_t += delta
	if _typing():
		var before := int(_shown)
		_shown += delta * CHARS_PER_SEC
		if int(_shown) / 6 != before / 6:
			AudioManager.sfx(&"ui_hover", -24.0, 0.2, 40)
	_canvas.queue_redraw()


func _input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	var choices := _choices()
	if event is InputEventKey and event.keycode >= KEY_1 and event.keycode <= KEY_9 and not _typing():
		var i: int = event.keycode - KEY_1
		if i < choices.size():
			_pick(choices[i])
	elif event.is_action_pressed(&"ui_down") or event.is_action_pressed(&"move_down"):
		if choices.size() > 0:
			_sel = (_sel + 1) % choices.size()
			AudioManager.sfx(&"ui_hover", -12.0, 0.04)
	elif event.is_action_pressed(&"ui_up") or event.is_action_pressed(&"move_up"):
		if choices.size() > 0:
			_sel = (_sel + choices.size() - 1) % choices.size()
			AudioManager.sfx(&"ui_hover", -12.0, 0.04)
	elif event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"interact") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		if event is InputEventMouseButton:
			var hit := _choice_at(event.position)
			if hit >= 0 and not _typing():
				_sel = hit
		_advance(choices)
	elif event.is_action_pressed(&"ui_cancel") and choices.is_empty():
		_advance(choices)
	else:
		return
	get_viewport().set_input_as_handled()


func _advance(choices: Array) -> void:
	if _typing():
		_shown = 9999.0
		return
	if choices.is_empty():
		AudioManager.sfx(&"ui_click", -10.0, 0.0)
		_go(_node.get("next", ""))
	else:
		_pick(choices[clampi(_sel, 0, choices.size() - 1)])


func _pick(choice: Dictionary) -> void:
	AudioManager.sfx(&"ui_click", -6.0, 0.0)
	_history = ["You: " + String(choice.get("text", ""))]
	_apply(choice)
	var before := _node
	_go(choice.get("next", ""))
	if _node == before:  # a choice that ends the conversation
		_close()


func _close() -> void:
	get_tree().paused = false
	finished.emit(conversation)
	queue_free()


func _choice_at(at: Vector2) -> int:
	var s := _canvas.get_viewport_rect().size
	var top := s.y - BAND_H + 92.0
	for i in _choices().size():
		if Rect2(s.x * 0.5 - 300, top + i * 22 - 16, 600, 22).has_point(at):
			return i
	return -1


# ---------------------------------------------------------------- drawing

func _draw_box() -> void:
	var s := _canvas.get_viewport_rect().size
	var top := s.y - BAND_H
	for i in 24:  # the band darkens from nothing to near-black
		var k := float(i) / 23.0
		_canvas.draw_rect(Rect2(0, top - 40 + i * 2, s.x, 2), Color(0.02, 0.015, 0.02, 0.85 * k))
	_canvas.draw_rect(Rect2(0, top + 8, s.x, BAND_H), Color(0.02, 0.015, 0.02, 0.88))
	_canvas.draw_rect(Rect2(s.x * 0.5 - 320, top + 8, 640, 1), Color(EMBER, 0.6))
	var who := _speaker(_node)
	var x := s.x * 0.5 - 300.0
	var w := 600.0
	# The name plate.
	var name: String = who.get("name", "")
	var nw := TITLE_FONT.get_string_size(name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 22.0
	var plate := Rect2(x, top - 6, nw, 22)
	_canvas.draw_rect(plate.grow(1), IRON)
	_canvas.draw_rect(plate, Color(0.1, 0.08, 0.08))
	_canvas.draw_rect(Rect2(plate.position, Vector2(3, plate.size.y)), EMBER)
	_text(TITLE_FONT, plate.position + Vector2(12, 16), name.to_upper(), 14, EMBER_HOT if _node.get("speaker", "") != "you" else ASH)
	if who.get("epithet", "") != "":
		_text(BODY_FONT, Vector2(x + nw + 10, top + 10), who["epithet"], 13, ASH_DIM)
	# The faint line before, then the line now.
	if not _history.is_empty():
		_text(BODY_FONT, Vector2(x, top + 34), _history[0].left(110), 12, Color(ASH_DIM, 0.6))
	var line: String = String(_node.get("text", "")).left(int(_shown))
	var y := _para(Vector2(x, top + 56), line, w, ASH, 17)
	if _typing():
		return
	var choices := _choices()
	if choices.is_empty():
		var blink := 0.5 + 0.5 * sin(_t * 5.0)
		_text(MENU_FONT, Vector2(x + w - 80, s.y - 16), Keys.label(&"interact") + "  continue", 11, Color(ASH_DIM, 0.5 + 0.5 * blink))
		return
	var cy := maxf(y + 6.0, top + 92.0)
	for i in choices.size():
		var on := i == _sel
		if on:
			var f := 0.8 + 0.2 * sin(_t * 12.0)
			_canvas.draw_rect(Rect2(x - 14, cy - 10 - 2 * f, 3, 5 + 2 * f), EMBER)
		_text(MENU_FONT, Vector2(x, cy), "%d" % (i + 1), 13, EMBER if on else ASH_DIM)
		_text(BODY_FONT, Vector2(x + 18, cy), choices[i]["text"], 15, EMBER_HOT if on else ASH)
		cy += 22.0


func _para(at: Vector2, t: String, w: float, col: Color, sz: int) -> float:
	var line := ""
	var y := at.y
	for word in t.split(" "):
		var trial := word if line == "" else line + " " + word
		if line != "" and BODY_FONT.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > w:
			_text(BODY_FONT, Vector2(at.x, y), line, sz, col)
			y += sz + 4
			line = word
		else:
			line = trial
	if line != "":
		_text(BODY_FONT, Vector2(at.x, y), line, sz, col)
		y += sz + 4
	return y


func _text(font: Font, at: Vector2, t: String, sz: int, col: Color) -> void:
	_canvas.draw_string(font, at + Vector2(1, 1), t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color(0, 0, 0, 0.85 * col.a))
	_canvas.draw_string(font, at, t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
