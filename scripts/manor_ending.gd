class_name ManorEnding
extends Node3D

const FLOWER_LIMIT := 72
var player: ManorPlayer
var active := false
var flowers: MultiMeshInstance3D
var rainbow: Node3D
var ages := PackedFloat32Array()
var positions := PackedVector3Array()
var rotations := PackedFloat32Array()
var spawned := 0
var total_spawned := 0
var spawn_clock := 0.0
var rng := RandomNumberGenerator.new()
var ground_y := -0.02

func _ready() -> void:
	rng.seed = 70123
	rainbow = Node3D.new()
	add_child(rainbow)
	rainbow.position = Vector3(0, 0, 36)
	for band in 7:
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		var outer := 10.5 - band * 0.32
		var inner := outer - 0.32
		for segment in 64:
			var a := float(segment) / 64 * PI
			var b := float(segment + 1) / 64 * PI
			var points := [Vector3(cos(a) * inner, sin(a) * inner, 0), Vector3(cos(a) * outer, sin(a) * outer, 0), Vector3(cos(b) * outer, sin(b) * outer, 0), Vector3(cos(b) * inner, sin(b) * inner, 0)]
			for i in [0, 1, 2, 0, 2, 3]:
				surface.set_normal(Vector3.FORWARD)
				surface.set_uv(Vector2(0, float(band + (1 if i in [0, 3] else 0)) / 7.0))
				surface.add_vertex(points[i])
		var mesh := MeshInstance3D.new()
		mesh.mesh = surface.commit()
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://shaders/rainbow.gdshader")
		mat.set_shader_parameter("band_color", Color(["D28B89", "D7AB82", "DACA93", "9EB58D", "8CB6BA", "929DBD", "B29DBD"][band]))
		mat.set_shader_parameter("reveal", 0.0)
		mesh.material_override = mat
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		rainbow.add_child(mesh)
	rainbow.hide()
	flowers = MultiMeshInstance3D.new()
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = _flower_mesh()
	instances.use_colors = true
	instances.instance_count = FLOWER_LIMIT
	instances.visible_instance_count = 0
	flowers.multimesh = instances
	var flower_material: ShaderMaterial = ManorGeometry.material("FFFFFF", 0.0).duplicate()
	flower_material.set_shader_parameter("vertex_colors", true)
	flowers.material_override = flower_material
	flowers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(flowers)
	ages.resize(FLOWER_LIMIT)
	positions.resize(FLOWER_LIMIT)
	rotations.resize(FLOWER_LIMIT)

func activate() -> void:
	if active:
		return
	active = true
	rainbow.show()
	var fade := create_tween().set_parallel(true)
	for mesh: MeshInstance3D in rainbow.get_children():
		fade.tween_property(mesh.material_override, "shader_parameter/reveal", 1.0, 2.5)

func _process(delta: float) -> void:
	if not active or player == null:
		return
	if absf(player.global_position.x) > 9.4 or absf(player.global_position.z) > 9.4:
		spawn_clock += delta
		while spawn_clock >= 0.30:
			spawn_clock -= 0.30
			_sprout()
	for i in spawned:
		ages[i] += delta
		var growth := smoothstep(0.0, 0.8, ages[i]) * (1.0 - smoothstep(19.0, 21.5, ages[i]))
		var basis := Basis(Vector3.UP, rotations[i]).scaled(Vector3.ONE * maxf(growth, 0.001))
		flowers.multimesh.set_instance_transform(i, Transform3D(basis, positions[i]))

func _sprout() -> void:
	for attempt in 12:
		var angle := rng.randf_range(0, TAU)
		if rng.randf() < 0.85:
			var forward := -player.global_basis.z
			angle = atan2(forward.z, forward.x) + rng.randf_range(-PI / 3.0, PI / 3.0)
		var radius := rng.randf_range(2.5, 7.0)
		var at := player.global_position + Vector3(cos(angle), 0, sin(angle)) * radius
		if absf(at.x) < 9.55 and absf(at.z) < 9.55:
			continue
		if absf(at.x) < 1.15 and at.z > 9.2 and at.z < 23.0:
			continue
		at.y = ground_y
		var index := total_spawned % FLOWER_LIMIT
		positions[index] = at
		ages[index] = 0
		rotations[index] = angle
		flowers.multimesh.set_instance_color(index, Color("EDC9D7") if rng.randf() < 0.5 else Color("F0EFE7"))
		total_spawned += 1
		spawned = mini(spawned + 1, FLOWER_LIMIT)
		flowers.multimesh.visible_instance_count = spawned
		return

func _flower_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stem := Color("617A55")
	for angle in [0.0, PI / 2.0]:
		var side := Vector3(cos(angle), 0, sin(angle)) * 0.002
		_quad(surface, [-side, side, side + Vector3.UP * 0.08, -side + Vector3.UP * 0.08], stem)
	for petal in 5:
		var angle := petal * TAU / 5.0
		var center := Vector3(cos(angle) * 0.019, 0.08, sin(angle) * 0.019)
		_disc(surface, center, 0.013, Color.WHITE)
	_disc(surface, Vector3(0, 0.081, 0), 0.006, Color("C7B275"))
	return surface.commit()

func _quad(surface: SurfaceTool, points: Array, color: Color) -> void:
	# Two-sided petals and crossed stems remain readable from a first-person camera.
	for index in [0, 1, 2, 0, 2, 3, 2, 1, 0, 3, 2, 0]:
		surface.set_color(color)
		surface.set_normal(Vector3.UP)
		surface.add_vertex(points[index])

func _disc(surface: SurfaceTool, center: Vector3, radius: float, color: Color) -> void:
	for segment in 8:
		var a := segment * TAU / 8.0
		var b := (segment + 1) * TAU / 8.0
		var points := [center, center + Vector3(cos(a), 0, sin(a)) * radius, center + Vector3(cos(b), 0, sin(b)) * radius]
		for index in [0, 1, 2, 2, 1, 0]:
			surface.set_color(color)
			surface.set_normal(Vector3.UP)
			surface.add_vertex(points[index])
