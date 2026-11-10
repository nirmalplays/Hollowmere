class_name GridMesher
## Builds a blocky 3D level from a text layout: one ArrayMesh with a surface per
## texture, plus box collision for anything that isn't walkable ground.
## Each character cell is 1x1 metre. Heights are in metres (0 = ground).

const CELL: float = 1.0


class Block:
	var height: float = 0.0
	var top: String = "floor_a"  ## texture name for the top face
	var side: String = "wall_face"  ## texture name for exposed side faces
	var solid: bool = false  ## blocks movement (walls, platforms, water)

	func _init(h: float, t: String, s: String, is_solid: bool) -> void:
		height = h
		top = t
		side = s
		solid = is_solid


## legend: character -> Block. Cells with unknown characters use legend["."].
## materials: texture name -> Material.
static func build_mesh(rows: PackedStringArray, legend: Dictionary, materials: Dictionary) -> ArrayMesh:
	var tools: Dictionary = {}  # texture name -> SurfaceTool
	var grid := _blocks(rows, legend)
	for z in grid.size():
		for x in grid[z].size():
			var b: Block = grid[z][x]
			_top_face(_tool(tools, b.top), x, z, b.height)
			# Expose a side wherever the neighbour is lower (or outside the map).
			for n in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
				var nb := _at(grid, x + n.x, z + n.y)
				var low := nb.height if nb else b.height - 2.0
				if low < b.height:
					_side_face(_tool(tools, b.side), x, z, n, low, b.height)
	var mesh := ArrayMesh.new()
	for tex_name: String in tools:
		var st: SurfaceTool = tools[tex_name]
		st.generate_tangents()
		st.commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, materials.get(tex_name))
	return mesh


## One StaticBody3D with a box per solid cell (walls, platforms, water edges).
static func build_collision(rows: PackedStringArray, legend: Dictionary) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = Const.LAYER_WORLD
	var grid := _blocks(rows, legend)
	for z in grid.size():
		for x in grid[z].size():
			var b: Block = grid[z][x]
			if not b.solid:
				continue
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(CELL, 3.0, CELL)
			shape.shape = box
			shape.position = Vector3(x + 0.5, 1.0, z + 0.5)
			body.add_child(shape)
	return body


static func cell_center(x: int, z: int, height: float = 0.0) -> Vector3:
	return Vector3(x + 0.5, height, z + 0.5)


static func _blocks(rows: PackedStringArray, legend: Dictionary) -> Array:
	var grid := []
	for line in rows:
		var row := []
		for ch in line:
			row.append(legend.get(ch, legend["."]))
		grid.append(row)
	return grid


static func _at(grid: Array, x: int, z: int) -> Block:
	if z < 0 or z >= grid.size() or x < 0 or x >= grid[z].size():
		return null
	return grid[z][x]


static func _tool(tools: Dictionary, tex_name: String) -> SurfaceTool:
	if not tools.has(tex_name):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		tools[tex_name] = st
	return tools[tex_name]


static func _quad(st: SurfaceTool, v: Array[Vector3], uv: Array[Vector2], normal: Vector3) -> void:
	for i in [0, 1, 2, 0, 2, 3]:
		st.set_normal(normal)
		st.set_uv(uv[i])
		st.add_vertex(v[i])


static func _top_face(st: SurfaceTool, x: int, z: int, h: float) -> void:
	_quad(st,
		[Vector3(x, h, z), Vector3(x + 1, h, z), Vector3(x + 1, h, z + 1), Vector3(x, h, z + 1)],
		[Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)],
		Vector3.UP)


## A vertical face on the cell edge facing `n`, from height `low` up to `high`.
## V runs down from the top edge, one texture repeat per metre.
static func _side_face(st: SurfaceTool, x: int, z: int, n: Vector2i, low: float, high: float) -> void:
	var a: Vector3
	var b: Vector3
	match n:
		Vector2i(0, 1):
			a = Vector3(x, 0, z + 1)
			b = Vector3(x + 1, 0, z + 1)
		Vector2i(0, -1):
			a = Vector3(x + 1, 0, z)
			b = Vector3(x, 0, z)
		Vector2i(-1, 0):
			a = Vector3(x, 0, z)
			b = Vector3(x, 0, z + 1)
		_:
			a = Vector3(x + 1, 0, z + 1)
			b = Vector3(x + 1, 0, z)
	var depth := high - low
	_quad(st,
		[a + Vector3.UP * high, b + Vector3.UP * high, b + Vector3.UP * low, a + Vector3.UP * low],
		[Vector2(0, 0), Vector2(1, 0), Vector2(1, depth), Vector2(0, depth)],
		Vector3(n.x, 0, n.y))
