class_name DamageCalc
## The one place damage is computed (GAME_PLAN 5.3). Unit-tested in tests/unit/test_damage_calc.gd.
##
## Physical damage is reduced by defense with diminishing returns: 100 defense halves it.
## Elemental damage uses a resistance fraction per element: 0.5 = half, -0.5 = 50% weakness.
## Block reduction applies last. Any hit that isn't fully blocked deals at least 1.

const PHYSICAL: StringName = &"physical"
const ARMOR_SCALE: float = 100.0  ## defense at which physical damage is halved
const MAX_RESIST: float = 0.9  ## nothing is fully immune through resistance alone
const MAX_WEAKNESS: float = -1.0  ## at most double damage from a weakness
const CRIT_MULT: float = 1.5


static func compute(
	amount: float,
	damage_type: StringName,
	defense: float,
	resistances: Dictionary,
	block_reduction: float = 0.0,
	crit: bool = false,
	crit_mult: float = CRIT_MULT,
) -> int:
	if amount <= 0.0:
		return 0
	var block := clampf(block_reduction, 0.0, 1.0)
	if block >= 1.0:
		return 0
	var dmg := amount * (crit_mult if crit else 1.0)
	if damage_type == PHYSICAL:
		dmg *= ARMOR_SCALE / (ARMOR_SCALE + maxf(defense, 0.0))
	var resist := clampf(float(resistances.get(damage_type, 0.0)), MAX_WEAKNESS, MAX_RESIST)
	dmg *= 1.0 - resist
	dmg *= 1.0 - block
	return maxi(1, roundi(dmg))


static func from_info(
	info: DamageInfo, defense: float, resistances: Dictionary, block_reduction: float = 0.0, crit_mult: float = CRIT_MULT
) -> int:
	return compute(info.amount, info.damage_type, defense, resistances, block_reduction, info.crit, crit_mult)
