extends PlayerState
## Drinking from the Ember Flask (souls-like heal): a committed sip that leaves you
## slow and open. The health arrives near the end, so a hit mid-drink wastes nothing
## but punishes greed. Charges refill at a Hearth.

const DRINK_TIME: float = 0.8
const HEAL_AT: float = 0.6
const MOVE_MULT: float = 0.35

var _healed: bool = false


func enter(_msg: Dictionary) -> void:
	_healed = false
	player.flasks -= 1
	player.flasks_changed.emit(player.flasks, player.combat.flask_charges)
	player.play_directional(&"idle")
	AudioManager.sfx(&"pickup", -6.0, 0.05)


func physics_update(delta: float) -> void:
	player.move_with_input(delta, MOVE_MULT)
	player.update_facing()
	if not _healed and elapsed >= HEAL_AT:
		_healed = true
		var amount := player.combat.max_hp * player.combat.flask_heal_fraction
		player.stats.heal(amount)
		Fx.text(player.chest_position() + Vector2(0, -20), "+%d" % int(amount), Color(0.55, 0.95, 0.6), player)
		Flash.hit(player.sprite, Color(1.0, 0.8, 0.45), 0.3)
	if elapsed >= DRINK_TIME:
		machine.transition(&"Idle")
