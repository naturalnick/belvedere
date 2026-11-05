class_name ConservatoryPlants
extends FurnitureKit

func pot(label: String, at: Vector3, radius: float, height: float, color: String = "AE826B") -> Node3D:
	var node := group(label, at)
	var profile: Array[Vector2] = [Vector2(0.69, 0), Vector2(0.76, 0.04), Vector2(0.76, 0.12), Vector2(0.92, 0.84), Vector2(1, 0.85), Vector2(1, 0.96), Vector2(0.96, 1), Vector2(0.84, 1), Vector2(0.82, 0.91), Vector2(0.78, 0.81)]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in profile.size() - 1:
		for i in 24:
			var points: Array[Vector3] = []
			for pair in [Vector2i(p, i), Vector2i(p, i + 1), Vector2i(p + 1, i), Vector2i(p + 1, i + 1)]:
				var section := profile[pair.x]
				var angle: float = pair.y * TAU / 24
				points.append(Vector3(cos(angle) * section.x * radius, section.y * height, sin(angle) * section.x * radius))
			for index in [0, 1, 2, 1, 3, 2]:
				surface.add_vertex(points[index])
	surface.generate_normals()
	var vessel := MeshInstance3D.new()
	vessel.mesh = surface.commit()
	vessel.material_override = ManorGeometry.material(color, 0.002)
	node.add_child(vessel)
	cylinder(node, radius * 0.82, 0.018, Vector3(0, height * 0.86, 0), "655749")
	solid(node, Vector3(radius * 1.8, height, radius * 1.8), Vector3(0, height / 2, 0))
	return node

func tree(at: Vector3) -> void:
	var planter := pot("TreePlanter", at, 0.58, 0.52, "B18B73")
	var foliage := MeshInstance3D.new()
	foliage.name = "BroadleafTree"
	foliage.mesh = ManorTree.tree_model(ManorTree.Kind.BROADLEAF, 2, false)
	foliage.material_override = ManorTree.shared_material()
	foliage.position.y = 0.46
	foliage.scale = Vector3(2.55, 2.80, 2.55)
	planter.add_child(foliage)
	rod(planter, Vector3(0, 0.45, 0), Vector3(0, 1.5, 0), 0.085, "756D55")

func fern(at: Vector3, radius: float, height: float, spread: float) -> void:
	var planter := pot("Fern", at, radius, height)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var root := Vector3(0, height * 0.87, 0)
	for frond in 9:
		var angle := frond * TAU / 9 + 0.23
		var reach := spread * (0.82 + 0.12 * (frond % 3))
		var direction := Vector3(cos(angle), 0, sin(angle))
		var side := Vector3(-direction.z, 0, direction.x)
		var previous := root
		for step in range(1, 8):
			var t := step / 8.0
			var center := root + direction * reach * t + Vector3.UP * spread * (sin(t * PI * 0.85) * 0.66 + 0.12)
			_stem(surface, previous, center, 0.007)
			previous = center
			var length := spread * 0.34 * sin(t * PI)
			for sign_value in [-1, 1]:
				var tip: Vector3 = center + side * sign_value * length + direction * length * 0.55 + Vector3.DOWN * length * 0.16
				_leaf(surface, center, tip, length * 0.48, Color("6D8C60") if (step + frond) % 2 == 0 else Color("8DA373"))
		_leaf(surface, previous, root + direction * reach + Vector3.UP * spread * 0.30, spread * 0.10, Color("8DA373"))
	_finish_leaves(planter, surface)

func broadleaf(at: Vector3, radius: float, height: float, growth: float) -> void:
	var planter := pot("LeafyPlant", at, radius, height, "8C9D86")
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var root := Vector3(0, height * 0.87, 0)
	for leaf in 11:
		var angle := leaf * 2.4
		var direction := Vector3(cos(angle), 0, sin(angle))
		var stalk := root + direction * growth * 0.12 + Vector3.UP * growth * (0.30 + (leaf % 4) * 0.12)
		_stem(surface, root, stalk, 0.012)
		var tip := stalk + direction * growth * (0.38 + 0.05 * (leaf % 3)) + Vector3.UP * growth * (0.16 if leaf % 3 == 0 else -0.06)
		_leaf(surface, stalk, tip, growth * 0.24, Color("617F64") if leaf % 2 == 0 else Color("8EA47B"))
	_finish_leaves(planter, surface)

# Folded, tapering blades have a raised midrib and a curved silhouette from either side.
func _leaf(surface: SurfaceTool, base: Vector3, tip: Vector3, width: float, color: Color) -> void:
	var across := (tip - base).cross(Vector3.UP).normalized()
	var rows: Array[Vector3] = []
	for i in 5:
		var t := i / 4.0
		var bulge := sin(PI * t)
		var center := base.lerp(tip, t) + Vector3.UP * bulge * width * 0.30
		rows.append(center - across * width * 0.5 * bulge - Vector3.UP * bulge * width * 0.14)
		rows.append(center)
		rows.append(center + across * width * 0.5 * bulge - Vector3.UP * bulge * width * 0.14)
	for row in 4:
		for half in 2:
			var a := row * 3 + half
			for triangle in [Vector3i(a, a + 3, a + 1), Vector3i(a + 1, a + 3, a + 4)]:
				var normal := (rows[triangle.y] - rows[triangle.x]).cross(rows[triangle.z] - rows[triangle.x])
				if normal.length_squared() < 0.0000001:
					continue
				for back in [false, true]:
					for index in [triangle.x, triangle.z if back else triangle.y, triangle.y if back else triangle.z]:
						surface.set_normal(normal.normalized() * (-1.0 if back else 1.0))
						surface.set_color(color.darkened(0.10) if half == 0 else color)
						surface.add_vertex(rows[index])

func _finish_leaves(parent: Node3D, surface: SurfaceTool) -> void:
	var leaves := MeshInstance3D.new()
	leaves.name = "Leaves"
	leaves.mesh = surface.commit()
	leaves.material_override = ManorGeometry.vertex_color_material("FFFFFF", 0.0)
	parent.add_child(leaves)

func _stem(surface: SurfaceTool, base: Vector3, tip: Vector3, radius: float) -> void:
	var up := (tip - base).normalized()
	var across := up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
	var other := up.cross(across)
	for i in 6:
		var a := i * TAU / 6
		var b := (i + 1) * TAU / 6
		var da := across * cos(a) + other * sin(a)
		var db := across * cos(b) + other * sin(b)
		for point in [base + da * radius, tip + da * radius, base + db * radius, base + db * radius, tip + da * radius, tip + db * radius]:
			surface.set_normal((da + db).normalized())
			surface.set_color(Color("617D53"))
			surface.add_vertex(point)
