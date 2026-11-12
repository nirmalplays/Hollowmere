class_name Heroes
## The playable origins and classes, read from data/heroes/heroes.json (GAME_PLAN 4:
## an archetype is origin x class; adding one is a data task). A hero profile is the
## small dictionary a journey carries: {"name", "origin", "class"}.

const PATH: String = "res://data/heroes/heroes.json"
const ATTRIBUTES: Array[String] = ["might", "agility", "vitality", "intellect", "spirit"]
const DEFAULT := {"name": "Unlaid", "origin": "human", "class": "bruiser"}

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data = parsed if parsed is Dictionary else {"origins": [], "classes": []}
	return _data


static func origins() -> Array:
	return data()["origins"]


static func classes() -> Array:
	return data()["classes"]


static func origin(id: String) -> Dictionary:
	for o: Dictionary in origins():
		if o["id"] == id:
			return o
	return origins()[0]


static func hero_class(id: String) -> Dictionary:
	for c: Dictionary in classes():
		if c["id"] == id:
			return c
	return classes()[0]


static func sheet_path(profile: Dictionary) -> String:
	return "res://data/sprites/hero_%s_%s.tres" % [origin(profile.get("origin", "human"))["id"], hero_class(profile.get("class", "bruiser"))["id"]]


## Attribute scores shown in the creator: the class's base plus the origin's lean.
static func attributes(profile: Dictionary) -> Dictionary:
	var out := {}
	var base: Dictionary = hero_class(profile.get("class", ""))["stats"]
	var lean: Dictionary = origin(profile.get("origin", ""))["lean"]
	for a in ATTRIBUTES:
		out[a] = clampi(int(base.get(a, 0)) + int(lean.get(a, 0)), 0, 6)
	return out


## "Bullhorn Bruiser"
static func title(profile: Dictionary) -> String:
	return "%s %s" % [origin(profile.get("origin", ""))["name"], hero_class(profile.get("class", ""))["name"]]
