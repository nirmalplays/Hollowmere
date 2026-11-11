class_name Inscription
extends Node2D
## Something readable in the world: a carved stone, a ledger page, a grave.
## Walk close and press Interact; the text shows in the HUD's lore box
## (STORY_BIBLE 9: lore is anchored to objects, one fact at a time).

signal read

@export_multiline var text: String = ""
@export var radius: float = 34.0
@export var prompt: String = "Read"

var _prompt: Label
var _near: bool = false
var _was_read: bool = false


func _ready() -> void:
	_prompt = Label.new()
	_prompt.text = Keys.fmt("[{interact}] ") + prompt
	_prompt.add_theme_font_override(&"font", load("res://assets/fonts/Alegreya.ttf"))
	_prompt.add_theme_font_size_override(&"font_size", 9)
	_prompt.add_theme_color_override(&"font_shadow_color", Color.BLACK)
	_prompt.add_theme_constant_override(&"shadow_offset_y", 1)
	_prompt.position = Vector2(-16, -48)
	_prompt.visible = false
	add_child(_prompt)


func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group(&"players") as Node2D
	_near = player != null and player.global_position.distance_to(global_position) < radius
	_prompt.visible = _near


func _unhandled_input(event: InputEvent) -> void:
	if _near and event.is_action_pressed(&"interact"):
		EventBus.lore_shown.emit(text)
		AudioManager.sfx(&"ui_select", -6.0, 0.0)
		if not _was_read:
			_was_read = true
			read.emit()
		get_viewport().set_input_as_handled()
