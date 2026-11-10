class_name Hud
extends CanvasLayer
## Player HUD (GAME_PLAN 11.5). M2: HP and stamina. Mana, spell bar, buffs come in M3/M5.
## Event-driven: bars update from the player's stat signals, never by polling.

var _hp: ResourceBar
var _stamina: ResourceBar
var _player: Player


func _ready() -> void:
	layer = 10
	var box := VBoxContainer.new()
	box.position = Vector2(6, 6)
	box.add_theme_constant_override(&"separation", 2)
	add_child(box)
	_hp = ResourceBar.new()
	_hp.fill_color = Color(0.72, 0.26, 0.23)
	box.add_child(_hp)
	_stamina = ResourceBar.new()
	_stamina.fill_color = Color(0.37, 0.56, 0.31)
	_stamina.bar_height = 3
	box.add_child(_stamina)


func bind(player: Player) -> void:
	_player = player
	player.stats.hp_changed.connect(_hp.set_values)
	player.stats.stamina_changed.connect(_on_stamina)
	_hp.set_values(player.stats.hp, player.combat.max_hp)
	_on_stamina(player.stats.stamina, player.combat.max_stamina)


func _on_stamina(value: float, max_value: float) -> void:
	_stamina.dimmed = _player.stats.exhausted
	_stamina.set_values(value, max_value)
