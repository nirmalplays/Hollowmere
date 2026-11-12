class_name RestFire
extends Inscription
## A fire you can rest at. Resting makes it your Hearth (where you rise after a death),
## mends you, refills the Ember Flask and keeps the journey. Pockets of warmth off the
## trail: the wood's only safe places.

const RING: Texture2D = preload("res://assets/art/props/wild/campfire_cold.png")
const WARM := Color(1.0, 0.62, 0.28)

var _fire: PointLight2D
var _sparks: Array[Dictionary] = []


func _ready() -> void:
	text = "You sit. The fire does not ask what you are."
	prompt = "Rest"
	radius = 44.0
	super._ready()
	var ring := Sprite2D.new()
	ring.texture = RING
	ring.offset = Vector2(0, -RING.get_height() / 2.0 + 6)
	ring.show_behind_parent = true
	add_child(ring)
	_fire = Prop.make_light(WARM, 1.7, 1.5, Vector2(0, -10))
	add_child(_fire)
	add_child(AudioManager.make_emitter(&"amb_fire"))
	used.connect(_rest)


func _process(delta: float) -> void:
	super._process(delta)
	_fire.energy = 1.7 * (0.86 + 0.14 * sin(_t * 9.0) * sin(_t * 5.3))
	if randf() < delta * 7.0:
		_sparks.append({"p": Vector2(randf_range(-4, 4), -12), "v": Vector2(randf_range(-5, 5), -randf_range(14, 26)), "life": randf_range(0.6, 1.3)})
	for s in _sparks:
		s["p"] += s["v"] * delta
		s["life"] -= delta
	_sparks = _sparks.filter(func(s: Dictionary) -> bool: return s["life"] > 0.0)
	queue_redraw()


func _draw() -> void:
	# Three tongues of flame, drawn in chunky pixels so they sit with the sprites.
	for i in 3:
		var sway := sin(_t * (7.0 + i * 2.3) + i * 2.0)
		var h := 9.0 + 4.0 * sin(_t * (9.0 + i) + i)
		var x := (i - 1) * 4.0 + sway
		draw_rect(Rect2(round(x - 3), -8 - h, 6, h), Color(0.95, 0.42, 0.12))
		draw_rect(Rect2(round(x - 2), -8 - h * 0.7, 4, h * 0.7), Color(1.0, 0.72, 0.25))
		draw_rect(Rect2(round(x - 1), -8 - h * 0.4, 2, h * 0.4), Color(1.0, 0.95, 0.7))
	for s in _sparks:
		draw_rect(Rect2(s["p"], Vector2(1, 1)), Color(1.0, 0.8, 0.4, clampf(s["life"], 0.0, 1.0)))
	super._draw()


func _rest() -> void:
	var player := get_tree().get_first_node_in_group(&"players") as Player
	if player == null:
		return
	player.spawn_point = global_position + Vector2(0, 22)
	player.stats.heal(player.combat.max_hp)
	player.flasks = player.combat.flask_charges
	player.flasks_changed.emit(player.flasks, player.combat.flask_charges)
	AudioManager.sfx(&"respawn", -8.0, 0.0)
	EventBus.toast_shown.emit("Hearth", "You will rise here")
	SaveManager.save_game.call_deferred()
	var menu := KindleMenu.new()
	menu.player = player
	get_tree().current_scene.add_child(menu)
