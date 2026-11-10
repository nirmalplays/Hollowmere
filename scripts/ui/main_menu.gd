extends Control
## M0 main menu. Solo is the default path and never blocked by co-op (GAME_PLAN 9.0).
## Solo goes to the M1 test room until zones exist (M7).

const SOLO_START_SCENE: String = "res://scenes/world/test_room.tscn"

@onready var _solo_button: Button = $Center/SoloButton
@onready var _quit_button: Button = $Center/QuitButton
@onready var _status: Label = $Status


func _ready() -> void:
	_solo_button.pressed.connect(_on_solo_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_solo_button.grab_focus()  # keyboard/gamepad navigation works from the first frame


func _on_solo_pressed() -> void:
	GameState.start_solo()
	get_tree().change_scene_to_file(SOLO_START_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()
