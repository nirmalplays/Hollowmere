class_name SpriteSheetDef
extends Resource
## Describes a spritesheet so art can be swapped by replacing the PNG and editing data.
## Logic only ever refers to animation names, never frame numbers.

@export var texture: Texture2D
@export var frame_size: Vector2i = Vector2i(16, 24)
@export var animations: Array[SpriteAnimRow] = []
## Pixels between the frame's bottom edge and the character's feet.
@export var foot_inset: int = 1


## Offset for a centered AnimatedSprite2D so the node origin sits at the feet.
func foot_offset() -> Vector2:
	return Vector2(0.0, -frame_size.y / 2.0 + foot_inset)
