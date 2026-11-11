class_name LanternPedestal
extends Inscription
## The cracked Cradle Lantern on its pedestal beside your cradle (ACT1_MQ01 O1).
## Taking it lights your way and powers Rests (STORY_BIBLE 4).

const LIT: Texture2D = preload("res://assets/art/props/lpc/lantern_pedestal_lit.png")
const EMPTY: Texture2D = preload("res://assets/art/props/lpc/lantern_pedestal_empty.png")

var _sprite: Sprite2D
var _light: PointLight2D


func _ready() -> void:
	text = "The lantern is cracked, but it burns. It is warm in your hand, as if it has been waiting."
	prompt = "Take the lantern"
	radius = 30.0
	super._ready()
	_sprite = Sprite2D.new()
	_sprite.texture = LIT
	_sprite.offset = Vector2(0, -LIT.get_height() / 2.0 + 2)
	add_child(_sprite)
	add_child(Prop.make_shadow(0.4))
	_light = IsoRoomBuilder.make_light(Color(1.0, 0.72, 0.4), 1.6, 0.9, Vector2(0, -16))
	add_child(_light)
	read.connect(_on_taken)


func _on_taken() -> void:
	_sprite.texture = EMPTY
	_light.queue_free()
	_prompt.visible = false
	set_process(false)
	set_process_unhandled_input(false)
	GameState.flags[&"has_cradle_lantern"] = true
	EventBus.story_flag_changed.emit(&"has_cradle_lantern", true)
	EventBus.toast_shown.emit("Item", "Cradle Lantern")
