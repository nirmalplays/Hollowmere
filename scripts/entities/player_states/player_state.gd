class_name PlayerState
extends Node
## Base class for player states. Each state lives in its own script (GAME_PLAN 5.3);
## the node's name is the state's name (Idle, Move, Attack...).

var player: Player
var machine: PlayerStateMachine
var elapsed: float = 0.0  ## seconds since this state was entered


func enter(_msg: Dictionary) -> void:
	pass


func exit() -> void:
	pass


func physics_update(_delta: float) -> void:
	pass


## How this state answers an incoming hit: a DamageInfo.Result, or -1 for "take it normally".
func on_hit(_info: DamageInfo) -> int:
	return -1


## Stamina regen multiplier while in this state (0 = no regen).
func stamina_regen_mult() -> float:
	return 1.0
