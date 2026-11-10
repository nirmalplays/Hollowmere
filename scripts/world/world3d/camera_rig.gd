class_name CameraRig
extends Camera3D
## MOBA-style camera (Mobile Legends / Dimraeth): fixed high angle looking "north",
## never rotates, follows its target with a little smoothing.

@export var target: Node3D
@export var pitch_degrees: float = 52.0  ## how steeply it looks down
@export var distance: float = 17.0  ## metres from the look-at point
@export var look_height: float = 0.8  ## look at the target's chest, not its feet
@export var follow_speed: float = 8.0

var _focus: Vector3 = Vector3.ZERO


func _ready() -> void:
	if target:
		_focus = target.global_position
	_apply()


func _physics_process(delta: float) -> void:
	if target == null:
		return
	_focus = _focus.lerp(target.global_position, 1.0 - exp(-follow_speed * delta))
	_apply()


func snap_to_target() -> void:
	if target:
		_focus = target.global_position
		_apply()


func _apply() -> void:
	var pitch := deg_to_rad(pitch_degrees)
	var look_at_point := _focus + Vector3.UP * look_height
	global_position = look_at_point + Vector3(0.0, sin(pitch), cos(pitch)) * distance
	rotation = Vector3(-pitch, 0.0, 0.0)
