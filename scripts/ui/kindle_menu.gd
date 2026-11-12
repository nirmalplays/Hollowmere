class_name KindleMenu
extends CanvasLayer
## Opens when you rest at a fire: feed Echoes to the flame and grow. Five attributes,
## each level a little dearer than the last. What each one does is said in plain words;
## the numbers on the right show before and after. Up/Down choose, Enter kindle, Esc rise.

const MENU_FONT: Font = preload("res://assets/fonts/PixelifySans.ttf")
const BODY_FONT: Font = preload("res://assets/fonts/Alegreya.ttf")
const TITLE_FONT: Font = preload("res://assets/fonts/Cinzel.ttf")
const ASH := Color(0.91, 0.88, 0.82)
const ASH_DIM := Color(0.62, 0.58, 0.54)
const EMBER := Color(1.0, 0.62, 0.25)
const EMBER_HOT := Color(1.0, 0.86, 0.55)
const ECHO := Color(0.6, 0.86, 1.0)
const LEFT: float = 90.0
const TOP: float = 190.0
const ROW_H: float = 40.0
const ROWS: Array = [
	["might", "Might", "Every blow lands harder."],
	["vitality", "Vitality", "More health to lose."],
	["agility", "Agility", "More stamina, and it returns faster."],
	["intellect", "Intellect", "Your ability strikes harder and comes back sooner."],
	["spirit", "Spirit", "Each sip of the Ember Flask mends more."],
]

var player: Player

var _canvas: Control
var _sel: int = 0
var _t: float = 0.0
var _fade: float = 0.0
var _flash: float = 0.0
var _refuse: float = 0.0


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.draw.connect(_draw_menu)
	add_child(_canvas)
	get_tree().paused = true


func _process(delta: float) -> void:
	_t += delta
	_fade = minf(1.0, _fade + delta * 5.0)
	_flash = maxf(0.0, _flash - delta * 2.5)
	_refuse = maxf(0.0, _refuse - delta * 3.0)
	_canvas.queue_redraw()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause"):
		_close()
	elif event.is_action_pressed(&"ui_down") or event.is_action_pressed(&"move_down"):
		_sel = (_sel + 1) % ROWS.size()
		AudioManager.sfx(&"ui_move", -10.0, 0.04)
	elif event.is_action_pressed(&"ui_up") or event.is_action_pressed(&"move_up"):
		_sel = (_sel + ROWS.size() - 1) % ROWS.size()
		AudioManager.sfx(&"ui_move", -10.0, 0.04)
	elif event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"interact"):
		_kindle()
	elif event is InputEventMouseMotion:
		var i := int(floor((event.position.y - TOP + ROW_H * 0.6) / ROW_H))
		if i >= 0 and i < ROWS.size() and event.position.x < 520.0:
			_sel = i
		return
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_kindle()
	else:
		return
	get_viewport().set_input_as_handled()


func _kindle() -> void:
	if player.raise_attribute(ROWS[_sel][0]):
		_flash = 1.0
		AudioManager.sfx(&"level_up", -6.0, 0.0)
	else:
		_refuse = 1.0
		AudioManager.sfx(&"ui_back", -6.0, 0.0)


func _close() -> void:
	get_tree().paused = false
	AudioManager.sfx(&"ui_back", -8.0, 0.0)
	SaveManager.save_game.call_deferred()
	queue_free()


func _draw_menu() -> void:
	var s := _canvas.get_viewport_rect().size
	var a := _fade
	_canvas.draw_rect(Rect2(Vector2.ZERO, s), Color(0.03, 0.02, 0.015, 0.78 * a))
	# The fire's glow, low on the left.
	var flick := 0.9 + 0.1 * sin(_t * 9.0) * sin(_t * 5.3)
	for i in 6:
		_canvas.draw_circle(Vector2(LEFT + 120, s.y + 40), (420.0 - i * 60.0) * flick, Color(1.0, 0.5, 0.18, 0.03 * a + 0.02 * _flash))
	_shadowed(TITLE_FONT, Vector2(LEFT, TOP - 86), "KINDLE", 30, Color(ASH, a))
	_shadowed(BODY_FONT, Vector2(LEFT, TOP - 62), "Feed the fire what the Hollowed left behind.", 15, Color(ASH_DIM, a))
	_canvas.draw_rect(Rect2(LEFT, TOP - 50, 140, 1), Color(EMBER, 0.8 * a))
	var cost := player.kindle_cost()
	for i in ROWS.size():
		var row: Array = ROWS[i]
		var y := TOP + i * ROW_H
		var on := i == _sel
		var level := player.attribute_level(row[0])
		if on:
			var f := 0.8 + 0.2 * sin(_t * 12.0)
			_canvas.draw_rect(Rect2(LEFT - 18, y - 11 - 3 * f, 4, 6 + 3 * f), Color(EMBER, a))
		_shadowed(MENU_FONT, Vector2(LEFT, y), row[1], 22, Color(EMBER_HOT if on else ASH_DIM, a))
		for p in 10:
			var pip := Rect2(LEFT + 150 + p * 16, y - 10, 12, 8)
			_canvas.draw_rect(pip, Color(0.18, 0.15, 0.14, a))
			if p < level:
				_canvas.draw_rect(pip, Color(EMBER if p < level - 1 or _flash <= 0.0 or not on else EMBER_HOT.lerp(Color.WHITE, _flash), a))
		if on:
			_shadowed(BODY_FONT, Vector2(LEFT, y + 16), row[2], 14, Color(ASH, a))
	# Right: the purse and what this level buys.
	var right := s.x - 90.0
	var w := 300.0
	var can := player.echoes >= cost
	_canvas.draw_circle(Vector2(right - 8, TOP - 78), 6.0, Color(ECHO, 0.3 * a))
	_canvas.draw_circle(Vector2(right - 8, TOP - 78), 2.5, Color(0.9, 0.97, 1.0, a))
	_shadowed(TITLE_FONT, Vector2(right - w - 22, TOP - 70), str(player.echoes), 26, Color(ECHO, a), HORIZONTAL_ALIGNMENT_RIGHT, w)
	_shadowed(BODY_FONT, Vector2(right - w, TOP - 50), "Echoes carried", 14, Color(ASH_DIM, a), HORIZONTAL_ALIGNMENT_RIGHT, w)
	_canvas.draw_rect(Rect2(right - 160, TOP - 38, 160, 1), Color(EMBER, 0.6 * a))
	var cost_col := (EMBER_HOT if can else Color(0.8, 0.35, 0.3)).lerp(Color(1.0, 0.3, 0.25), _refuse)
	_shadowed(TITLE_FONT, Vector2(right - w, TOP - 8), "NEXT LEVEL COSTS", 11, Color(ASH_DIM, a), HORIZONTAL_ALIGNMENT_RIGHT, w)
	_shadowed(TITLE_FONT, Vector2(right - w, TOP + 20), "%d Echoes" % cost, 22, Color(cost_col, a), HORIZONTAL_ALIGNMENT_RIGHT, w)
	if not can:
		_shadowed(BODY_FONT, Vector2(right - w, TOP + 42), "Not enough yet. The Hollowed carry more.", 14, Color(ASH_DIM, a), HORIZONTAL_ALIGNMENT_RIGHT, w)
	var y2 := TOP + 84.0
	for line: Array in player.stat_lines():
		_shadowed(BODY_FONT, Vector2(right - w, y2), line[0], 15, Color(ASH_DIM, a), HORIZONTAL_ALIGNMENT_LEFT, w)
		_shadowed(MENU_FONT, Vector2(right - w, y2), line[1], 16, Color(ASH, a), HORIZONTAL_ALIGNMENT_RIGHT, w)
		y2 += 22.0
	_shadowed(BODY_FONT, Vector2(LEFT, s.y - 40), "Up / Down  choose     Enter  kindle     Esc  rise from the fire", 14, Color(ASH_DIM, a))


func _shadowed(font: Font, at: Vector2, t: String, sz: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0) -> void:
	_canvas.draw_string(font, at + Vector2(1, 1), t, align, w, sz, Color(0, 0, 0, 0.85 * col.a))
	_canvas.draw_string(font, at, t, align, w, sz, col)
