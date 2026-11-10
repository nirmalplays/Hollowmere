class_name PropDef
extends Resource
## A placeable world prop (tree, ruin, campfire...). One of `textures` is picked per
## placement (deterministically), so a forest of 'T's isn't a grid of clones.

@export var textures: Array[Texture2D] = []
## Pixels between the texture's bottom edge and where it touches the ground.
@export var base_inset: int = 2
## Blocks movement within this radius of its base (0 = walk-through decoration).
@export var collision_radius: float = 0.0
## Random offset in pixels so rows of props don't look gridded.
@export var jitter: float = 5.0
@export var flip_randomly: bool = true
@export_group("Light")
@export var light_color: Color = Color(0, 0, 0, 0)  ## alpha 0 = no light
@export var light_energy: float = 1.0
@export var light_scale: float = 1.0
@export var light_height: float = 10.0
