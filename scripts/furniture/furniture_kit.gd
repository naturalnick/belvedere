class_name FurnitureKit
extends Node3D

const WOOD := "8A6247"
const BRASS := "B39459"
const CREAM := "E7E1D4"

func group(label: String, at: Vector3, yaw: float = 0.0) -> Node3D:
	var node := Node3D.new()
	node.name = label
	add_child(node)
	node.position = at
	node.rotation.y = yaw
	return node

func box(parent: Node3D, size: Vector3, at: Vector3, color: String, outline: float = 0.006) -> MeshInstance3D:
	return ManorGeometry.box(parent, size, at, ManorGeometry.material(color, outline))

func cylinder(parent: Node3D, radius: float, height: float, at: Vector3, color: String) -> MeshInstance3D:
	return ManorGeometry.cylinder(parent, radius, height, at, ManorGeometry.material(color, 0.003))

func solid(parent: Node3D, size: Vector3, at: Vector3) -> void:
	ManorGeometry.barrier(parent, size, at)

func rod(parent: Node3D, from: Vector3, to: Vector3, radius: float, color: String) -> void:
	var mesh := cylinder(parent, radius, from.distance_to(to), (from + to) / 2, color)
	mesh.quaternion = Quaternion(Vector3.UP, (to - from).normalized())

func globe(parent: Node3D, radius: float, at: Vector3, color: String) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2
	mesh.radial_segments = 16
	mesh.rings = 8
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = ManorGeometry.material(color, 0.004)
	parent.add_child(node)
	node.position = at
	return node

func ring(parent: Node3D, inner: float, outer: float, at: Vector3, color: String) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = 24
	mesh.ring_segments = 8
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = ManorGeometry.material(color, 0.002)
	parent.add_child(node)
	node.position = at
	return node

func legs(parent: Node3D, width: float, depth: float, height: float, color: String = WOOD) -> void:
	for x in [-width / 2 + 0.07, width / 2 - 0.07]:
		for z in [-depth / 2 + 0.07, depth / 2 - 0.07]:
			box(parent, Vector3(0.07, height, 0.07), Vector3(x, height / 2, z), color)

func table(label: String, at: Vector3, width: float, depth: float, height: float = 0.75, color: String = WOOD) -> Node3D:
	var node := group(label, at)
	legs(node, width, depth, height - 0.07, color)
	box(node, Vector3(width, 0.07, depth), Vector3(0, height - 0.035, 0), color)
	solid(node, Vector3(width, height, depth), Vector3(0, height / 2, 0))
	return node

func chair(label: String, at: Vector3, yaw: float, fabric: String, upholstered: bool = false) -> Node3D:
	var node := group(label, at, yaw)
	var width := 0.72 if upholstered else 0.46
	var depth := 0.70 if upholstered else 0.46
	legs(node, width, depth, 0.38)
	box(node, Vector3(width, 0.12, depth), Vector3(0, 0.44, 0), fabric)
	box(node, Vector3(width, 0.45, 0.09), Vector3(0, 0.725, -depth / 2 + 0.045), fabric if upholstered else WOOD)
	if upholstered:
		for side in [-1, 1]:
			box(node, Vector3(0.09, 0.24, depth), Vector3(side * (width / 2 + 0.025), 0.56, 0), fabric)
	solid(node, Vector3(width + (0.14 if upholstered else 0.0), 0.95, depth), Vector3(0, 0.475, 0))
	return node

func cabinet(label: String, at: Vector3, width: float, height: float, depth: float, color: String, yaw: float = 0.0) -> Node3D:
	var node := group(label, at, yaw)
	box(node, Vector3(width - 0.10, 0.09, depth - 0.08), Vector3(0, 0.045, 0), WOOD)
	box(node, Vector3(width, height - 0.15, depth), Vector3(0, (height - 0.15) / 2 + 0.09, 0), color)
	box(node, Vector3(width + 0.04, 0.06, depth + 0.04), Vector3(0, height - 0.03, 0), CREAM)
	for side in [-1, 1]:
		box(node, Vector3(width / 2 - 0.045, height - 0.24, 0.025), Vector3(side * width / 4, height / 2, depth / 2 + 0.016), color)
		cylinder(node, 0.018, 0.11, Vector3(side * 0.07, height * 0.64, depth / 2 + 0.045), BRASS)
	solid(node, Vector3(width + 0.04, height, depth + 0.08), Vector3(0, height / 2, 0.02))
	return node

func mirror(parent: Node3D, at: Vector3, width: float, height: float) -> void:
	box(parent, Vector3(width, height, 0.06), at, WOOD)
	box(parent, Vector3(width - 0.10, height - 0.10, 0.015), at + Vector3(0, 0, 0.04), "A6B5BB", 0.0)
	for x in [-width * 0.17, width * 0.14]:
		var shine := box(parent, Vector3(0.022, height * 0.65, 0.004), at + Vector3(x, 0, 0.052), "C9D0CD", 0.0)
		shine.rotation.z = -0.3

func lamp(parent: Node3D, at: Vector3, height: float) -> void:
	cylinder(parent, 0.11, 0.035, at + Vector3.UP * 0.018, BRASS)
	cylinder(parent, 0.015, height - 0.18, at + Vector3.UP * ((height - 0.18) / 2), BRASS)
	var shape := CylinderMesh.new()
	shape.top_radius = 0.10
	shape.bottom_radius = 0.20
	shape.height = 0.24
	shape.radial_segments = 16
	var shade := MeshInstance3D.new()
	shade.mesh = shape
	shade.material_override = ManorGeometry.material("DDD3BD", 0.004)
	parent.add_child(shade)
	shade.position = at + Vector3.UP * (height - 0.12)

# A hollow elliptical shell gives tubs and sinks a readable rim without a filled top.
func basin(parent: Node3D, at: Vector3, width: float, depth: float, height: float) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var inner_floor := minf(0.08, height * 0.22)
	var profiles := [Vector3(width * 0.39, 0, depth * 0.37), Vector3(width / 2, height, depth / 2), Vector3(width / 2 - 0.065, height, depth / 2 - 0.065), Vector3(width * 0.32, inner_floor, depth * 0.25), Vector3(0, inner_floor, 0)]
	for p in range(profiles.size() - 1):
		for i in 24:
			var corners: Array[Vector3] = []
			for pair in [Vector2i(p, i), Vector2i(p, i + 1), Vector2i(p + 1, i), Vector2i(p + 1, i + 1)]:
				var profile: Vector3 = profiles[pair.x]
				var angle: float = pair.y * TAU / 24
				corners.append(Vector3(cos(angle) * profile.x, profile.y, sin(angle) * profile.z))
			for index in [0, 1, 2, 1, 3, 2]:
				surface.set_color(Color(0.83, 0.87, 0.86) if p >= 2 else Color.WHITE)
				surface.add_vertex(corners[index])
	surface.generate_normals()
	var node := MeshInstance3D.new()
	node.mesh = surface.commit()
	var ceramic: ShaderMaterial = ManorGeometry.material("F4F1EA", 0.004).duplicate()
	ceramic.set_shader_parameter("vertex_colors", true)
	node.material_override = ceramic
	parent.add_child(node)
	node.position = at

func tap(parent: Node3D, at: Vector3) -> void:
	rod(parent, at, at + Vector3.UP * 0.23, 0.025, BRASS)
	rod(parent, at + Vector3.UP * 0.23, at + Vector3(0, 0.23, 0.20), 0.025, BRASS)
	rod(parent, at + Vector3(0, 0.23, 0.20), at + Vector3(0, 0.17, 0.20), 0.025, BRASS)

func skirting(id: int) -> void:
	for direction in 4:
		var wall := group("Skirting%d" % direction, ManorGeometry.DIRECTIONS[direction] * 2.98, -direction * PI / 2.0)
		if ManorRules.side(id, direction) == ManorRules.WINDOW:
			box(wall, Vector3(5.92, 0.12, 0.04), Vector3(0, 0.061, 0), "D9C7AE", 0.0)
		else:
			for side in [-1, 1]:
				box(wall, Vector3(2.25, 0.12, 0.04), Vector3(side * 1.835, 0.061, 0), "D9C7AE", 0.0)
