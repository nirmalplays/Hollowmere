class_name IntegrationTest
extends Node
## Base for scene-level tests. Override `_run()` as a coroutine: drive input, then
## `await wait_until(...)` / `await wait_frames(...)` and `check()` results.
## The runner frees the test (and any scene it spawned) afterwards.

signal finished

var failures: Array[String] = []

var _done: bool = false


func _ready() -> void:
	_start.call_deferred()


func _start() -> void:
	await _run()
	finish()


func _run() -> void:
	pass


func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)


func fail(message: String) -> void:
	failures.append(message)


func finish() -> void:
	if _done:
		return
	_done = true
	for action in InputMap.get_actions():
		Input.action_release(action)
	finished.emit()


func wait_frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


## Waits until `condition` is true or `max_frames` physics frames pass. Returns the condition.
func wait_until(condition: Callable, max_frames: int) -> bool:
	for i in max_frames:
		if _done:
			return false
		if condition.call():
			return true
		await get_tree().physics_frame
	return condition.call()


## Presses an action for one physics frame (like a tap).
func tap(action: StringName) -> void:
	Input.action_press(action)
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release(action)


## Loads a scene under this test (so it's freed with the test).
func spawn_scene(path: String) -> Node:
	var node := (load(path) as PackedScene).instantiate()
	add_child(node)
	return node
