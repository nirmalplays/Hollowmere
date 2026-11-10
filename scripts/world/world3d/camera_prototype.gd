extends Node3D
## Camera/look prototype for the 3D switch: a blocky level with height, water and
## trees, moonlight + the Unlaid's lantern, a MOBA-style camera, and pixel-art
## rendering (the project renders 3D at 640x360 and scales it up crisply).
## Movement only; combat gets ported once the look is approved.

const SHEET: SpriteSheetDef = preload("res://data/sprites/unlaid.tres")
const DUMMY_SHEET: SpriteSheetDef = preload("res://data/sprites/training_dummy.tres")
const TERRAIN_DIR: String = "res://assets/art/terrain/"
const TERRAIN: Array[String] = ["grass", "grass_dark", "moss", "path_stone", "ash", "cliff_side", "dirt", "wall_side", "wall_top"]
const PIXELS_PER_METRE: float = 16.0  ## current sprites are 16 px/m; the 3D art pass targets 32
const SPEED: float = 4.0

## '.' grass, ',' dark grass, 'm' moss, '=' stone path, 'a' Hollow ash, '#' cliff (2m),
## '^' ledge (1m), 'W' ruined wall (2m), '~' water, 'T' tree, 'P' player, 'D' dummy, '*' shrine crystal
const LAYOUT: Array[String] = [
	"################################",
	"################################",
	"##,,,,T,,.....==....##,,T,,,,,##",
	"##,T,,,......===.....#,,,,,,T,##",
	"##,,,.....m..==......^^^^^^,,,##",
	"##,,...~~~~..==......^^*^^^,,,##",
	"##,...~~~~~~.==.mm...^^=^^^...##",
	"##.....~~~~..==......===......##",
	"##...........====..====...m...##",
	"##..P.......D==========.......##",
	"##..........==...aaaa.....T...##",
	"##....WWW...==..aaaaaa........##",
	"##....W.....==..aaaaaa...WWW..##",
	"##..T.......==...aaaa......W..##",
	"##,,,,,,,,..==.T..............##",
	"##,,,,,T,,,,==,,,,,,T,,,,,T,,,##",
	"################################",
	"################################",
]

var _player: CharacterBody3D
var _sprite: AnimatedSprite3D
var _facing := Vector2.DOWN


func _ready() -> void:
	var rows := PackedStringArray(LAYOUT)
	var legend := {
		".": GridMesher.Block.new(0.0, "grass", "dirt", false),
		",": GridMesher.Block.new(0.0, "grass_dark", "dirt", false),
		"m": GridMesher.Block.new(0.0, "moss", "dirt", false),
		"=": GridMesher.Block.new(0.0, "path_stone", "dirt", false),
		"a": GridMesher.Block.new(0.0, "ash", "dirt", false),
		"#": GridMesher.Block.new(2.0, "grass_dark", "cliff_side", true),
		"^": GridMesher.Block.new(1.0, "grass", "cliff_side", true),
		"*": GridMesher.Block.new(1.0, "path_stone", "cliff_side", true),
		"W": GridMesher.Block.new(2.0, "wall_top", "wall_side", true),
		"~": GridMesher.Block.new(-0.6, "water", "dirt", true),
	}
	var level := MeshInstance3D.new()
	level.mesh = GridMesher.build_mesh(rows, legend, _materials())
	add_child(level)
	add_child(GridMesher.build_collision(rows, legend))
	_add_environment()
	for z in rows.size():
		for x in rows[z].length():
			var at := GridMesher.cell_center(x, z)
			match rows[z][x]:
				"T":
					_add_tree(at, x * 31 + z * 17)
				"P":
					_spawn_player(at)
				"D":
					_add_dummy(at)
				"*":
					_add_crystal(GridMesher.cell_center(x, z, 1.0))
	var cam := CameraRig.new()
	cam.target = _player
	cam.fov = 32.0
	cam.distance = 21.0
	add_child(cam)
	cam.make_current()
	cam.snap_to_target()


func _physics_process(delta: float) -> void:
	var move := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var target := Vector3(move.x, 0.0, move.y) * SPEED
	_player.velocity = _player.velocity.move_toward(target, 40.0 * delta)
	_player.move_and_slide()
	if move != Vector2.ZERO:
		_facing = move
	var dir_name := "side" if absf(_facing.x) >= absf(_facing.y) else ("up" if _facing.y < 0.0 else "down")
	_sprite.flip_h = dir_name == "side" and _facing.x < 0.0
	var anim := StringName(("walk_" if move != Vector2.ZERO else "idle_") + dir_name)
	if _sprite.animation != anim:
		_sprite.play(anim)


func _materials() -> Dictionary:
	var out := {}
	for tex_name in TERRAIN:
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = load(TERRAIN_DIR + tex_name + ".png")
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.texture_repeat = true
		mat.roughness = 1.0
		out[tex_name] = mat
	var water := StandardMaterial3D.new()
	water.albedo_color = Color(0.12, 0.3, 0.38)
	water.roughness = 0.05
	water.metallic_specular = 1.0
	water.emission_enabled = true
	water.emission = Color(0.03, 0.1, 0.13)
	out["water"] = water
	return out


func _add_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.07, 0.11, 0.16)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.62, 0.8)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.fog_enabled = true
	env.fog_light_color = Color(0.2, 0.26, 0.34)
	env.fog_density = 0.008
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-42.0, -40.0, 0.0)  # low dusk sun from the upper left
	moon.light_color = Color(1.0, 0.82, 0.62)
	moon.light_energy = 1.1
	moon.shadow_enabled = true
	add_child(moon)


func _spawn_player(at: Vector3) -> void:
	_player = CharacterBody3D.new()
	_player.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var col := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.4
	col.shape = capsule
	col.position.y = 0.7
	_player.add_child(col)
	_sprite = _make_sprite(SHEET)
	_player.add_child(_sprite)
	var lantern := OmniLight3D.new()
	lantern.light_color = Color(1.0, 0.72, 0.42)
	lantern.light_energy = 2.4
	lantern.omni_range = 6.5
	lantern.shadow_enabled = true
	lantern.position = Vector3(0.35, 0.7, 0.2)
	_player.add_child(lantern)
	add_child(_player)
	_player.global_position = at


func _add_dummy(at: Vector3) -> void:
	var s := _make_sprite(DUMMY_SHEET)
	add_child(s)
	s.global_position = at
	s.play(&"idle")


func _make_sprite(sheet: SpriteSheetDef) -> AnimatedSprite3D:
	var s := AnimatedSprite3D.new()
	s.sprite_frames = SpriteFramesBuilder.build(sheet)
	s.pixel_size = 1.0 / PIXELS_PER_METRE
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED  # upright on screen, like HD-2D
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.shaded = true
	s.offset = Vector2(0.0, sheet.frame_size.y / 2.0 - sheet.foot_inset)
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return s


func _add_tree(at: Vector3, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var tree := Node3D.new()
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.29, 0.2, 0.15)
	var trunk := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.12
	cyl.bottom_radius = 0.2
	cyl.height = 1.6
	cyl.radial_segments = 6
	cyl.material = bark
	trunk.mesh = cyl
	trunk.position.y = 0.8
	tree.add_child(trunk)
	var leaf_colors := [Color(0.16, 0.29, 0.17), Color(0.25, 0.42, 0.23), Color(0.37, 0.56, 0.31)]
	var leaf_tex: Texture2D = load(TERRAIN_DIR + "grass.png")
	for i in 3:
		var leaves := StandardMaterial3D.new()
		leaves.albedo_color = leaf_colors[i].lightened(0.35)
		leaves.albedo_texture = leaf_tex
		leaves.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		leaves.uv1_scale = Vector3(2, 2, 2)
		leaves.roughness = 1.0
		var blob := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		var r := rng.randf_range(0.75, 1.05) * (1.0 - i * 0.18)
		sphere.radius = r
		sphere.height = r * 1.7
		sphere.radial_segments = 7
		sphere.rings = 4
		sphere.material = leaves
		blob.mesh = sphere
		blob.position = Vector3(rng.randf_range(-0.2, 0.2), 1.7 + i * 0.45, rng.randf_range(-0.2, 0.2))
		tree.add_child(blob)
	tree.scale = Vector3.ONE * rng.randf_range(0.9, 1.25)
	add_child(tree)
	tree.global_position = at


func _add_crystal(at: Vector3) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.75, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.45, 0.72, 0.85)
	mat.emission_energy_multiplier = 2.0
	var crystal := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(0.35, 1.1, 0.35)
	prism.material = mat
	crystal.mesh = prism
	crystal.position = at + Vector3.UP * 0.55
	add_child(crystal)
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.5, 0.75, 1.0)
	glow.light_energy = 2.0
	glow.omni_range = 5.0
	glow.position = at + Vector3.UP * 1.0
	add_child(glow)
