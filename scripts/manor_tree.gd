class_name ManorTree
extends Node3D

func build(height_value: float, variation: int) -> void:
	var bark := ManorGeometry.material("756D55", 0.003)
	var fork := Vector3(0.025, 0.40, 0) * height_value
	_branch(Vector3.ZERO, fork, height_value * 0.045, height_value * 0.026, bark)
	for tip in [Vector3(-0.24, 0.64, 0.04), Vector3(0.23, 0.68, -0.05), Vector3(0, 0.79, -0.04)]:
		_branch(fork, tip * height_value, height_value * 0.026, height_value * 0.009, bark)
	ManorGeometry.barrier(self, Vector3(height_value * 0.09, height_value * 0.55, height_value * 0.09), Vector3(0, height_value * 0.275, 0))
	var crowns := [
		[Vector3(-0.03, 0.65, -0.23), Vector3(0.25, 0.12, 0.22), "8D9E73"],
		[Vector3(0.02, 0.55, 0.19), Vector3(0.25, 0.10, 0.21), "899B6F"],
		[Vector3(-0.24, 0.64, 0.04), Vector3(0.26, 0.13, 0.23), "98A97A"],
		[Vector3(0.23, 0.68, -0.05), Vector3(0.26, 0.14, 0.24), "9EAF80"],
		[Vector3(0, 0.79, -0.015), Vector3(0.29, 0.15, 0.26), "A6B686"],
	]
	for i in crowns.size():
		var canopy := MeshInstance3D.new()
		canopy.mesh = _crown_mesh(variation * 7 + i)
		var leaves: ShaderMaterial = ManorGeometry.material(crowns[i][2], 0.003).duplicate()
		leaves.set_shader_parameter("vertex_colors", true)
		canopy.material_override = leaves
		add_child(canopy)
		canopy.position = crowns[i][0] * height_value
		canopy.scale = crowns[i][1] * height_value
		canopy.rotation.y = variation * 0.73 + i * 1.17

func _branch(from: Vector3, to: Vector3, base: float, tip: float, mat: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = base
	mesh.top_radius = tip
	mesh.height = from.distance_to(to)
	mesh.radial_segments = 7
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	add_child(node)
	node.position = (from + to) / 2
	node.quaternion = Quaternion(Vector3.UP, (to - from).normalized())

func _crown_mesh(seed_value: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 613
	var radii: Array[float] = []
	for i in 10:
		radii.append(rng.randf_range(0.87, 1.12))
	var profile: Array[Vector2] = [Vector2(0, -0.8), Vector2(0.62, -0.58), Vector2(1, -0.16), Vector2(0.84, 0.40), Vector2(0.38, 0.86), Vector2(0, 1)]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Broad, quiet facets suggest painted foliage without individual leaf clutter.
	surface.set_smooth_group(-1)
	for p in range(profile.size() - 1):
		for i in 10:
			var corners: Array[Vector3] = []
			for pair in [Vector2i(p, i), Vector2i(p, (i + 1) % 10), Vector2i(p + 1, i), Vector2i(p + 1, (i + 1) % 10)]:
				var ring: Vector2 = profile[pair.x]
				var angle: float = pair.y * TAU / 10
				corners.append(Vector3(cos(angle) * ring.x * radii[pair.y], ring.y, sin(angle) * ring.x * radii[pair.y]))
			var tone := lerpf(0.84, 1.0, p / 4.0) * rng.randf_range(0.97, 1.0)
			for index in [0, 1, 2, 1, 3, 2]:
				surface.set_color(Color(tone, tone, tone))
				surface.add_vertex(corners[index])
	surface.generate_normals()
	return surface.commit()
