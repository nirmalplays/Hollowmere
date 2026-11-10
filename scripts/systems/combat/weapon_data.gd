class_name WeaponData
extends Resource
## A weapon: base damage, its light/heavy attacks and how well it blocks.

@export var id: StringName = &""
@export var display_name: String = ""
@export var base_damage: float = 12.0
@export var light: AttackData
@export var heavy: AttackData
@export_range(0.0, 1.0) var block_reduction: float = 0.7  ## fraction of damage stopped when blocking
@export var block_stamina_per_damage: float = 1.2  ## stamina lost per point of raw damage blocked
@export var attribute_requirements: Dictionary = {}  ## M3+: e.g. {"might": 8}
