class_name Hud
extends CanvasLayer
## In-game HUD, "ember and iron": the HUD is the Unlaid's lantern and little else.
##   top-left:     the lantern emblem (its glow is your Ember Flask; the number is sips
##                 left) beside straight iron-banded HP and stamina bars whose length
##                 grows with their maximum
##   top-right:    the current objective, right-aligned, no box; flares when it changes
##   lower centre: prompts (keys drawn as iron caps) and the lore whisper above them
##   bottom:       boss name and bar, souls-style
## Nothing is drawn for systems the player doesn't have yet (no empty spell slots).
## Event-driven: values arrive by signal, the canvas only redraws them.

const ASH := Color(0.91, 0.88, 0.82)
const ASH_DIM := Color(0.62, 0.58, 0.54)
const EMBER := Color(1.0, 0.62, 0.25)
const EMBER_HOT := Color(1.0, 0.86, 0.55)
const IRON := Color(0.09, 0.08, 0.09, 0.9)
const IRON_EDGE := Color(0.36, 0.32, 0.31)
const BLOOD := Color(0.72, 0.15, 0.13)
const BLOOD_HI := Color(0.93, 0.33, 0.24)
const BONE := Color(0.84, 0.79, 0.62)
const TITLE_FONT: Font = preload("res://assets/fonts/Cinzel.ttf")
const BODY_FONT: Font = preload("res://assets/fonts/Alegreya.ttf")
const PIXEL_FONT: Font = preload("res://assets/fonts/PixelifySans.ttf")
const LORE_SECONDS: float = 6.0
const PX_PER_POINT: float = 1.5  ## bar length per point of max HP / stamina
const EMBLEM := Vector2(30, 36)

var _player: Player
var _hp: float = 1.0
var _hp_max: float = 1.0
var _hp_chip: float = 1.0
var _hp_flash: float = 0.0
var _stamina: float = 1.0
var _stamina_max: float = 1.0
var _exhausted: bool = false
var _flasks: int = 0
var _flasks_max: int = 0
var _flask_flash: float = 0.0
var _echo_pop: float = 0.0
var _t: float = 0.0
var _canvas: Control

var _quest_title: String = ""
var _quest_step: String = ""
var _quest_flare: float = 0.0

var _lore: Label
var _lore_left: float = 0.0
var _tip_text: String = ""
var _tip_alpha: float = 0.0
var _key_regex := RegEx.create_from_string("\\[([^\\]]+)\\]")

var _banner_text: String = ""
var _banner_t: float = -1.0
var _complete_text: String = ""
var _complete_t: float = -1.0
const BANNER_SECONDS: float = 4.0

var _boss: Enemy
var _boss_label: String = ""
var _boss_hp: float = 1.0
var _boss_max: float = 1.0
var _boss_chip: float = 1.0

var _toast_kind: String = ""
var _toast_text: String = ""
var _toast_left: float = 0.0

var _card: Control


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS  # tutorial cards pause the game
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_hud)
	add_child(_canvas)
	_lore = _label(BODY_FONT, 17, ASH)
	_lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lore.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lore.modulate.a = 0.0
	QuestLog.quest_changed.connect(_on_quest_changed)
	EventBus.lore_shown.connect(show_lore)
	EventBus.tip_shown.connect(func(t: String) -> void:
		_tip_text = Keys.fmt(t)
		if t != "":
			_tip_alpha = 0.0
			AudioManager.sfx(&"ui_hover", -10.0, 0.0))
	EventBus.tutorial_card.connect(_show_card)
	EventBus.quest_completed.connect(func(title: String) -> void:
		_complete_text = title
		_complete_t = 0.0)
	EventBus.area_entered.connect(func(title: String) -> void:
		_banner_text = title
		_banner_t = 0.0)
	EventBus.boss_engaged.connect(_on_boss)
	EventBus.toast_shown.connect(func(kind: String, text: String) -> void:
		_toast_kind = kind.to_upper()
		_toast_text = text
		_toast_left = 3.5)
	_on_quest_changed(QuestLog.title, QuestLog.steps)
	get_viewport().size_changed.connect(_layout)
	_layout()


func bind(player: Player) -> void:
	_player = player
	player.stats.hp_changed.connect(func(v: float, m: float) -> void:
		if v < _hp:
			_hp_chip = maxf(_hp_chip, _hp)
			_hp_flash = 0.35
		_hp = v
		_hp_max = m)
	player.stats.stamina_changed.connect(func(v: float, m: float) -> void:
		_stamina = v
		_stamina_max = m)
	player.flasks_changed.connect(func(n: int, m: int) -> void:
		if n != _flasks:
			_flask_flash = 0.6
		_flasks = n
		_flasks_max = m)
	player.echoes_changed.connect(func(_total: int) -> void: _echo_pop = 1.0)
	_hp = player.stats.hp
	_hp_max = player.combat.max_hp
	_hp_chip = _hp
	_stamina = player.stats.stamina
	_stamina_max = player.combat.max_stamina
	_flasks = player.flasks
	_flasks_max = player.combat.flask_charges


func show_lore(text: String) -> void:
	_lore.text = text
	_lore_left = LORE_SECONDS
	_lore.reset_size()
	_layout()


func _on_quest_changed(title: String, steps: Array) -> void:
	var step := ""
	for s in steps:  # only the objective you're on; finished ones drop off
		if not s["done"]:
			step = s["text"]
			break
	if step != _quest_step and step != "":
		_quest_flare = 1.0
	_quest_title = title
	_quest_step = step


func _on_boss(boss: Node) -> void:
	_boss = boss as Enemy
	if _boss == null:
		return
	_boss_label = _boss.data.display_name
	_boss_max = _boss.data.max_hp
	_boss_hp = _boss.hp
	_boss_chip = _boss_hp
	_boss.health_changed.connect(func(v: float, m: float) -> void:
		_boss_chip = maxf(_boss_chip, _boss_hp)
		_boss_hp = v
		_boss_max = m
		if v <= 0.0:
			_boss = null)


func _process(delta: float) -> void:
	_t += delta
	_toast_left = maxf(0.0, _toast_left - delta)
	_hp_flash = maxf(0.0, _hp_flash - delta)
	_flask_flash = maxf(0.0, _flask_flash - delta)
	_echo_pop = maxf(0.0, _echo_pop - delta * 4.0)
	_quest_flare = maxf(0.0, _quest_flare - delta * 0.7)
	_tip_alpha = move_toward(_tip_alpha, 1.0 if _tip_text != "" else 0.0, delta * 4.0)
	_hp_chip = move_toward(_hp_chip, _hp, _hp_max * 0.5 * delta) if _hp_chip > _hp else _hp
	_boss_chip = move_toward(_boss_chip, _boss_hp, _boss_max * 0.3 * delta) if _boss_chip > _boss_hp else _boss_hp
	if _player:
		_exhausted = _player.stats.exhausted
	if _banner_t >= 0.0:
		_banner_t += delta
		if _banner_t > BANNER_SECONDS:
			_banner_t = -1.0
	if _complete_t >= 0.0:
		_complete_t += delta
		if _complete_t > BANNER_SECONDS:
			_complete_t = -1.0
	if _lore_left > 0.0:
		_lore_left -= delta
	_lore.modulate.a = clampf(minf(_lore_left, (LORE_SECONDS - _lore_left) * 3.0), 0.0, 1.0)
	_canvas.queue_redraw()


func _layout() -> void:
	var s := _canvas.get_viewport_rect().size
	_lore.size = Vector2(440, 0)
	_lore.reset_size()
	_lore.size.x = 440
	_lore.position = Vector2(s.x * 0.5 - 220, s.y - 150 - _lore.size.y)


func _label(font: Font, font_size: int, color: Color, add: bool = true) -> Label:
	var l := Label.new()
	l.add_theme_font_override(&"font", font)
	l.add_theme_font_size_override(&"font_size", font_size)
	l.add_theme_color_override(&"font_color", color)
	l.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override(&"shadow_offset_x", 1)
	l.add_theme_constant_override(&"shadow_offset_y", 1)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if add:
		_canvas.add_child(l)
	return l


# ---------------------------------------------------------------- tutorial card

## A one-time explainer for a new concept; pauses the game until dismissed.
## Styled as a page nailed to iron: dark warm panel, ember rule under the title.
func _show_card(id: StringName, title: String, body: String) -> void:
	var key := StringName("card_" + String(id))
	if GameState.flags.get(key, false) or _card:
		return
	GameState.flags[key] = true
	get_tree().paused = true
	AudioManager.sfx(&"pickup", -8.0, 0.0)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.06, 0.06, 0.97)
	style.border_color = IRON_EDGE
	style.set_border_width_all(1)
	style.border_width_top = 3
	style.set_content_margin_all(24)
	style.content_margin_top = 20
	style.shadow_color = Color(0, 0, 0, 0.75)
	style.shadow_size = 16
	panel.add_theme_stylebox_override(&"panel", style)
	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", 12)
	panel.add_child(v)
	var head := _label(TITLE_FONT, 22, EMBER_HOT, false)
	head.text = title.to_upper()
	v.add_child(head)
	var rule := Control.new()
	rule.custom_minimum_size = Vector2(0, 2)
	rule.draw.connect(func() -> void:
		rule.draw_rect(Rect2(0, 0, 90, 1), EMBER)
		rule.draw_rect(Rect2(94, 0, rule.size.x - 94, 1), Color(IRON_EDGE, 0.6)))
	v.add_child(rule)
	var text := _label(BODY_FONT, 17, ASH, false)
	text.text = Keys.fmt(body)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(440, 0)
	v.add_child(text)
	var foot := _label(PIXEL_FONT, 12, ASH_DIM, false)
	foot.text = Keys.fmt("{interact}  continue")
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(foot)
	_canvas.add_child(panel)
	panel.reset_size()
	panel.position = ((_canvas.get_viewport_rect().size - panel.size) * 0.5).round()
	panel.modulate.a = 0.0
	panel.create_tween().tween_property(panel, ^"modulate:a", 1.0, 0.18)
	# The iron corner of the page: a lit ember stud top-left.
	panel.draw.connect(func() -> void:
		panel.draw_rect(Rect2(-3, -3, 7, 7), IRON_EDGE)
		panel.draw_rect(Rect2(-1, -1, 3, 3), EMBER))
	_card = panel


func _unhandled_input(event: InputEvent) -> void:
	if _card and (event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"ui_cancel")):
		_card.queue_free()
		_card = null
		get_tree().paused = false
		AudioManager.sfx(&"ui_click", -6.0, 0.0)
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- drawing

func _draw_hud() -> void:
	var s := _canvas.get_viewport_rect().size
	_draw_vitals()
	_draw_objective(s)
	_draw_tip(s)
	_draw_toast()
	_draw_boss(s)
	_draw_banner(s)
	_draw_complete(s)
	if _lore.modulate.a > 0.0:
		var a := _lore.modulate.a
		var y := _lore.position.y - 8
		var cx := s.x * 0.5
		for i in 20:  # soft dark band so the whisper reads over lit floor
			var k := 1.0 - absf(i / 9.5 - 1.0)
			_canvas.draw_rect(Rect2(cx - 250 + i * 25, y + 4, 25, _lore.size.y + 8), Color(0.02, 0.02, 0.03, 0.6 * k * a))
		_canvas.draw_rect(Rect2(cx - 40, y, 32, 1), Color(EMBER, 0.7 * a))
		_canvas.draw_rect(Rect2(cx + 8, y, 32, 1), Color(EMBER, 0.7 * a))
		_canvas.draw_rect(Rect2(cx - 2, y - 2, 4, 4), Color(EMBER_HOT, a))


func _text(font: Font, at: Vector2, t: String, sz: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0) -> void:
	_canvas.draw_string(font, at + Vector2(1, 1), t, align, w, sz, Color(0, 0, 0, 0.85 * col.a))
	_canvas.draw_string(font, at, t, align, w, sz, col)


## The lantern emblem, then HP over stamina. Bars are straight and banded in iron,
## and their length tracks the maximum, so growing stronger is visible.
func _draw_vitals() -> void:
	var low := _hp > 0.0 and _hp / maxf(_hp_max, 1.0) < 0.25
	_draw_lantern(EMBLEM, low)
	var x := EMBLEM.x + 22.0
	var hp_w := _hp_max * PX_PER_POINT
	var hp_col := BLOOD.lerp(BLOOD_HI, 0.5 + 0.5 * sin(_t * 8.0)) if low else BLOOD
	_bar(Vector2(x, 22), hp_w, 9, _hp / maxf(_hp_max, 1.0), hp_col, _hp_chip / maxf(_hp_max, 1.0), _hp_flash > 0.0)
	var st_w := _stamina_max * PX_PER_POINT * 0.85
	var st_col := Color(0.55, 0.4, 0.3) if _exhausted else BONE
	_bar(Vector2(x, 36), st_w, 5, _stamina / maxf(_stamina_max, 1.0), st_col, 0.0, false)
	# The lantern's ember throw: a coal that dims while it rekindles. Only once you carry it.
	if _player and GameState.flags.get(&"has_cradle_lantern", false):
		var ready := 1.0 - clampf(_player.ember_cooldown / maxf(_player.ability_cooldown, 0.01), 0.0, 1.0)
		var c := Vector2(x + 6, 53)
		_canvas.draw_circle(c, 6.0, Color(0, 0, 0, 0.6))
		_canvas.draw_arc(c, 5.0, -PI / 2, -PI / 2 + TAU * ready, 16, EMBER if ready >= 1.0 else IRON_EDGE, 1.5)
		_canvas.draw_circle(c, 2.5, EMBER_HOT if ready >= 1.0 else Color(0.4, 0.22, 0.14))
		_text(PIXEL_FONT, c + Vector2(10, 4), Keys.label(&"spell_1"), 9, ASH_DIM)
	# Echoes carried: a pale mote and a count that jumps when one arrives.
	if _player and (_player.echoes > 0 or not _player.levels.is_empty()):
		var e := Vector2(x + 60, 53)
		_canvas.draw_circle(e, 5.0 + 2.0 * _echo_pop, Color(0.5, 0.8, 1.0, 0.3))
		_canvas.draw_circle(e, 2.2, Color(0.88, 0.97, 1.0))
		_text(PIXEL_FONT, e + Vector2(9, 4 - 2.0 * _echo_pop), str(_player.echoes), 12, Color(0.72, 0.9, 1.0).lerp(Color.WHITE, _echo_pop))


func _bar(at: Vector2, w: float, h: float, k: float, col: Color, chip: float, flash: bool) -> void:
	at = at.round()
	_canvas.draw_rect(Rect2(at - Vector2(2, 2), Vector2(w + 4, h + 4)), Color(0, 0, 0, 0.6))
	_canvas.draw_rect(Rect2(at - Vector2(1, 1), Vector2(w + 2, h + 2)), IRON_EDGE)
	_canvas.draw_rect(Rect2(at, Vector2(w, h)), IRON)
	if chip > k:
		_canvas.draw_rect(Rect2(at + Vector2(w * k, 0), Vector2(w * (chip - k), h)), Color(EMBER_HOT, 0.85))
	if k > 0.0:
		var fw := w * clampf(k, 0.0, 1.0)
		_canvas.draw_rect(Rect2(at, Vector2(fw, h)), ASH if flash else col)
		_canvas.draw_rect(Rect2(at, Vector2(fw, 1)), col.lightened(0.35))
		_canvas.draw_rect(Rect2(at + Vector2(0, h - 1), Vector2(fw, 1)), col.darkened(0.35))
	# Iron bands every 50 points: a reading aid, like ruler ticks.
	var step := 50.0 * PX_PER_POINT * (w / maxf(w, 1.0))
	var bx := step
	while bx < w - 2.0:
		_canvas.draw_rect(Rect2(at + Vector2(bx, 0), Vector2(1, h)), Color(0, 0, 0, 0.45))
		bx += step
	# End rivet.
	_canvas.draw_rect(Rect2(at + Vector2(w + 1, h * 0.5 - 2), Vector2(3, 4)), IRON_EDGE)


## A small iron lantern. Its flame is the Ember Flask: bright when full, guttering as
## sips are spent, dark when empty. Low HP makes the glass beat red.
func _draw_lantern(c: Vector2, low: bool) -> void:
	var k := float(_flasks) / maxf(_flasks_max, 1.0)
	var flick := 0.88 + 0.12 * sin(_t * 11.0) * sin(_t * 6.7)
	var glow := k * flick + _flask_flash
	if glow > 0.0:
		_canvas.draw_circle(c, 24.0, Color(1.0, 0.55, 0.2, 0.07 * glow))
		_canvas.draw_circle(c, 14.0, Color(1.0, 0.6, 0.25, 0.12 * glow))
	var iron := Color(0.3, 0.27, 0.27)
	_canvas.draw_line(c + Vector2(0, -21), c + Vector2(0, -16), iron, 2.0)
	_canvas.draw_arc(c + Vector2(0, -14), 4, PI, TAU, 8, iron, 2.0)
	var body := Rect2(c + Vector2(-9, -12), Vector2(18, 24))
	_canvas.draw_rect(body.grow(2), Color(0.04, 0.03, 0.04))
	var glass := Color(0.1, 0.07, 0.06).lerp(Color(1.0, 0.68, 0.3), clampf(glow, 0.0, 1.0))
	if low:
		glass = glass.lerp(BLOOD_HI, 0.35 + 0.35 * sin(_t * 8.0))
	_canvas.draw_rect(body, Color(0.2, 0.15, 0.11))
	_canvas.draw_rect(Rect2(body.position + Vector2(3, 3), body.size - Vector2(6, 6)), glass)
	if _flasks > 0:
		var fh := 3.0 + 5.0 * k
		_canvas.draw_rect(Rect2(c + Vector2(-2, 6 - fh) , Vector2(4, fh) * Vector2(1, flick)), EMBER_HOT)
	for dx in [0, 16]:
		_canvas.draw_rect(Rect2(body.position + Vector2(dx, 0), Vector2(2, body.size.y)), iron)
	_canvas.draw_rect(Rect2(body.position + Vector2(-2, -3), Vector2(body.size.x + 4, 3)), iron)
	_canvas.draw_rect(Rect2(body.position + Vector2(-2, body.size.y), Vector2(body.size.x + 4, 3)), iron)
	# Sips left, stamped on the base plate.
	var n := str(_flasks)
	_text(PIXEL_FONT, c + Vector2(6, 25), n, 12, EMBER_HOT if _flasks > 0 else ASH_DIM)
	if _player:
		_text(PIXEL_FONT, c + Vector2(-13, 25), Keys.label(&"heal"), 9, ASH_DIM)


## The current objective, right-aligned under a quiet quest title. When it changes it
## arrives ember-hot and cools.
func _draw_objective(s: Vector2) -> void:
	if _quest_step == "":
		return
	var right := s.x - 20.0
	var w := 260.0
	_text(TITLE_FONT, Vector2(right - w, 26), _quest_title.to_upper(), 11, Color(ASH_DIM, 0.95), HORIZONTAL_ALIGNMENT_RIGHT, w)
	var lines := _wrap(_quest_step, BODY_FONT, 16, w - 14.0)
	var y := 46.0
	var col := ASH.lerp(EMBER_HOT, _quest_flare)
	for line in lines:
		_text(BODY_FONT, Vector2(right - w - 12, y), line, 16, col, HORIZONTAL_ALIGNMENT_RIGHT, w)
		y += 19.0
	# A thin ember rule on the right edge, flame-tipped.
	_canvas.draw_rect(Rect2(right + 2, 16, 1, y - 26), Color(EMBER, 0.55 + 0.45 * _quest_flare))
	_canvas.draw_rect(Rect2(right + 1, 13, 3, 3), EMBER_HOT)


func _wrap(t: String, font: Font, sz: int, w: float) -> PackedStringArray:
	var out := PackedStringArray()
	var line := ""
	for word in t.split(" "):
		var trial := word if line == "" else line + " " + word
		if line != "" and font.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > w:
			out.append(line)
			line = word
		else:
			line = trial
	if line != "":
		out.append(line)
	return out


## Prompts sit low and centred on a soft dark band; [Key] tokens become iron key caps.
func _draw_tip(s: Vector2) -> void:
	if _tip_alpha <= 0.0 or _tip_text == "":
		return
	var lines := _tip_text.split("\n")
	var y := s.y - 96.0 - (lines.size() - 1) * 24.0
	var band_h := lines.size() * 24.0 + 12.0
	for i in 24:  # band fading out to both sides
		var k := 1.0 - absf(i / 11.5 - 1.0)
		_canvas.draw_rect(Rect2(s.x * 0.5 - 300 + i * 25, y - 18, 25, band_h), Color(0.02, 0.02, 0.03, 0.55 * k * _tip_alpha))
	for line in lines:
		var w := _line_width(line)
		var x := s.x * 0.5 - w * 0.5
		var last := 0
		for m in _key_regex.search_all(line):
			x = _tip_text_part(line.substr(last, m.get_start() - last), x, y)
			x = _tip_key(m.get_string(1), x, y)
			last = m.get_end()
		_tip_text_part(line.substr(last), x, y)
		y += 24.0


func _line_width(line: String) -> float:
	var w := 0.0
	var last := 0
	for m in _key_regex.search_all(line):
		w += BODY_FONT.get_string_size(line.substr(last, m.get_start() - last), HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		w += _key_w(m.get_string(1)) + 6.0
		last = m.get_end()
	return w + BODY_FONT.get_string_size(line.substr(last), HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x


func _tip_text_part(t: String, x: float, y: float) -> float:
	if t == "":
		return x
	_text(BODY_FONT, Vector2(x, y), t, 16, Color(ASH, _tip_alpha))
	return x + BODY_FONT.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x


func _key_w(k: String) -> float:
	return maxf(18.0, PIXEL_FONT.get_string_size(k, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 10.0)


func _tip_key(k: String, x: float, y: float) -> float:
	var w := _key_w(k)
	var r := Rect2(round(x + 3), y - 14, w, 18)
	_canvas.draw_rect(r.grow(1), Color(IRON_EDGE, _tip_alpha))
	_canvas.draw_rect(r, Color(0.14, 0.12, 0.12, _tip_alpha))
	_canvas.draw_rect(Rect2(r.position, Vector2(w, 1)), Color(EMBER, 0.8 * _tip_alpha))
	_canvas.draw_string(PIXEL_FONT, Vector2(r.position.x, y), k, HORIZONTAL_ALIGNMENT_CENTER, w, 12, Color(EMBER_HOT, _tip_alpha))
	return x + w + 9.0


func _draw_toast() -> void:
	if _toast_left <= 0.0:
		return
	var a := clampf(_toast_left / 0.6, 0.0, 1.0) * clampf((3.5 - _toast_left) * 6.0, 0.0, 1.0)
	var at := Vector2(20, 72)
	_canvas.draw_rect(Rect2(at + Vector2(0, -2), Vector2(2, 30)), Color(EMBER, a))
	_text(TITLE_FONT, at + Vector2(10, 9), _toast_kind, 10, Color(EMBER, a))
	_text(BODY_FONT, at + Vector2(10, 25), _toast_text, 15, Color(ASH, a))


## Souls convention: the boss's name and a long bar along the bottom of the screen.
func _draw_boss(s: Vector2) -> void:
	if _boss == null or not is_instance_valid(_boss):
		return
	var w := minf(560.0, s.x - 120.0)
	var at := Vector2(s.x * 0.5 - w * 0.5, s.y - 34)
	_text(TITLE_FONT, at + Vector2(0, -8), _boss_label, 15, ASH)
	_bar(at, w, 7, _boss_hp / maxf(_boss_max, 1.0), Color(0.62, 0.12, 0.11), _boss_chip / maxf(_boss_max, 1.0), false)


## Area title: name in relic capitals, ember rules drawing outward from the middle.
func _draw_banner(s: Vector2) -> void:
	if _banner_t < 0.0:
		return
	var a := clampf(minf(_banner_t * 1.5, (BANNER_SECONDS - _banner_t) * 1.0), 0.0, 1.0)
	var y := s.y * 0.26
	var t := _banner_text.to_upper()
	_text(TITLE_FONT, Vector2(0, y), t, 28, Color(ASH, a), HORIZONTAL_ALIGNMENT_CENTER, s.x)
	var half := TITLE_FONT.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x * 0.5 * clampf(_banner_t * 1.2, 0.0, 1.0)
	_canvas.draw_rect(Rect2(s.x * 0.5 - half, y + 10, half * 2.0, 1), Color(EMBER, 0.8 * a))


func _draw_complete(s: Vector2) -> void:
	if _complete_t < 0.0:
		return
	var a := clampf(minf(_complete_t * 2.0, (BANNER_SECONDS - _complete_t) * 1.2), 0.0, 1.0)
	var y := s.y * 0.3
	var cx := s.x * 0.5
	var flick := 0.85 + 0.15 * sin(_t * 12.0)
	_canvas.draw_circle(Vector2(cx, y - 34), 18 * flick, Color(1.0, 0.6, 0.25, 0.12 * a))
	_canvas.draw_rect(Rect2(cx - 2, y - 40, 4, 8 * flick), Color(EMBER_HOT, a))
	_text(TITLE_FONT, Vector2(0, y), "QUEST COMPLETE", 30, Color(EMBER_HOT.lerp(ASH, clampf(_complete_t, 0.0, 1.0)), a), HORIZONTAL_ALIGNMENT_CENTER, s.x)
	var half := 150.0 * clampf(_complete_t * 1.5, 0.0, 1.0)
	_canvas.draw_rect(Rect2(cx - half, y + 10, half * 2.0, 1), Color(EMBER, 0.8 * a))
	_text(BODY_FONT, Vector2(0, y + 30), _complete_text, 16, Color(ASH_DIM, a), HORIZONTAL_ALIGNMENT_CENTER, s.x)
