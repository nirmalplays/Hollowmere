extends Node
## Loads every resource under res://data/ at startup and serves lookups by id.
## M0: stub. Filled in at M3 (races/classes) and extended each milestone after.
## Content is data-only: adding a .tres under data/ must never require code changes.

const DATA_ROOT: String = "res://data/"

var _by_category: Dictionary = {}  # category (String) -> { id (StringName) -> Resource }


func _ready() -> void:
	pass  # TODO(M3): scan DATA_ROOT subfolders and register resources.


func get_entry(category: StringName, id: StringName) -> Resource:
	var bucket: Dictionary = _by_category.get(category, {})
	return bucket.get(id, null)


func list_ids(category: StringName) -> Array:
	return _by_category.get(category, {}).keys()
