class_name EnemyAttackData
extends Resource
## One enemy attack, with its telegraph (GAME_PLAN 5.3). Times are milliseconds.
## M2 supports a circular AoE around the enemy; M4 adds melee arcs and projectiles.

@export var id: StringName = &"sweep"
@export var trigger_range: float = 30.0  ## starts when a target's feet are this close
@export var telegraph_ms: int = 700  ## wind-up the player can read and react to
@export var active_ms: int = 120
@export var recovery_ms: int = 600
@export var cooldown_ms: int = 1800
@export var damage: float = 14.0
@export var damage_type: StringName = &"physical"
@export var knockback: float = 120.0
@export var poise_damage: float = 20.0
@export var aoe_radius: float = 22.0
@export var weight: float = 1.0  ## for weighted choice when several attacks are ready (M4)
