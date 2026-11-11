class_name EnemyAttackData
extends Resource
## One enemy attack and its telegraph (GAME_PLAN 5.3). Times are milliseconds.
## Shapes:
##   AROUND    - a circle round the enemy (sweeps, slams)
##   FRONT     - a box in front, toward the target (swings, lunges)
##   AT_TARGET - circles on the ground where the target stands (grave-pits, falling debris)

enum Shape { AROUND, FRONT, AT_TARGET }

@export var id: StringName = &"sweep"
@export var shape: Shape = Shape.AROUND
@export var trigger_range: float = 34.0  ## starts when the target's feet are this close
@export var telegraph_ms: int = 700  ## wind-up the player can read and react to
@export var active_ms: int = 120
@export var recovery_ms: int = 600
@export var cooldown_ms: int = 1800
@export var damage: float = 14.0
@export var damage_type: StringName = &"physical"
@export var knockback: float = 120.0
@export var poise_damage: float = 20.0
@export var weight: float = 1.0  ## weighted choice when several attacks are ready
@export_group("Shape")
@export var aoe_radius: float = 28.0  ## AROUND and AT_TARGET
@export var reach: float = 20.0  ## FRONT: hitbox centre distance from the body
@export var box_size: Vector2 = Vector2(30, 22)  ## FRONT: x along the swing
@export var lunge_speed: float = 0.0  ## FRONT: burst toward the target on release
@export var pits: int = 1  ## AT_TARGET: how many circles (the first under the target)
@export var pit_spread: float = 40.0
