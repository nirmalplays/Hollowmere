class_name SpriteAnimRow
extends Resource
## One animation = one row of a spritesheet (GAME_PLAN 11.2).

@export var name: StringName = &"idle_down"
@export var row: int = 0
## First column, so one row can hold several short animations (e.g. attack phases).
@export var column: int = 0
@export var frame_count: int = 4
@export var fps: float = 6.0
@export var loop: bool = true
