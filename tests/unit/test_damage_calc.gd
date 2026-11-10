extends TestCase
## DamageCalc rules (GAME_PLAN 5.3: the damage formula is unit-tested).

const PHYS := DamageCalc.PHYSICAL


func test_physical_no_defense_is_raw() -> void:
	assert_eq(DamageCalc.compute(100.0, PHYS, 0.0, {}), 100)


func test_defense_100_halves_physical() -> void:
	assert_eq(DamageCalc.compute(100.0, PHYS, 100.0, {}), 50)


func test_defense_has_diminishing_returns() -> void:
	var at_100 := DamageCalc.compute(100.0, PHYS, 100.0, {})
	var at_200 := DamageCalc.compute(100.0, PHYS, 200.0, {})
	assert_eq(at_200, 33, "200 defense")
	assert_true(at_100 - at_200 < 100 - at_100, "second 100 defense should help less")


func test_defense_does_not_reduce_elemental() -> void:
	assert_eq(DamageCalc.compute(100.0, &"fire", 100.0, {}), 100)


func test_resistance_and_weakness() -> void:
	assert_eq(DamageCalc.compute(100.0, &"fire", 0.0, {&"fire": 0.5}), 50, "resist")
	assert_eq(DamageCalc.compute(100.0, &"frost", 0.0, {&"frost": -0.5}), 150, "weakness")


func test_resistance_is_capped() -> void:
	assert_eq(DamageCalc.compute(100.0, &"void", 0.0, {&"void": 5.0}), 10, "max resist 90%")
	assert_eq(DamageCalc.compute(100.0, &"void", 0.0, {&"void": -5.0}), 200, "max weakness x2")


func test_block_reduction_applies_last() -> void:
	assert_eq(DamageCalc.compute(40.0, PHYS, 0.0, {}, 0.75), 10)
	assert_eq(DamageCalc.compute(40.0, PHYS, 100.0, {}, 0.5), 10, "defense then block")


func test_full_block_is_zero() -> void:
	assert_eq(DamageCalc.compute(40.0, PHYS, 0.0, {}, 1.0), 0)


func test_crit_multiplies() -> void:
	assert_eq(DamageCalc.compute(20.0, PHYS, 0.0, {}, 0.0, true), 30, "default crit x1.5")
	assert_eq(DamageCalc.compute(20.0, PHYS, 0.0, {}, 0.0, true, 2.0), 40, "custom crit")


func test_minimum_one_damage() -> void:
	assert_eq(DamageCalc.compute(1.0, PHYS, 1000.0, {}), 1)


func test_zero_amount_is_zero() -> void:
	assert_eq(DamageCalc.compute(0.0, PHYS, 0.0, {}), 0)


func test_from_info_uses_info_fields() -> void:
	var info := DamageInfo.new()
	info.amount = 20.0
	info.damage_type = &"fire"
	info.crit = true
	assert_eq(DamageCalc.from_info(info, 50.0, {&"fire": 0.5}), 15, "crit 30, fire resist half, defense ignored")
