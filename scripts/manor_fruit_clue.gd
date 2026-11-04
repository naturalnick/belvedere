class_name ManorFruitClue
extends Node3D

const ROOMS: Array[int] = [3, 6, 5, 0]
const COUNTS: Array[int] = [3, 2, 4, 1]
const COLORS: Array[String] = ["C83C32", "F3CB45", "ED862C", "82AC43"]
const FRUITS: Array[String] = ["Apple", "Banana", "Orange", "Pear"]

var room: ManorRoom
var kind: int
var fruits: Array[Node3D] = []
var clue_materials: Dictionary[String, ShaderMaterial] = {}
var last_origin := Vector3.INF
var last_closed_doors := Vector4(-1, -1, -1, -1)

func _ready() -> void:
	name = FRUITS[kind] + "Clue"
	var positions: Array[Vector3] = []
	match kind:
		0:
			for z in [1.99, 2.28, 2.57]:
				positions.append(Vector3(-1.88, 0.90, z))
		1:
			for z in [1.56, 2.24]:
				positions.append(Vector3(2.48, 0.68, z))
		2:
			for z in [1.00, 1.40, 1.80, 2.20]:
				positions.append(Vector3(2.65, 0.90, z))
		3:
			positions.append(Vector3(-2.36, 0.90, 2.43))
	for at in positions:
		var fruit := Node3D.new()
		fruit.name = FRUITS[kind] + str(fruits.size() + 1)
		add_child(fruit)
		fruit.position = at
		fruits.append(fruit)
		if kind == 1:
			fruit.rotation.y = -PI / 2
			_banana(fruit)
		else:
			_round_fruit(fruit)
	_sync_origin()
	_sync_doors()

func _material(color: String) -> ShaderMaterial:
	if not clue_materials.has(color):
		# No outline pass or cast shadows: neither may reveal invisible fruit indoors.
		var mat: ShaderMaterial = ManorGeometry.material(color, 0.0).duplicate()
		mat.set_shader_parameter("window_clue", true)
		var windows := Vector4.ZERO
		for d in 4:
			windows[d] = float(ManorRules.side(room.room_id, d) == ManorRules.WINDOW)
		mat.set_shader_parameter("clue_windows", windows)
		clue_materials[color] = mat
	return clue_materials[color]

func _mesh(parent: Node3D, mesh: Mesh, color: String, at: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _material(color)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	node.position = at
	return node

func _round_fruit(parent: Node3D) -> void:
	var profile: Array[Vector2]
	match kind:
		0: profile = [Vector2(0, 0.015), Vector2(0.075, 0.008), Vector2(0.112, 0.055), Vector2(0.124, 0.13), Vector2(0.11, 0.205), Vector2(0.065, 0.235), Vector2(0, 0.21)]
		2: profile = [Vector2(0, 0.005), Vector2(0.078, 0.027), Vector2(0.118, 0.08), Vector2(0.126, 0.13), Vector2(0.108, 0.195), Vector2(0.063, 0.237), Vector2(0, 0.25)]
		3: profile = [Vector2(0, 0.008), Vector2(0.08, 0.01), Vector2(0.125, 0.07), Vector2(0.132, 0.145), Vector2(0.105, 0.215), Vector2(0.06, 0.28), Vector2(0.045, 0.35), Vector2(0, 0.375)]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in range(profile.size() - 1):
		for segment in 24:
			var corners: Array[Vector3] = []
			for pair: Vector2i in [Vector2i(p, segment), Vector2i(p, segment + 1), Vector2i(p + 1, segment), Vector2i(p + 1, segment + 1)]:
				var angle := pair.y * TAU / 24
				var section := profile[pair.x]
				var radius := section.x * (1.0 + 0.035 * cos(angle * 5.0) if kind == 0 else 1.0)
				corners.append(Vector3(cos(angle) * radius, section.y, sin(angle) * radius))
			for index in [0, 1, 2, 1, 3, 2]:
				surface.add_vertex(corners[index])
	surface.generate_normals()
	_mesh(parent, surface.commit(), COLORS[kind])
	var top := 0.215 if kind == 0 else (0.245 if kind == 2 else 0.37)
	_stem(parent, Vector3(0, top, 0), Vector3(0.014, top + (0.012 if kind == 2 else 0.055), 0.006), 0.012)
	if kind != 2:
		var leaf := SphereMesh.new()
		leaf.radius = 0.045
		leaf.height = 0.09
		leaf.radial_segments = 12
		leaf.rings = 6
		var node := _mesh(parent, leaf, "507538", Vector3(0.043, top + 0.035, 0))
		node.scale = Vector3(1.0, 0.16, 0.43)
		node.rotation.z = 0.3

func _banana(parent: Node3D) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for segment in 16:
		for side in 8:
			var corners: Array[Vector3] = []
			for pair: Vector2i in [Vector2i(segment, side), Vector2i(segment, side + 1), Vector2i(segment + 1, side), Vector2i(segment + 1, side + 1)]:
				var t := pair.x / 16.0
				var angle := lerpf(-1.12, 1.12, t)
				var radial := Vector3(sin(angle), 0, cos(angle))
				var center := Vector3(sin(angle) * 0.24, 0.052, cos(angle) * 0.24 - 0.17)
				var radius := 0.012 + 0.039 * pow(sin(t * PI), 0.6)
				var around := pair.y * TAU / 8
				corners.append(center + (Vector3.UP * sin(around) + radial * cos(around)) * radius)
			for index in [0, 2, 1, 1, 2, 3]:
				surface.add_vertex(corners[index])
	surface.generate_normals()
	_mesh(parent, surface.commit(), COLORS[kind])
	for sign_value in [-1, 1]:
		var end := Vector3(sign_value * sin(1.12) * 0.24, 0.052, cos(1.12) * 0.24 - 0.17)
		_stem(parent, end, end + Vector3(sign_value * 0.022, 0.006, -0.025), 0.013)

func _stem(parent: Node3D, from: Vector3, to: Vector3, radius: float) -> void:
	var shape := CylinderMesh.new()
	shape.top_radius = radius * 0.75
	shape.bottom_radius = radius
	shape.height = from.distance_to(to)
	shape.radial_segments = 8
	var node := _mesh(parent, shape, "675039", (from + to) / 2)
	node.quaternion = Quaternion(Vector3.UP, (to - from).normalized())

func _process(_delta: float) -> void:
	_sync_origin()
	_sync_doors()

func _sync_origin() -> void:
	if room.global_position == last_origin:
		return
	last_origin = room.global_position
	for mat in clue_materials.values():
		mat.set_shader_parameter("clue_room_origin", last_origin)

func _sync_doors() -> void:
	var closed := Vector4.ZERO
	for door in room.doors:
		if not door.is_front and not door.opened and door.leaves.all(func(leaf: Node3D) -> bool: return absf(leaf.rotation.y) < 0.001):
			closed[door.direction] = 1.0
	if closed == last_closed_doors:
		return
	last_closed_doors = closed
	for mat in clue_materials.values():
		mat.set_shader_parameter("clue_closed_doors", closed)
