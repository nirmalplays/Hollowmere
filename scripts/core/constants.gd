class_name Const
## Project-wide constants. Gameplay tunables belong in data resources, not here;
## this file is only for engine-level contracts like physics layer bits.

# Physics layers (names also set in project.godot [layer_names]).
const LAYER_WORLD: int = 1 << 0
const LAYER_PLAYER: int = 1 << 1
const LAYER_ENEMY: int = 1 << 2
const LAYER_HITBOX: int = 1 << 3
const LAYER_HURTBOX: int = 1 << 4
const LAYER_INTERACT: int = 1 << 5

const TILE_SIZE: int = 16
const SOLO_PEER_ID: int = 1  # solo play = host with this id and no other peers
