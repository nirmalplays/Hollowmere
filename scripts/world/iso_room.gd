extends Node2D
## An isometric area built from an IsoRoomLayout (ground, cliffs, props, enemies),
## with one Player per connected peer. Solo has exactly one (peer 1).
## Cliffs, props and characters share one y-sorted parent so they occlude correctly.

const PLAYER_SCENE: PackedScene = preload("res://scenes/entities/player.tscn")
const MAIN_MENU_PATH: String = "res://scenes/ui/main_menu.tscn"

@export var layout: IsoRoomLayout

@onready var _ground: TileMapLayer = $Ground
@onready var _raised: TileMapLayer = $World/Raised
@onready var _entities: Node2D = $World/Entities
@onready var _fx_layer: CanvasLayer = $FxLayer


@export var quest_title: String = ""
@export var quest_steps: PackedStringArray = []
@export var music: StringName = &"music_explore"
@export var ambience: StringName = &"amb_forest"


func _ready() -> void:
	_fx_layer.add_to_group(Fx.FX_ROOT_GROUP)
	AudioManager.music(music)
	AudioManager.ambient(ambience)
	var built := IsoRoomBuilder.build(layout, _ground, _raised, _entities)
	for placement in built.placements:
		var node := (placement["scene"] as PackedScene).instantiate() as Node2D
		node.position = placement["position"]
		_entities.add_child(node)
	if quest_title != "":
		QuestLog.start(quest_title, quest_steps)
		EventBus.enemy_killed.connect(func(_e: Node, _k: Node) -> void: QuestLog.complete(0))
		for node in get_tree().get_nodes_in_group(&"quest_inscription"):
			(node as Inscription).read.connect(func() -> void: QuestLog.complete(1))
	if GameState.players.is_empty():
		GameState.start_solo()  # running the scene directly from the editor
	var i := 0
	for peer_id: int in GameState.players:
		var player := PLAYER_SCENE.instantiate() as Player
		player.peer_id = peer_id
		player.name = "Player_%d" % peer_id
		player.position = built.spawns[i % built.spawns.size()] if built.spawns else Vector2.ZERO
		_entities.add_child(player)
		player.set_camera_limits(built.bounds)
		if player.input.is_local():
			var hud := Hud.new()
			add_child(hud)
			hud.bind(player)
		i += 1


## The raised (cliff) layer, for tests and tools.
func raised_layer() -> TileMapLayer:
	return _raised


func ground_layer() -> TileMapLayer:
	return _ground


func _unhandled_input(event: InputEvent) -> void:
	# Temporary until the pause menu (M12): Esc returns to the main menu.
	if event.is_action_pressed(&"pause"):
		get_tree().change_scene_to_file(MAIN_MENU_PATH)
