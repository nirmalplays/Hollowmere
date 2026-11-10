class_name CombatStats
extends Node
## HP and stamina pools with regen. Mana joins in M3/M5.
## Stamina: spending pauses regen briefly; reaching 0 exhausts you until it refills
## past CombatTuning.exhaust_recover (GAME_PLAN 5.1).

signal hp_changed(value: float, max_value: float)
signal stamina_changed(value: float, max_value: float)
signal died

var tuning: CombatTuning
var hp: float = 0.0
var stamina: float = 0.0
var exhausted: bool = false

var _regen_delay_left: float = 0.0


func reset() -> void:
	hp = tuning.max_hp
	stamina = tuning.max_stamina
	exhausted = false
	_regen_delay_left = 0.0
	hp_changed.emit(hp, tuning.max_hp)
	stamina_changed.emit(stamina, tuning.max_stamina)


func can_act() -> bool:
	return not exhausted and stamina > 0.0


func spend_stamina(amount: float) -> void:
	if amount <= 0.0:
		return
	stamina = maxf(0.0, stamina - amount)
	_regen_delay_left = tuning.stamina_regen_delay
	if stamina <= 0.0:
		exhausted = true
	stamina_changed.emit(stamina, tuning.max_stamina)


func regen(delta: float, mult: float = 1.0) -> void:
	if _regen_delay_left > 0.0:
		_regen_delay_left -= delta
		return
	if stamina >= tuning.max_stamina:
		return
	stamina = minf(tuning.max_stamina, stamina + tuning.stamina_regen * mult * delta)
	if exhausted and stamina >= tuning.exhaust_recover:
		exhausted = false
	stamina_changed.emit(stamina, tuning.max_stamina)


func take_damage(amount: int) -> void:
	if amount <= 0 or hp <= 0.0:
		return
	hp = maxf(0.0, hp - amount)
	hp_changed.emit(hp, tuning.max_hp)
	if hp <= 0.0:
		died.emit()


func is_dead() -> bool:
	return hp <= 0.0
