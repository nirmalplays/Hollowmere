class_name DamageInfo
extends RefCounted
## One hit, before mitigation. Built by the attacker, resolved by the target.
## In co-op only the host builds and resolves these (GAME_PLAN 9.4).

enum Result { HIT, BLOCKED, PARRIED, IGNORED }

var source: Node  ## attacker (may be freed later; check is_instance_valid)
var amount: float = 0.0  ## raw damage = attacker power * attack multiplier
var damage_type: StringName = DamageCalc.PHYSICAL
var poise_damage: float = 0.0
var knockback: float = 0.0  ## pixels/second applied to the target
var direction: Vector2 = Vector2.ZERO  ## attacker -> target, normalized
var crit: bool = false
var attack_id: StringName = &""


## A copy aimed at one target, so each target gets its own direction.
func aimed_at(target: Node2D, origin: Vector2) -> DamageInfo:
	var copy := DamageInfo.new()
	copy.source = source
	copy.amount = amount
	copy.damage_type = damage_type
	copy.poise_damage = poise_damage
	copy.knockback = knockback
	copy.crit = crit
	copy.attack_id = attack_id
	var delta := target.global_position - origin
	copy.direction = delta.normalized() if delta.length() > 0.01 else Vector2.RIGHT
	return copy
