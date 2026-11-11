class_name Keys
## Names for whatever is bound to an action, so prompts follow rebinding.
## Write prompts with {action} tokens: "Interact with [{interact}]" -> "Interact with [F]".

const MOUSE_NAMES := {MOUSE_BUTTON_LEFT: "LMB", MOUSE_BUTTON_RIGHT: "RMB", MOUSE_BUTTON_MIDDLE: "MMB"}


static func label(action: StringName) -> String:
	if not InputMap.has_action(action):
		return String(action)
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			var code: int = e.physical_keycode if e.physical_keycode != 0 else e.keycode
			return OS.get_keycode_string(code)
		if e is InputEventMouseButton:
			return MOUSE_NAMES.get(e.button_index, "Mouse")
	return String(action)


## Replaces {action} tokens with key names.
static func fmt(text: String) -> String:
	var out := text
	var re := RegEx.create_from_string("\\{([a-z_0-9]+)\\}")
	for m in re.search_all(text):
		out = out.replace(m.get_string(), label(StringName(m.get_string(1))))
	return out
