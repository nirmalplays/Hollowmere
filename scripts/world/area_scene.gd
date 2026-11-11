class_name AreaScene
extends Node2D
## A playable top-down area: builds its AreaLayout, spawns one Player per peer at the
## Hearth ('P'), adds the HUD, plays its music and ambience, and announces its title.
## Story areas extend this and drive their quest beats (e.g. underroot_caves.gd).

const PLAYER_SCENE: PackedScene = preload("res://scenes/entities/player.tscn")
const MAIN_MENU_PATH: String = "res://scenes/ui/main_menu.tscn"

@export var layout: AreaLayout
@export var area_title: String = ""
@export var music: StringName = &"music_explore"
@export var ambience: StringName = &""
@export var ambient_light: Color = Color(0.32, 0.34, 0.45)

var player: Player
var built: AreaBuilder.Result
var hud: Hud

@onready var floor_layer: TileMapLayer = $Floor
@onready var wall_layer: TileMapLayer = $Walls
@onready var entities: Node2D = $World/Entities
@onready var _fx_layer: CanvasLayer = $FxLayer
@onready var _ambient: CanvasModulate = $Ambient


func _ready() -> void:
	_fx_layer.add_to_group(Fx.FX_ROOT_GROUP)
	_ambient.color = ambient_light
	built = AreaBuilder.build(layout, floor_layer, wall_layer, entities)
	for placement in built.placements:
		var node := (placement["scene"] as PackedScene).instantiate() as Node2D
		node.position = placement["position"]
		node.set_meta(&"marker", placement["char"])
		if node is Trigger:
			(node as Trigger).id = StringName(placement["char"])
		entities.add_child(node)
	if GameState.players.is_empty():
		GameState.start_solo()
	for peer_id: int in GameState.players:
		var p := PLAYER_SCENE.instantiate() as Player
		p.peer_id = peer_id
		p.name = "Player_%d" % peer_id
		p.position = built.spawns[0] if built.spawns else Vector2.ZERO
		entities.add_child(p)
		p.set_camera_limits(built.bounds)
		if p.input.is_local():
			player = p
			hud = Hud.new()
			add_child(hud)
			hud.bind(p)
	AudioManager.music(music)
	if ambience != &"":
		AudioManager.ambient(ambience)
	if area_title != "":
		EventBus.area_entered.emit.call_deferred(area_title)
	_start()


## Story areas override this to start their quest and beats.
func _start() -> void:
	pass


func enemies_with_char(ch: String) -> Array[Enemy]:
	var out: Array[Enemy] = []
	for node in entities.get_children():
		var e := node as Enemy
		if e and e.get_meta(&"marker", "") == ch:
			out.append(e)
	return out


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		get_tree().change_scene_to_file(MAIN_MENU_PATH)
