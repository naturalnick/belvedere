class_name ConservatoryArt
extends FurnitureKit

var key: Node3D
var key_hit: StaticBody3D
const PEDESTAL := Vector3(0, 0, 1.35)

func _ready() -> void:
	name = "Conservatory"
	ManorGeometry.box(self, Vector3(6.25, 0.20, 6.25), Vector3(0, -0.10, 0), ManorGeometry.floor_material(1), true)
	for direction in 4:
		var wall := group("Wall%d" % direction, ManorGeometry.DIRECTIONS[direction] * 3.0625, -direction * PI / 2.0)
		for side in [-1, 1]:
			box(wall, Vector3(2.40, 0.32, 0.125), Vector3(side * 1.80, 0.16, 0), "C8C6B3")
			solid(wall, Vector3(2.40, 3, 0.125), Vector3(side * 1.80, 1.5, 0))
			pane(wall, Vector3(2.24, 2.55, 0.018), Vector3(side * 1.80, 1.625, 0))
			for x in [0.65, 1.8, 2.96]:
				box(wall, Vector3(0.075, 3.0, 0.15), Vector3(side * x, 1.5, 0), CREAM, 0.0)
			for y in [0.35, 1.6]:
				box(wall, Vector3(2.4, 0.06, 0.15), Vector3(side * 1.8, y, 0), CREAM, 0.0)
		box(wall, Vector3(6.12, 0.13, 0.17), Vector3(0, 2.97, 0), CREAM, 0.0)
		box(wall, Vector3(1.3, 0.09, 0.15), Vector3(0, 2.25, 0), CREAM, 0.0)
		pane(wall, Vector3(1.2, 0.62, 0.018), Vector3(0, 2.62, 0))
		box(wall, Vector3(0.06, 0.65, 0.15), Vector3(0, 2.62, 0), CREAM, 0.0)
	_roof()
	_garden()
	var pedestal := group("KeyPedestal", PEDESTAL)
	box(pedestal, Vector3(0.54, 0.08, 0.54), Vector3(0, 0.04, 0), WOOD)
	box(pedestal, Vector3(0.43, 0.055, 0.43), Vector3(0, 0.108, 0), WOOD)
	box(pedestal, Vector3(0.29, 0.77, 0.29), Vector3(0, 0.52, 0), WOOD)
	for side in [-1, 1]:
		box(pedestal, Vector3(0.018, 0.64, 0.31), Vector3(side * 0.15, 0.52, 0), "A57C58", 0.0)
		box(pedestal, Vector3(0.31, 0.64, 0.018), Vector3(0, 0.52, side * 0.15), "A57C58", 0.0)
	box(pedestal, Vector3(0.43, 0.055, 0.43), Vector3(0, 0.925, 0), WOOD)
	box(pedestal, Vector3(0.62, 0.065, 0.55), Vector3(0, 0.985, 0), CREAM)
	box(pedestal, Vector3(0.53, 0.015, 0.46), Vector3(0, 1.025, 0), "547563", 0.0)
	solid(pedestal, Vector3(0.62, 1.04, 0.55), Vector3(0, 0.52, 0))
	key = group("RedKey", PEDESTAL + Vector3(0, 1.065, 0))
	key.rotation.y = -0.35
	var bow := ring(key, 0.065, 0.105, Vector3(-0.14, 0, 0), "BA5145")
	bow.scale.y = 0.55
	box(key, Vector3(0.31, 0.035, 0.045), Vector3(0.075, 0, 0), "BA5145", 0.002)
	for x in [0.14, 0.22]:
		box(key, Vector3(0.04, 0.035, 0.09), Vector3(x, 0, 0.055), "BA5145", 0.002)
	key_hit = ManorGeometry.barrier(key, Vector3(0.56, 0.16, 0.32), Vector3(0, 0.04, 0.02))
	ManorStaticBatch.combine(self, [key])

func pane(parent: Node3D, size: Vector3, at: Vector3) -> MeshInstance3D:
	var glass := ManorGeometry.box(parent, size, at, ManorGeometry.glass())
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return glass

func _roof() -> void:
	var rise := 1.35
	var span := 3.06
	var slope := atan2(rise, span)
	for side in [-1, 1]:
		var glass := pane(self, Vector3(Vector2(span, rise).length(), 0.018, 6.12), Vector3(side * span / 2, 3.0 + rise / 2, 0))
		glass.rotation.z = -side * slope
		for z in [-3.03, -1.52, 0.0, 1.52, 3.03]:
			rod(self, Vector3(side * span, 3.0, z), Vector3(0, 4.35, z), 0.045, CREAM)
		rod(self, Vector3(side * span / 2, 3.675, -3.06), Vector3(side * span / 2, 3.675, 3.06), 0.035, CREAM)
	rod(self, Vector3(0, 4.35, -3.10), Vector3(0, 4.35, 3.10), 0.065, CREAM)
	for z in [-3.06, 3.06]:
		for x in [-1.5, 0.0, 1.5]:
			rod(self, Vector3(x, 3.0, z), Vector3(x, 4.35 - absf(x) * rise / span, z), 0.035, CREAM)
		var triangle := SurfaceTool.new()
		triangle.begin(Mesh.PRIMITIVE_TRIANGLES)
		for point in [Vector3(-span, 3, z), Vector3(span, 3, z), Vector3(0, 4.35, z)]:
			triangle.add_vertex(point)
		triangle.generate_normals()
		var gable := MeshInstance3D.new()
		gable.mesh = triangle.commit()
		gable.material_override = ManorGeometry.glass()
		gable.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(gable)

func _garden() -> void:
	var plants := ConservatoryPlants.new()
	plants.name = "Planting"
	add_child(plants)
	plants.tree(Vector3(-0.25, 0, -0.80))
	# A paired seating area faces a shared tea table; the central crossing stays open.
	var rug := group("SeatingRug", Vector3(1.91, 0.008, 1.93))
	box(rug, Vector3(1.94, 0.008, 1.96), Vector3.ZERO, "A4AC8E", 0.0)
	box(rug, Vector3(1.78, 0.009, 1.80), Vector3(0, 0.001, 0), "C7CCB1", 0.0)
	_garden_chair("EastGardenChair", Vector3(2.48, 0, 1.12), -1.05)
	_garden_chair("SouthGardenChair", Vector3(1.65, 0, 2.48), PI - 0.10)
	var tea := group("TeaTable", Vector3(1.75, 0, 1.55))
	cylinder(tea, 0.34, 0.055, Vector3(0, 0.51, 0), WOOD)
	cylinder(tea, 0.30, 0.018, Vector3(0, 0.547, 0), "A57C58")
	for angle in [0.0, TAU / 3, TAU * 2 / 3]:
		rod(tea, Vector3(cos(angle) * 0.25, 0.035, sin(angle) * 0.25), Vector3(cos(angle) * 0.16, 0.49, sin(angle) * 0.16), 0.028, WOOD)
	solid(tea, Vector3(0.68, 0.56, 0.68), Vector3(0, 0.28, 0))
	for offset in [-0.14, 0.14]:
		cylinder(tea, 0.082, 0.012, Vector3(offset, 0.564, 0.015), CREAM)
		bowl(tea, Vector3(offset, 0.57, 0.015), 0.052, 0.08)
		var handle := ring(tea, 0.022, 0.031, Vector3(offset + 0.062, 0.61, 0.015), CREAM)
		handle.rotation.x = PI / 2
	var stand := table("PlantingBench", Vector3(-1.80, 0, -2.64), 1.66, 0.48, 0.62)
	box(stand, Vector3(1.53, 0.045, 0.38), Vector3(0, 0.20, 0), WOOD)
	plants.fern(Vector3(-2.25, 0.62, -2.63), 0.18, 0.25, 0.42)
	plants.broadleaf(Vector3(-1.35, 0.62, -2.63), 0.16, 0.23, 0.62)
	plants.broadleaf(Vector3(2.27, 0, -2.20), 0.30, 0.43, 1.25)
	plants.fern(Vector3(-2.22, 0, 1.85), 0.29, 0.42, 0.72)

func _garden_chair(label: String, at: Vector3, yaw: float) -> void:
	var chair := group(label, at, yaw)
	for x in [-0.31, 0.31]:
		for z in [-0.25, 0.25]:
			rod(chair, Vector3(x * 1.08, 0.035, z * 1.08), Vector3(x, 0.43, z), 0.032, WOOD)
		rod(chair, Vector3(x, 0.41, -0.25), Vector3(x, 0.98, -0.34), 0.027, WOOD)
		rod(chair, Vector3(x, 0.39, 0.23), Vector3(x, 0.67, 0.23), 0.023, WOOD)
		box(chair, Vector3(0.08, 0.055, 0.64), Vector3(x, 0.68, -0.015), WOOD)
		rod(chair, Vector3(x, 0.18, -0.25), Vector3(x, 0.18, 0.25), 0.016, WOOD)
	box(chair, Vector3(0.70, 0.065, 0.61), Vector3(0, 0.40, 0), WOOD)
	box(chair, Vector3(0.72, 0.065, 0.055), Vector3(0, 0.97, -0.34), WOOD)
	for x in [-0.17, 0.0, 0.17]:
		var slat := box(chair, Vector3(0.045, 0.49, 0.035), Vector3(x, 0.70, -0.29), WOOD)
		slat.rotation.x = -0.15
	_cushion(chair, Vector3(0.61, 0.13, 0.54), Vector3(0, 0.49, 0.01), "8D9E86")
	var back := _cushion(chair, Vector3(0.57, 0.37, 0.10), Vector3(0, 0.77, -0.24), "A4B29A")
	back.rotation.x = -0.15
	solid(chair, Vector3(0.73, 1.0, 0.70), Vector3(0, 0.5, -0.015))

func _cushion(parent: Node3D, size: Vector3, at: Vector3, color: String) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners: Array[Vector2] = [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]
	var rows: Array[PackedVector3Array] = []
	for level in 4:
		var edge := level in [0, 3]
		var inset := 0.025 if edge else 0.0
		var y: float = [-size.y / 2, -size.y / 2 + 0.025, size.y / 2 - 0.025, size.y / 2][level]
		var row := PackedVector3Array()
		for corner in corners:
			row.append(Vector3(corner.x * (size.x / 2 - inset), y, corner.y * (size.z / 2 - inset)))
		rows.append(row)
	for level in 3:
		for i in 4:
			var j := (i + 1) % 4
			for vertex in [rows[level][i], rows[level][j], rows[level + 1][i], rows[level][j], rows[level + 1][j], rows[level + 1][i]]:
				surface.add_vertex(vertex)
	for index in [0, 1, 2, 0, 2, 3]:
		surface.add_vertex(rows[3][index])
	for index in [0, 2, 1, 0, 3, 2]:
		surface.add_vertex(rows[0][index])
	surface.generate_normals()
	var cushion := MeshInstance3D.new()
	cushion.mesh = surface.commit()
	cushion.material_override = ManorGeometry.material(color, 0.003)
	parent.add_child(cushion)
	cushion.position = at
	return cushion
