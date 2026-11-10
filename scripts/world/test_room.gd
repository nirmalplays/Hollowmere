extends Node2D
## M1 test room: builds the floor/walls from a RoomLayout and spawns one Player per
## connected peer. Solo has exactly one entry in GameState.players (peer 1).

const PLAYER_SCENE: PackedScene = preload("res://scenes/entities/player.tscn")
const MAIN_MENU_PATH: String = "res://scenes/ui/main_menu.tscn"

@export var layout: RoomLayout

@onready var _tiles: TileMapLayer = $Tiles
@onready var _entities: Node2D = $Entities
@onready var _fx_layer: CanvasLayer = $FxLayer


func _ready() -> void:
	_fx_layer.add_to_group(Fx.FX_ROOT_GROUP)
	var built := RoomBuilder.build(layout, _tiles)
	for placement in built.placements:
		var node := (placement["scene"] as PackedScene).instantiate() as Node2D
		node.position = placement["position"]
		_entities.add_child(node)
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


func _unhandled_input(event: InputEvent) -> void:
	# Temporary until the pause menu (M12): Esc returns to the main menu.
	if event.is_action_pressed(&"pause"):
		get_tree().change_scene_to_file(MAIN_MENU_PATH)
