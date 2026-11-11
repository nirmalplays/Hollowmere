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
@export var reverb: bool = false

var player: Player
var built: AreaBuilder.Result
var hud: Hud
var place: String = ""  ## the named place the player is standing in ("" between them)

var _last_announced: String = ""

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
	AudioManager.set_area_music(music)
	AudioManager.set_reverb(reverb)
	if ambience != &"":
		AudioManager.ambient(ambience)
	if area_title != "":
		EventBus.area_entered.emit.call_deferred(area_title)
	place = _place_at(player.global_position) if player else ""
	_last_announced = place  # the area's own title covers where you start
	_start()


func _physics_process(_delta: float) -> void:
	if player == null or Engine.get_physics_frames() % 10 != 0:
		return
	place = _place_at(player.global_position)
	if place != "" and place != _last_announced:
		_last_announced = place
		EventBus.area_entered.emit(place)


func _place_at(at: Vector2) -> String:
	var cell := Vector2i(floor_layer.local_to_map(floor_layer.to_local(at)))
	for i in layout.place_rects.size():
		if layout.place_rects[i].has_point(cell):
			return layout.place_names[i]
	return ""


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
