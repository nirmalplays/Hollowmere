class_name Hud
extends CanvasLayer
## In-game HUD in the reference's layout (docs/ART_DIRECTION.md), our own art:
##   bottom-left:  diamond quick slots (1-4), XP, slanted stamina + mana bars over a big HP bar
##   bottom-right: diamond ability bar (spells 1-5 arrive in M5; weapon slot shows now)
##   right:        quest tracker (serif title, diamond bullets)
##   top-centre:   lore text box for inscriptions and pages ("A journal page reads...")
## Event-driven: everything updates from signals, never by polling.

const GOLD := Color(0.85, 0.66, 0.32)
const GOLD_DARK := Color(0.42, 0.28, 0.12)
const SLOT_FILL := Color(0.2, 0.13, 0.08, 0.88)
const HP_A := Color(0.98, 0.42, 0.16)
const HP_B := Color(0.97, 0.66, 0.24)
const STAMINA := Color(0.98, 0.86, 0.3)
const MANA := Color(0.42, 0.78, 0.36)
const TITLE_FONT: Font = preload("res://assets/fonts/Cinzel.ttf")
const BODY_FONT: Font = preload("res://assets/fonts/Alegreya.ttf")
const LORE_SECONDS: float = 6.0

var _player: Player
var _hp: float = 1.0
var _hp_max: float = 1.0
var _hp_chip: float = 1.0
var _stamina: float = 1.0
var _stamina_max: float = 1.0
var _canvas: Control
var _xp: Label
var _quest_title: Label
var _quest_steps: VBoxContainer
var _lore: Label
var _lore_box: Control
var _lore_left: float = 0.0
var _tips: Label
var _banner: Label
var _boss: Enemy
var _boss_name: Label
var _boss_hp: float = 1.0
var _boss_max: float = 1.0
var _toast_kind: Label
var _toast_text: Label
var _toast_left: float = 0.0
var _tip_text: String = ""
var _key_regex := RegEx.create_from_string("\\[([^\\]]+)\\]")
var _card: Control
var _complete: Control


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS  # tutorial cards pause the game
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_hud)
	add_child(_canvas)
	_xp = _label(TITLE_FONT, 15, Color(0.98, 0.95, 0.88))
	_xp.text = "XP: 0"
	_build_quest_tracker()
	_build_lore_box()
	_tips = _label(BODY_FONT, 15, Color(0.95, 0.93, 0.86))
	_tips.custom_minimum_size = Vector2(360, 0)
	_banner = _label(TITLE_FONT, 34, Color(0.98, 0.95, 0.88))
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.modulate.a = 0.0
	_boss_name = _label(TITLE_FONT, 18, Color(0.98, 0.95, 0.88))
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_name.visible = false
	_toast_kind = _label(TITLE_FONT, 13, GOLD)
	_toast_text = _label(BODY_FONT, 14, Color(0.9, 0.9, 0.86))
	_toast_kind.modulate.a = 0.0
	_toast_text.modulate.a = 0.0
	QuestLog.quest_changed.connect(_on_quest_changed)
	EventBus.lore_shown.connect(show_lore)
	_tips.visible = false
	EventBus.tip_shown.connect(func(t: String) -> void:
		_tip_text = t
		if t != "":
			AudioManager.sfx(&"ui_move", -10.0, 0.0))
	EventBus.tutorial_card.connect(_show_card)
	EventBus.quest_completed.connect(_show_quest_complete)
	EventBus.area_entered.connect(_show_banner)
	EventBus.boss_engaged.connect(_on_boss)
	EventBus.toast_shown.connect(_show_toast)
	_on_quest_changed(QuestLog.title, QuestLog.steps)
	get_viewport().size_changed.connect(_layout)
	_layout()


func bind(player: Player) -> void:
	_player = player
	player.stats.hp_changed.connect(func(v: float, m: float) -> void:
		if v < _hp:
			_hp_chip = maxf(_hp_chip, _hp)
		_hp = v
		_hp_max = m)
	player.stats.stamina_changed.connect(func(v: float, m: float) -> void:
		_stamina = v
		_stamina_max = m)
	_hp = player.stats.hp
	_hp_max = player.combat.max_hp
	_hp_chip = _hp
	_stamina = player.stats.stamina
	_stamina_max = player.combat.max_stamina


func show_lore(text: String) -> void:
	_lore.text = text
	_lore_left = LORE_SECONDS
	_lore_box.modulate.a = 1.0
	_lore_box.visible = true


## Top-left tutorial prompts in the reference style: a diamond per line and keys drawn
## as caps. Write keys in brackets: "Move with [W][A][S][D]".
func _draw_tips() -> void:
	if _tip_text == "":
		return
	var lines := _tip_text.split("\n")
	_canvas.draw_rect(Rect2(10, 10, 430, lines.size() * 26 + 12), Color(0.02, 0.03, 0.06, 0.62))
	var y := 34.0
	for line in lines:
		var p := Vector2(24, y - 5)
		var d := PackedVector2Array([p + Vector2(0, -5), p + Vector2(5, 0), p + Vector2(0, 5), p + Vector2(-5, 0), p + Vector2(0, -5)])
		_canvas.draw_polyline(d, GOLD, 1.5)
		var x := 38.0
		var last := 0
		for m in _key_regex.search_all(line):
			x = _tip_text_part(line.substr(last, m.get_start() - last), x, y)
			x = _tip_key(m.get_string(1), x, y)
			last = m.get_end()
		_tip_text_part(line.substr(last), x, y)
		y += 26.0


func _tip_text_part(t: String, x: float, y: float) -> float:
	if t == "":
		return x
	_canvas.draw_string(BODY_FONT, Vector2(x, y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.96, 0.94, 0.88))
	return x + BODY_FONT.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x


func _tip_key(k: String, x: float, y: float) -> float:
	var w := maxf(20.0, TITLE_FONT.get_string_size(k, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 10.0)
	var r := Rect2(x + 2, y - 15, w, 19)
	_canvas.draw_rect(r, Color(0.95, 0.94, 0.9))
	_canvas.draw_rect(Rect2(r.position + Vector2(0, 17), Vector2(w, 2)), Color(0.55, 0.52, 0.5))
	_canvas.draw_string(TITLE_FONT, Vector2(x + 7, y), k, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.15, 0.12, 0.2))
	return x + w + 6.0


## A one-time explainer for a new concept; pauses the game until dismissed.
func _show_card(id: StringName, title: String, body: String) -> void:
	var key := StringName("card_" + String(id))
	if GameState.flags.get(key, false) or _card:
		return
	GameState.flags[key] = true
	get_tree().paused = true
	AudioManager.sfx(&"pickup", -8.0, 0.0)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.06, 0.1, 0.96)
	style.border_color = Color(0.45, 0.62, 0.85)
	style.set_border_width_all(2)
	style.set_content_margin_all(26)
	style.shadow_color = Color(0, 0, 0, 0.7)
	style.shadow_size = 12
	panel.add_theme_stylebox_override(&"panel", style)
	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", 14)
	panel.add_child(v)
	var head := _label(TITLE_FONT, 26, Color(0.98, 0.95, 0.88), false)
	head.text = title
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(head)
	var text := _label(BODY_FONT, 18, Color(0.9, 0.9, 0.86), false)
	text.text = body
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(480, 0)
	v.add_child(text)
	var foot := _label(TITLE_FONT, 13, GOLD, false)
	foot.text = "Press  E  or  Enter  to continue"
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(foot)
	_canvas.add_child(panel)
	panel.reset_size()
	panel.position = (_canvas.get_viewport_rect().size - panel.size) * 0.5
	_card = panel


func _unhandled_input(event: InputEvent) -> void:
	if _card and (event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"ui_cancel")):
		_card.queue_free()
		_card = null
		get_tree().paused = false
		AudioManager.sfx(&"ui_select", -6.0, 0.0)
		get_viewport().set_input_as_handled()


func _show_quest_complete(title: String) -> void:
	if _complete:
		_complete.queue_free()
	var s := _canvas.get_viewport_rect().size
	var box := Control.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.position = Vector2(0, s.y * 0.2)
	box.size = Vector2(s.x, 90)
	box.draw.connect(func() -> void:
		for i in 40:
			var k := absf(i / 20.0 - 1.0)
			box.draw_rect(Rect2(s.x * 0.5 - 300 + i * 15, 6, 15, 70), Color(0.2, 0.38, 0.75, 0.45 * (1.0 - k))))
	var head := _label(TITLE_FONT, 40, Color(0.99, 0.96, 0.88), false)
	head.text = "QUEST COMPLETE!"
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.size = Vector2(s.x, 50)
	box.add_child(head)
	var sub := _label(BODY_FONT, 16, Color(0.8, 0.85, 0.95), false)
	sub.text = title.to_upper()
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(s.x, 20)
	sub.position = Vector2(0, 50)
	box.add_child(sub)
	_canvas.add_child(box)
	_complete = box
	box.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(box, ^"modulate:a", 1.0, 0.4)
	tw.tween_interval(3.0)
	tw.tween_property(box, ^"modulate:a", 0.0, 0.8)
	tw.tween_callback(box.queue_free)


func _show_banner(title: String) -> void:
	_banner.text = title.to_upper()
	var tw := create_tween()
	tw.tween_property(_banner, ^"modulate:a", 1.0, 0.6)
	tw.tween_interval(2.4)
	tw.tween_property(_banner, ^"modulate:a", 0.0, 1.0)


func _show_toast(kind: String, text: String) -> void:
	_toast_kind.text = kind.to_upper()
	_toast_text.text = text
	_toast_left = 3.5
	_toast_kind.modulate.a = 1.0
	_toast_text.modulate.a = 1.0


func _on_boss(boss: Node) -> void:
	_boss = boss as Enemy
	if _boss == null:
		return
	_boss_name.text = _boss.data.display_name.to_upper()
	_boss_name.visible = true
	_boss_max = _boss.data.max_hp
	_boss_hp = _boss.hp
	_boss.health_changed.connect(func(v: float, m: float) -> void:
		_boss_hp = v
		_boss_max = m
		if v <= 0.0:
			_boss_name.visible = false)


func _process(delta: float) -> void:
	if _toast_left > 0.0:
		_toast_left -= delta
		if _toast_left < 0.6:
			_toast_kind.modulate.a = maxf(_toast_left / 0.6, 0.0)
			_toast_text.modulate.a = _toast_kind.modulate.a
	_hp_chip = move_toward(_hp_chip, _hp, _hp_max * 0.6 * delta) if _hp_chip > _hp else _hp
	if _lore_left > 0.0:
		_lore_left -= delta
		if _lore_left < 1.0:
			_lore_box.modulate.a = maxf(_lore_left, 0.0)
		if _lore_left <= 0.0:
			_lore_box.visible = false
	_canvas.queue_redraw()


# ---------------------------------------------------------------- layout

func _layout() -> void:
	var s := _canvas.get_viewport_rect().size
	_xp.position = Vector2(100, s.y - 92)
	_quest_title.position = Vector2(s.x - 250, 150)
	_quest_steps.position = Vector2(s.x - 250, 186)
	_lore_box.position = Vector2(s.x * 0.5 - 200, s.y - 190)  # lower centre, clear of the tracker
	_tips.position = Vector2(22, 18)
	_banner.size = Vector2(s.x, 44)
	_banner.position = Vector2(0, 92)
	_boss_name.size = Vector2(s.x, 24)
	_boss_name.position = Vector2(0, 14)
	_toast_kind.position = Vector2(s.x - 230, 108)
	_toast_text.position = Vector2(s.x - 230, 126)


func _build_quest_tracker() -> void:
	_quest_title = _label(TITLE_FONT, 22, Color(0.98, 0.95, 0.88))
	_quest_title.size = Vector2(240, 30)
	_quest_steps = VBoxContainer.new()
	_quest_steps.add_theme_constant_override(&"separation", 6)
	_quest_steps.size = Vector2(240, 0)
	_canvas.add_child(_quest_steps)


func _on_quest_changed(title: String, steps: Array) -> void:
	_quest_title.text = title
	for c in _quest_steps.get_children():
		c.queue_free()
	# Like the reference: only the objective you're on (finished ones drop off).
	var shown: Array = []
	for step in steps:
		if not step["done"]:
			shown.append(step)
			break
	for step in shown:
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 8)
		var bullet := Control.new()
		bullet.custom_minimum_size = Vector2(12, 16)
		bullet.draw.connect(_draw_bullet.bind(bullet, step["done"]))
		row.add_child(bullet)
		var text := _label(BODY_FONT, 16, Color(0.55, 0.55, 0.5) if step["done"] else Color(0.96, 0.93, 0.86), false)
		text.text = step["text"]
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.custom_minimum_size = Vector2(218, 0)
		row.add_child(text)
		_quest_steps.add_child(row)


func _draw_bullet(c: Control, done: bool) -> void:
	var p := Vector2(6, 9)
	var pts := PackedVector2Array([p + Vector2(0, -5), p + Vector2(5, 0), p + Vector2(0, 5), p + Vector2(-5, 0), p + Vector2(0, -5)])
	if done:
		c.draw_colored_polygon(pts, GOLD)
	c.draw_polyline(pts, GOLD, 1.5, true)


func _build_lore_box() -> void:
	_lore_box = Control.new()
	_lore_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lore_box.visible = false
	_lore_box.draw.connect(func() -> void:
		var w := 400.0
		_lore_box.draw_rect(Rect2(-12, -8, w + 24, _lore.size.y + 22), Color(0.04, 0.05, 0.08, 0.72))
		var y := _lore.size.y + 10
		_lore_box.draw_line(Vector2(w * 0.35, y), Vector2(w + 6, y), Color(0.45, 0.62, 0.85, 0.8), 1.5)
		_lore_box.draw_arc(Vector2(w + 6, y - 6), 6, -PI / 2, PI / 2, 10, Color(0.45, 0.62, 0.85, 0.8), 1.5))
	_canvas.add_child(_lore_box)
	_lore = _label(BODY_FONT, 17, Color(0.97, 0.95, 0.9), false)
	_lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lore.custom_minimum_size = Vector2(400, 0)
	_lore.size = Vector2(400, 0)
	_lore_box.add_child(_lore)


func _label(font: Font, font_size: int, color: Color, add: bool = true) -> Label:
	var l := Label.new()
	l.add_theme_font_override(&"font", font)
	l.add_theme_font_size_override(&"font_size", font_size)
	l.add_theme_color_override(&"font_color", color)
	l.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override(&"shadow_offset_x", 1)
	l.add_theme_constant_override(&"shadow_offset_y", 2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if add:
		_canvas.add_child(l)
	return l


# ---------------------------------------------------------------- drawing

func _draw_hud() -> void:
	var s := _canvas.get_viewport_rect().size
	# Boss bar: a long bar under the boss's name at the top of the screen.
	if _boss_name.visible:
		var w := 420.0
		var at := Vector2(s.x * 0.5 - w * 0.5, 42)
		_canvas.draw_rect(Rect2(at - Vector2(2, 2), Vector2(w + 4, 12)), GOLD_DARK)
		_canvas.draw_rect(Rect2(at, Vector2(w, 8)), Color(0.08, 0.05, 0.05))
		_canvas.draw_rect(Rect2(at, Vector2(w * clampf(_boss_hp / maxf(_boss_max, 1.0), 0.0, 1.0), 8)), Color(0.78, 0.16, 0.12))
		_canvas.draw_line(at, at + Vector2(w * clampf(_boss_hp / maxf(_boss_max, 1.0), 0.0, 1.0), 0), Color(1.0, 0.45, 0.35), 1.0)
	_draw_tips()
	if _toast_left > 0.0:
		_canvas.draw_rect(Rect2(_toast_kind.position - Vector2(10, 6), Vector2(220, 42)), Color(0.04, 0.05, 0.08, 0.7 * _toast_kind.modulate.a))
	# Quick slots: a diamond cluster bottom-left (1 top, 2 left, 3 right, 4 bottom).
	var c := Vector2(52, s.y - 52)
	for i in 4:
		var off: Vector2 = [Vector2(0, -26), Vector2(-26, 0), Vector2(26, 0), Vector2(0, 26)][i]
		_diamond(c + off, 18.0, str(i + 1))
	# Bars: stamina and mana slanted above the long HP bar.
	var x0 := 100.0
	var y0 := s.y - 64.0
	_slant_bar(Vector2(x0, y0), 150.0, 6.0, _stamina / maxf(_stamina_max, 1.0), STAMINA, STAMINA.darkened(0.3), 0.0)
	_slant_bar(Vector2(x0 - 6, y0 + 10), 156.0, 6.0, 1.0, MANA, MANA.darkened(0.3), 0.0)
	_cap(Vector2(x0 + 156, y0 + 3))
	_slant_bar(Vector2(x0 - 22, y0 + 24), 260.0, 18.0, _hp / maxf(_hp_max, 1.0), HP_A, HP_B, _hp_chip / maxf(_hp_max, 1.0))
	# Ability bar: a diagonal of diamonds bottom-right (weapon, then spell slots).
	var b := Vector2(s.x - 40, s.y - 186)
	var keys := ["", "5", "4", "3", "2", "1"]
	for i in keys.size():
		var p := b + Vector2(-26, 26) * i
		_diamond(p, 20.0 if i == 0 else 16.0, keys[i], i == 0)


func _diamond(center: Vector2, r: float, key: String, weapon: bool = false) -> void:
	var pts := PackedVector2Array([center + Vector2(0, -r), center + Vector2(r, 0), center + Vector2(0, r), center + Vector2(-r, 0)])
	_canvas.draw_colored_polygon(pts, SLOT_FILL)
	pts.append(pts[0])
	_canvas.draw_polyline(pts, GOLD_DARK, 4.0)
	_canvas.draw_polyline(pts, GOLD, 2.0)
	if weapon:
		# A short sword icon for the equipped weapon.
		_canvas.draw_line(center + Vector2(-8, 8), center + Vector2(8, -8), Color(0.88, 0.9, 0.95), 3.0)
		_canvas.draw_line(center + Vector2(-9, 3), center + Vector2(-3, 9), GOLD, 2.0)
	if key != "":
		_canvas.draw_string(TITLE_FONT, center + Vector2(-4, r - 2), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.96, 0.9, 0.75))


## A parallelogram bar leaning right, filled `k` (0..1), with a pale chip trailing losses.
func _slant_bar(at: Vector2, w: float, h: float, k: float, a: Color, b: Color, chip: float) -> void:
	var lean := h * 0.8
	var frame := PackedVector2Array([at + Vector2(lean, 0), at + Vector2(w + lean, 0), at + Vector2(w, h), at + Vector2(0, h)])
	_canvas.draw_colored_polygon(frame, Color(0.08, 0.06, 0.06, 0.85))
	if chip > k:
		_canvas.draw_colored_polygon(_slant_fill(at, w * chip, h, lean), Color(0.98, 0.9, 0.72, 0.9))
	if k > 0.0:
		var fill := _slant_fill(at, w * clampf(k, 0.0, 1.0), h, lean)
		_canvas.draw_polygon(fill, PackedColorArray([b, a, a, b]))
		_canvas.draw_line(fill[0], fill[1], a.lightened(0.35), 1.0)
	frame.append(frame[0])
	_canvas.draw_polyline(frame, GOLD_DARK, 1.5)


func _slant_fill(at: Vector2, w: float, h: float, lean: float) -> PackedVector2Array:
	return PackedVector2Array([at + Vector2(lean, 0), at + Vector2(w + lean, 0), at + Vector2(w, h), at + Vector2(0, h)])


func _cap(at: Vector2) -> void:
	_canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -6), at + Vector2(14, -6), at + Vector2(6, 6)]), GOLD)
