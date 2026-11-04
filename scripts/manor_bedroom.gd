class_name ManorBedroom
extends Node3D

func _ready() -> void:
	name = "BedroomFurnishings"
	var wood := ManorGeometry.material("8A6247", 0.008)
	var linen := ManorGeometry.material("E7E1D4", 0.006)
	var blue := ManorGeometry.material("6E86A8", 0.006)
	var brass := ManorGeometry.material("B39459", 0.003)
	ManorGeometry.box(self, Vector3(2.0, 0.006, 2.9), Vector3(-1.60, 0.004, -1.45), ManorGeometry.material("8FA3BF", 0.0))
	var bed := Node3D.new()
	bed.name = "Bed"
	add_child(bed)
	bed.position = Vector3(-1.60, 0, -1.90)
	for x in [-0.61, 0.61]:
		for z in [-0.88, 0.88]:
			ManorGeometry.box(bed, Vector3(0.09, 0.23, 0.09), Vector3(x, 0.115, z), wood)
	ManorGeometry.box(bed, Vector3(1.48, 0.18, 2.06), Vector3(0, 0.32, 0), wood)
	ManorGeometry.box(bed, Vector3(1.42, 0.17, 1.94), Vector3(0, 0.47, 0), linen)
	ManorGeometry.box(bed, Vector3(1.44, 0.08, 1.42), Vector3(0, 0.57, 0.25), blue)
	ManorGeometry.box(bed, Vector3(1.52, 0.65, 0.10), Vector3(0, 0.50, -1.0), wood)
	for x in [-0.34, 0.34]:
		ManorGeometry.box(bed, Vector3(0.58, 0.10, 0.34), Vector3(x, 0.60, -0.65), linen)
	ManorGeometry.barrier(bed, Vector3(1.52, 0.75, 2.12), Vector3(0, 0.375, 0))
	var bedside := Node3D.new()
	bedside.name = "BedsideTable"
	add_child(bedside)
	bedside.position = Vector3(-2.70, 0, -2.60)
	ManorGeometry.box(bedside, Vector3(0.48, 0.55, 0.50), Vector3(0, 0.275, 0), wood)
	ManorGeometry.box(bedside, Vector3(0.40, 0.16, 0.025), Vector3(0, 0.39, 0.265), ManorGeometry.material("987153", 0.004))
	ManorGeometry.cylinder(bedside, 0.018, 0.035, Vector3(0, 0.39, 0.30), brass).rotation.x = PI / 2
	ManorGeometry.cylinder(bedside, 0.075, 0.15, Vector3(0, 0.625, 0), blue)
	ManorGeometry.cylinder(bedside, 0.012, 0.12, Vector3(0, 0.76, 0), brass)
	var shade := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = 0.07
	shape.bottom_radius = 0.15
	shape.height = 0.16
	shape.radial_segments = 16
	shade.mesh = shape
	shade.material_override = ManorGeometry.material("DDD3BD", 0.004)
	shade.position.y = 0.88
	bedside.add_child(shade)
	ManorGeometry.barrier(bedside, Vector3(0.48, 0.55, 0.53), Vector3(0, 0.275, 0.015))
	var wardrobe := Node3D.new()
	wardrobe.name = "Wardrobe"
	add_child(wardrobe)
	wardrobe.position = Vector3(2.64, 0, 1.90)
	wardrobe.rotation.y = -PI / 2
	ManorGeometry.box(wardrobe, Vector3(1.38, 0.10, 0.62), Vector3(0, 0.05, 0), wood)
	ManorGeometry.box(wardrobe, Vector3(1.30, 1.85, 0.55), Vector3(0, 1.025, 0), wood)
	ManorGeometry.box(wardrobe, Vector3(1.38, 0.08, 0.62), Vector3(0, 1.99, 0), wood)
	for side in [-1, 1]:
		ManorGeometry.box(wardrobe, Vector3(0.60, 1.72, 0.035), Vector3(side * 0.325, 1.025, 0.29), ManorGeometry.material("967051", 0.006))
		ManorGeometry.cylinder(wardrobe, 0.012, 0.18, Vector3(side * 0.075, 1.02, 0.34), brass)
	ManorGeometry.barrier(wardrobe, Vector3(1.38, 2.03, 0.62), Vector3(0, 1.015, 0))
	_build_dresser(wood, brass)
	_build_reading_chair(wood, blue)
	var trim := ManorGeometry.material("D9C7AE", 0.0)
	for direction in 4:
		var wall := Node3D.new()
		add_child(wall)
		wall.position = ManorGeometry.DIRECTIONS[direction] * 2.98
		wall.rotation.y = -direction * PI / 2.0
		if direction in [ManorRules.N, ManorRules.W]:
			ManorGeometry.box(wall, Vector3(5.92, 0.15, 0.04), Vector3(0, 0.076, 0), trim)
		else:
			for side in [-1, 1]:
				ManorGeometry.box(wall, Vector3(2.25, 0.15, 0.04), Vector3(side * 1.835, 0.076, 0), trim)

func _build_dresser(wood: Material, brass: Material) -> void:
	var dresser := Node3D.new()
	dresser.name = "Dresser"
	add_child(dresser)
	dresser.position = Vector3(-1.90, 0, 2.60)
	dresser.rotation.y = PI
	ManorGeometry.box(dresser, Vector3(1.50, 0.84, 0.60), Vector3(0, 0.42, 0), wood)
	ManorGeometry.box(dresser, Vector3(1.58, 0.06, 0.66), Vector3(0, 0.87, 0), wood)
	var fronts := ManorGeometry.material("987153", 0.004)
	for y in [0.19, 0.44, 0.69]:
		ManorGeometry.box(dresser, Vector3(1.40, 0.20, 0.035), Vector3(0, y, 0.31), fronts)
		ManorGeometry.cylinder(dresser, 0.025, 0.04, Vector3(0, y, 0.36), brass).rotation.x = PI / 2
	ManorGeometry.barrier(dresser, Vector3(1.58, 0.90, 0.66), Vector3(0, 0.45, 0))
	ManorGeometry.box(dresser, Vector3(0.94, 1.06, 0.055), Vector3(0, 1.63, -0.34), wood)
	ManorGeometry.box(dresser, Vector3(0.80, 0.92, 0.018), Vector3(0, 1.63, -0.302), ManorGeometry.material("A6B5BB", 0.0))
	# Painted highlights suggest mirror glass without an expensive reflection viewport.
	var reflection := ManorGeometry.material("C9D0CD", 0.0)
	for offset in [-0.18, 0.12]:
		var shine := ManorGeometry.box(dresser, Vector3(0.025, 0.68, 0.006), Vector3(offset, 1.63, -0.289), reflection)
		shine.rotation.z = -0.30

func _build_reading_chair(wood: Material, fabric: Material) -> void:
	var chair := Node3D.new()
	chair.name = "ReadingChair"
	add_child(chair)
	chair.position = Vector3(2.10, 0, -2.0)
	chair.rotation.y = -PI / 4
	for x in [-0.27, 0.27]:
		for z in [-0.27, 0.27]:
			ManorGeometry.box(chair, Vector3(0.07, 0.37, 0.07), Vector3(x, 0.185, z), wood)
	ManorGeometry.box(chair, Vector3(0.68, 0.12, 0.72), Vector3(0, 0.43, 0), fabric)
	ManorGeometry.box(chair, Vector3(0.72, 0.58, 0.12), Vector3(0, 0.72, -0.32), fabric)
	for side in [-1, 1]:
		ManorGeometry.box(chair, Vector3(0.10, 0.28, 0.72), Vector3(side * 0.36, 0.57, 0), fabric)
	ManorGeometry.box(chair, Vector3(0.58, 0.05, 0.59), Vector3(0, 0.515, 0.025), ManorGeometry.material("8296AE", 0.006))
	ManorGeometry.barrier(chair, Vector3(0.82, 1.01, 0.85), Vector3(0, 0.505, -0.015))
