extends Control
## M0 main menu. Solo is the default path and never blocked by co-op (GAME_PLAN 9.0).
## Solo currently only reports that gameplay arrives in M1.

@onready var _solo_button: Button = $Center/SoloButton
@onready var _quit_button: Button = $Center/QuitButton
@onready var _status: Label = $Status


func _ready() -> void:
	_solo_button.pressed.connect(_on_solo_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_solo_button.grab_focus()  # keyboard/gamepad navigation works from the first frame


func _on_solo_pressed() -> void:
	_status.text = "Test room arrives in milestone M1."


func _on_quit_pressed() -> void:
	get_tree().quit()
