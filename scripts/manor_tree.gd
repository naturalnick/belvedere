class_name ManorTree
extends Node3D

static var meshes: Dictionary[int, ArrayMesh] = {}
static var materials: Dictionary[bool, ShaderMaterial] = {}
var tree_height := 4.0
var variation := 0
var flat := false

func build(height_value: float, variant: int, flat_value: bool = false) -> void:
	tree_height = height_value
	variation = variant % 3
	flat = flat_value
	var canopy := MeshInstance3D.new()
	canopy.mesh = shared_mesh(flat)
	canopy.material_override = shared_material(flat)
	canopy.scale = Vector3(0.95 + variation * 0.05, 1, 1) * height_value
	canopy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if flat else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	# Billboard rotation must fit the batch bounds at every viewing angle.
	if flat:
		canopy.custom_aabb = AABB(Vector3(-0.55, 0, -0.55), Vector3(1.1, 1, 1.1))
	add_child(canopy)
	ManorGeometry.barrier(self, Vector3(height_value * 0.09, height_value * 0.55, height_value * 0.09), Vector3(0, height_value * 0.275, 0))

static func shared_material(flat_value: bool) -> ShaderMaterial:
	if not materials.has(flat_value):
		var material := ShaderMaterial.new()
		material.shader = preload("res://shaders/vegetation.gdshader")
		material.set_shader_parameter("flat_tree", flat_value)
		materials[flat_value] = material
	return materials[flat_value]

static func shared_mesh(flat_value: bool) -> ArrayMesh:
	var key := 1 if flat_value else 0
	if not meshes.has(key):
		meshes[key] = _flat_mesh(1) if flat_value else _solid_mesh(1)
	return meshes[key]

static func _solid_mesh(variant: int) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var fork := Vector3(0.025, 0.40, 0)
	_branch(surface, Vector3.ZERO, fork, 0.045, 0.026)
	for tip in [Vector3(-0.24, 0.64, 0.04), Vector3(0.23, 0.68, -0.05), Vector3(0, 0.79, -0.04)]:
		_branch(surface, fork, tip, 0.026, 0.009)
	for data in [
		[Vector3(-0.24, 0.64, 0.04), Vector3(0.29, 0.16, 0.28), "98A97A"],
		[Vector3(0.23, 0.68, -0.05), Vector3(0.29, 0.17, 0.29), "9EAF80"],
		[Vector3(0, 0.79, -0.015), Vector3(0.32, 0.17, 0.30), "A6B686"],
	]:
		var basis := Basis(Vector3.UP, variant * 0.7).scaled(data[1])
		_append(surface, _crown_mesh(variant), Transform3D(basis, data[0]), Color(data[2]))
	return surface.commit()

static func _branch(surface: SurfaceTool, from: Vector3, to: Vector3, base: float, tip: float) -> void:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = base
	mesh.top_radius = tip
	mesh.height = from.distance_to(to)
	mesh.radial_segments = 5
	mesh.rings = 0
	_append(surface, mesh, Transform3D(Basis(Quaternion(Vector3.UP, (to - from).normalized())), (from + to) / 2), Color("756D55"))

static func _append(surface: SurfaceTool, source: Mesh, transform: Transform3D, color: Color) -> void:
	var arrays := source.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var normal_basis := transform.basis.inverse().transposed()
	var light_direction := Vector3(-0.4, 0.8, 0.3).normalized()
	for i in indices.size() if not indices.is_empty() else vertices.size():
		var index := indices[i] if not indices.is_empty() else i
		var normal := (normal_basis * normals[index]).normalized()
		var tone := 0.78 + 0.22 * clampf(normal.dot(light_direction) * 0.5 + 0.5, 0, 1)
		surface.set_color((color * Color(tone, tone, tone)))
		surface.set_normal(normal)
		surface.add_vertex(transform * vertices[index])

static func _crown_mesh(variant: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 613 + variant
	var radii: Array[float] = []
	for i in 7:
		radii.append(rng.randf_range(0.9, 1.1))
	var profile: Array[Vector2] = [Vector2(0, -0.8), Vector2(1, -0.2), Vector2(0.8, 0.45), Vector2(0, 1)]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for p in range(profile.size() - 1):
		for i in 7:
			var corners: Array[Vector3] = []
			for pair in [Vector2i(p, i), Vector2i(p, (i + 1) % 7), Vector2i(p + 1, i), Vector2i(p + 1, (i + 1) % 7)]:
				var ring := profile[pair.x]
				var angle: float = pair.y * TAU / 7
				corners.append(Vector3(cos(angle) * ring.x * radii[pair.y], ring.y, sin(angle) * ring.x * radii[pair.y]))
			for triangle in [[0, 1, 2], [1, 3, 2]]:
				if (corners[triangle[1]] - corners[triangle[0]]).cross(corners[triangle[2]] - corners[triangle[0]]).length_squared() < 0.00001:
					continue
				for index in triangle:
					surface.add_vertex(corners[index])
	surface.generate_normals()
	return surface.commit()

static func _flat_mesh(variant: int) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var trunk: Array[Vector2] = [Vector2(-0.035, 0), Vector2(0.035, 0), Vector2(0.024, 0.55), Vector2(-0.018, 0.55)]
	for index in [0, 1, 2, 0, 2, 3]:
		surface.set_color(Color("756D55"))
		surface.add_vertex(Vector3(trunk[index].x, trunk[index].y, 0.005))
	var outline: Array[Vector2] = [Vector2(-0.50, 0.64), Vector2(-0.45, 0.73), Vector2(-0.33, 0.79), Vector2(-0.20, 0.77), Vector2(-0.12, 0.91), Vector2(0.04, 0.94), Vector2(0.20, 0.88), Vector2(0.25, 0.82), Vector2(0.38, 0.80), Vector2(0.49, 0.72), Vector2(0.47, 0.61), Vector2(0.30, 0.57), Vector2(0.10, 0.54), Vector2(-0.10, 0.54), Vector2(-0.30, 0.57)]
	var colors: Array[Color] = [Color("98A97A"), Color("9EAF80"), Color("A6B686")]
	for i in outline.size():
		var tone := 0.90 + (i % 3) * 0.035
		surface.set_color((colors[variant] * Color(tone, tone, tone)))
		for point in [Vector2(0, 0.70), outline[i], outline[(i + 1) % outline.size()]]:
			surface.add_vertex(Vector3(point.x * (0.95 + variant * 0.05), point.y, 0))
	return surface.commit()

static func bush_mesh() -> ArrayMesh:
	if not meshes.has(2):
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in 3:
			_append(surface, _crown_mesh(i), Transform3D(Basis(Vector3.UP, i * 2.1).scaled(Vector3(0.65, 0.45, 0.6)), Vector3((i - 1) * 0.45, 0.35 + i * 0.06, (i % 2) * 0.25)), Color("98A97A"))
		meshes[2] = surface.commit()
	return meshes[2]
