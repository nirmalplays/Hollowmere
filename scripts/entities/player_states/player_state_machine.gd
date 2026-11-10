class_name PlayerStateMachine
extends Node
## Owns the player's states (child nodes) and switches between them.

signal state_changed(from: StringName, to: StringName)

@export var initial_state: StringName = &"Idle"

var current: PlayerState

var _states: Dictionary = {}  # StringName -> PlayerState


func setup(owner_player: Player) -> void:
	for child in get_children():
		var state := child as PlayerState
		if state:
			state.player = owner_player
			state.machine = self
			_states[StringName(state.name)] = state
	transition(initial_state)


func transition(to: StringName, msg: Dictionary = {}) -> void:
	var next: PlayerState = _states.get(to)
	assert(next != null, "Unknown player state: %s" % to)
	var from: StringName = current.name if current else &""
	if current:
		current.exit()
	current = next
	current.elapsed = 0.0
	current.enter(msg)
	state_changed.emit(from, to)


func physics_update(delta: float) -> void:
	current.elapsed += delta
	current.physics_update(delta)


func current_name() -> StringName:
	return current.name if current else &""
