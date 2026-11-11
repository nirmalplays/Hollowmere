class_name CharacterAnimator
extends RefCounted
## Plays "<base>_<dir>" animations from an 8-direction sheet (see tools/art/import_lpc.py).
## Directions are screen compass points: s is toward the camera, n away from it.

## Index = round(angle / 45 deg), angle measured from +x with y pointing down.
const DIRS: Array[String] = ["e", "se", "s", "sw", "w", "nw", "n", "ne"]

var sprite: AnimatedSprite2D


func _init(target: AnimatedSprite2D) -> void:
	sprite = target


static func dir_name(facing: Vector2) -> String:
	if facing == Vector2.ZERO:
		return "s"
	return DIRS[wrapi(roundi(facing.angle() / (PI / 4.0)), 0, 8)]


## Plays the animation for `facing`. Same animation keeps playing (a finished
## one-shot holds its last frame) unless `restart` is true.
func play(base: StringName, facing: Vector2, speed: float = 1.0, restart: bool = false) -> void:
	var anim := StringName("%s_%s" % [base, dir_name(facing)])
	if not sprite.sprite_frames.has_animation(anim):
		return
	sprite.speed_scale = speed
	if restart or sprite.animation != anim:
		var frame := 0 if restart or not _same_base(anim) else sprite.frame
		sprite.play(anim)
		sprite.frame = mini(frame, sprite.sprite_frames.get_frame_count(anim) - 1)


## Plays so the whole animation lasts `seconds` (e.g. an attack timed to its data).
func play_timed(base: StringName, facing: Vector2, seconds: float) -> void:
	var anim := StringName("%s_%s" % [base, dir_name(facing)])
	if not sprite.sprite_frames.has_animation(anim):
		return
	var natural := sprite.sprite_frames.get_frame_count(anim) / maxf(sprite.sprite_frames.get_animation_speed(anim), 0.01)
	play(base, facing, natural / maxf(seconds, 0.01), true)


## Turning while walking keeps the stride: carry the frame over between directions.
func _same_base(anim: StringName) -> bool:
	var a := String(sprite.animation)
	var b := String(anim)
	return a.get_slice("_", 0) == b.get_slice("_", 0)
