extends Node
## The active quest and its steps, shown by the HUD's tracker (STORY_BIBLE 6, GAME_PLAN 7).
## M7 replaces this with the full data-driven quest state machines; the HUD keeps
## listening to the same signals.

signal quest_changed(title: String, steps: Array)
signal step_completed(index: int)

var title: String = ""
var steps: Array = []  ## [{"text": String, "done": bool}]


func start(quest_title: String, step_texts: PackedStringArray) -> void:
	title = quest_title
	steps.clear()
	for t in step_texts:
		steps.append({"text": t, "done": false})
	quest_changed.emit(title, steps)


func complete(index: int) -> void:
	if index >= 0 and index < steps.size() and not steps[index]["done"]:
		steps[index]["done"] = true
		AudioManager.sfx(&"quest_complete", -6.0, 0.0)
		step_completed.emit(index)
		quest_changed.emit(title, steps)


func clear() -> void:
	title = ""
	steps.clear()
	quest_changed.emit(title, steps)
