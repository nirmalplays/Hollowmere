class_name AttackData
extends Resource
## One attack's timing and effect (GAME_PLAN 5.3). Times are milliseconds.
## Flow rule: you keep moving at `move_mult` while swinging, a dash cancels any time,
## and the next swing may start `chain_ms` into recovery.

@export var id: StringName = &"light"
@export var windup_ms: int = 160
@export var active_ms: int = 100
@export var recovery_ms: int = 260
@export var dodge_cancel_ms: int = 80  ## legacy: a dash now cancels at any time
@export var chain_ms: int = 90  ## ms into recovery when the next attack may start
@export_range(0.0, 1.0) var move_mult: float = 0.6  ## walking speed kept while swinging
@export var damage_mult: float = 1.0
@export var damage_type: StringName = &"physical"
@export var stamina_cost: float = 18.0
@export var knockback: float = 60.0
@export var poise_damage: float = 10.0
## The strike throws a bolt at the cursor instead of cutting (staves).
@export var projectile: bool = false
@export_group("Shape")
@export var reach: float = 12.0  ## hitbox center distance from the body
@export var hitbox_size: Vector2 = Vector2(18, 14)  ## x = along the swing direction
@export var lunge_speed: float = 60.0  ## burst of speed when the strike starts
@export_group("Feel")
@export var hit_stop_ms: int = 50
@export var shake: float = 1.0
@export var fx: FxDef
@export var sound: StringName = &"swing_light"
