class_name CombatTuning
extends Resource
## Player combat tunables. Times are seconds. Race/class stats (M3) derive from these.

@export_group("Pools")
@export var max_hp: float = 100.0
@export var max_stamina: float = 100.0
@export var stamina_regen: float = 45.0  ## per second
@export var stamina_regen_delay: float = 0.6  ## pause after spending
@export var exhaust_recover: float = 30.0  ## after hitting 0, how much must refill before acting
@export var defense: float = 10.0
@export var resistances: Dictionary = {}
@export_group("Dodge")
@export var dodge_stamina: float = 22.0
@export var dodge_duration: float = 0.36
@export var dodge_iframes: float = 0.22  ## from the start of the roll
@export var dodge_speed: float = 170.0
@export var dodge_end_speed_ratio: float = 0.25
@export var dodge_recovery: float = 0.1  ## locked after the roll ends
@export_group("Sprint")
@export var sprint_mult: float = 1.5
@export var sprint_stamina_per_sec: float = 14.0
@export_group("Block and parry")
@export var block_move_mult: float = 0.45
@export var block_regen_mult: float = 0.35
@export var parry_window: float = 0.15  ## block pressed this long before a hit = parry
@export var parry_recover: float = 0.35
@export var riposte_open: float = 0.08  ## after a parry, attacks can start this soon
@export_group("Reactions")
@export var hurt_duration: float = 0.28
@export var guard_break_duration: float = 0.9
@export var parried_stagger_duration: float = 0.9
@export var respawn_delay: float = 2.5
