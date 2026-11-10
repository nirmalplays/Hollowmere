class_name EnemyData
extends Resource
## An enemy type (GAME_PLAN 5.6). Adding an enemy = a new .tres, not new code.

@export var id: StringName = &""
@export var display_name: String = ""
@export var max_hp: float = 100.0
@export var defense: float = 0.0
@export var resistances: Dictionary = {}  ## element -> fraction (negative = weakness)
@export_group("Poise")
@export var max_poise: float = 50.0
@export var poise_regen: float = 15.0  ## per second, after the delay
@export var poise_regen_delay: float = 2.0
@export var stagger_ms: int = 1600
## Damage multiplier on staggered enemies (ripostes and poise-break follow-ups).
@export var stagger_damage_mult: float = 2.0
@export_group("Combat")
@export var attacks: Array[EnemyAttackData] = []
@export var revive_ms: int = -1  ## -1 = stays dead; training dummies pull themselves back up
@export_group("Visuals")
@export var sprite_sheet: SpriteSheetDef
@export var hit_fx: FxDef
@export var telegraph_color: Color = Color(1.0, 0.35, 0.25)
