class_name EnemyData
extends Resource
## An enemy type (GAME_PLAN 5.6). Adding an enemy = a new .tres, not new code.

@export var id: StringName = &""
@export var display_name: String = ""
@export var max_hp: float = 100.0
@export var defense: float = 0.0
@export var resistances: Dictionary = {}  ## element -> fraction (negative = weakness)
@export var xp: int = 10
@export_group("Movement")
@export var move_speed: float = 0.0  ## 0 = holds its ground (training husks)
@export var aggro_radius: float = 140.0
@export var leash_radius: float = 320.0  ## gives up and walks home past this
@export_group("Poise")
@export var max_poise: float = 50.0
@export var poise_regen: float = 15.0  ## per second, after the delay
@export var poise_regen_delay: float = 2.0
@export var stagger_ms: int = 1600
## Damage multiplier on staggered enemies (ripostes and poise-break follow-ups).
@export var stagger_damage_mult: float = 2.0
@export_group("Defence")
## Shielded: frontal hits are blocked (clang) until it is parried or its poise breaks.
@export var shielded: bool = false
## Can be laid to rest with the Cradle Lantern while staggered (STORY_BIBLE 4: Rest).
@export var restable: bool = true
@export_group("Combat")
@export var attacks: Array[EnemyAttackData] = []
## Boss phase 2: below this HP fraction it switches to `phase2_attacks` and summons.
@export_range(0.0, 1.0) var phase2_at: float = 0.0
@export var phase2_attacks: Array[EnemyAttackData] = []
@export var phase2_summon: PackedScene
@export var phase2_summon_count: int = 0
@export var revive_ms: int = -1  ## -1 = stays dead; training husks pull themselves back up
@export_group("Visuals")
@export var sprite_sheet: SpriteSheetDef
@export var hit_fx: FxDef
@export var telegraph_color: Color = Color(1.0, 0.35, 0.25)
@export var is_boss: bool = false
