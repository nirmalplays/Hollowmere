class_name MusicZone
extends Area2D
## A place with its own music (a shrine, a town square, the waking chamber). Outside
## zones the world is ambience only, as in the reference.

@export var sound: StringName = &"music_cutscene"
@export var radius: float = 220.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = Const.LAYER_PLAYER
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)
	body_entered.connect(func(b: Node) -> void:
		if b is Player:
			AudioManager.zone_music(sound))
	body_exited.connect(func(b: Node) -> void:
		if b is Player:
			AudioManager.zone_music(&""))
