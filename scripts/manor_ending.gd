class_name ManorEnding
extends Node3D

const FLOWER_LIMIT := 160
const SPROUT_INTERVAL := 0.15
const WALK_SECONDS := 20.0
const TITLE_FADE_SECONDS := 10.0
const CREDIT_FADE_SECONDS := 4.0
const CREDIT_GAP_SECONDS := 3.0
const THANKS_FADE_SECONDS := 4.0
var player: ManorPlayer
var active := false
var flowers: MultiMeshInstance3D
var rainbow: Node3D
var title: Label3D
var credit: Label3D
var thanks: Label3D
var ages := PackedFloat32Array()
var positions := PackedVector3Array()
var rotations := PackedFloat32Array()
var spawned := 0
var total_spawned := 0
var spawn_clock := 0.0
var rng := RandomNumberGenerator.new()
var ground_y := -0.02
var reveal_motion: Tween

func _ready() -> void:
	set_process(false)
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
	title = _lettering("Belvedere", 8.0, 1.8)
	# Bring the lower lines closer so they sit farther down the view without sinking into the grass.
	credit = _lettering("A game by Nick Schaefer", 3.6, 0.50, 30.0)
	thanks = _lettering("Thank you for playing", 1.96, 0.25, 27.0)
	flowers = MultiMeshInstance3D.new()
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = _flower_mesh()
	instances.use_colors = true
	instances.instance_count = FLOWER_LIMIT
	instances.visible_instance_count = 0
	flowers.multimesh = instances
	flowers.material_override = ManorGeometry.vertex_color_material("FFFFFF", 0.0)
	flowers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(flowers)
	ages.resize(FLOWER_LIMIT)
	positions.resize(FLOWER_LIMIT)
	rotations.resize(FLOWER_LIMIT)

func _lettering(words: String, width_value: float, height_value: float, depth: float = 35.8) -> Label3D:
	var label := Label3D.new()
	label.text = words
	label.font = preload("res://assets/fonts/Fondamento-Regular.ttf")
	label.font_size = 192
	label.pixel_size = width_value / label.font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, label.font_size).x
	label.position = Vector3(0, height_value, depth)
	label.rotation.y = PI
	label.modulate = Color(1, 1, 1, 0)
	label.outline_size = 0
	label.no_depth_test = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(label)
	label.hide()
	return label

func begin_sequence() -> void:
	for label in [title, credit, thanks]:
		label.modulate.a = 0.0
		label.show()

func activate() -> void:
	if active:
		return
	active = true
	set_process(true)
	rainbow.show()
	reveal_motion = create_tween().set_parallel(true)
	for mesh: MeshInstance3D in rainbow.get_children():
		reveal_motion.tween_property(mesh.material_override, "shader_parameter/reveal", 1.0, 2.5)

func reset() -> void:
	active = false
	set_process(false)
	if reveal_motion != null:
		reveal_motion.kill()
	rainbow.hide()
	for mesh: MeshInstance3D in rainbow.get_children():
		mesh.material_override.set_shader_parameter("reveal", 0.0)
	for label in [title, credit, thanks]:
		label.hide()
	spawned = 0
	total_spawned = 0
	spawn_clock = 0.0
	flowers.multimesh.visible_instance_count = 0

func _process(delta: float) -> void:
	if not active or player == null or player.manor.play_gate.visible or player.manor.at_title:
		return
	if absf(player.global_position.x) > 9.4 or absf(player.global_position.z) > 9.4:
		spawn_clock += delta
		while spawn_clock >= SPROUT_INTERVAL:
			spawn_clock -= SPROUT_INTERVAL
			_sprout()
	for i in spawned:
		ages[i] += delta
		var growth := smoothstep(0.0, 0.8, ages[i]) * (1.0 - smoothstep(19.0, 21.5, ages[i]))
		var basis := Basis(Vector3.UP, rotations[i]).scaled(Vector3.ONE * maxf(growth, 0.001))
		flowers.multimesh.set_instance_transform(i, Transform3D(basis, positions[i]))

func _sprout() -> void:
	var camera := player.camera
	if not camera.is_current() or player.manor.play_gate.visible or player.manor.at_title:
		return
	var viewport_size := camera.get_viewport().get_visible_rect().size
	var visible_area := Rect2(viewport_size * 0.06, viewport_size * 0.88)
	var forward := -camera.global_basis.z
	for attempt in 24:
		var angle := atan2(forward.z, forward.x) + rng.randf_range(-PI / 3.0, PI / 3.0)
		var radius := rng.randf_range(2.5, 12.0)
		var at := player.global_position + Vector3(cos(angle), 0, sin(angle)) * radius
		if absf(at.x) < 9.55 and absf(at.z) < 9.55:
			continue
		if absf(at.x) < 1.15 and at.z > 9.2 and at.z < 23.0:
			continue
		at.y = ground_y
		# A forward cone alone can still plant off-screen at narrow FOVs or below the frame.
		if not camera.is_position_in_frustum(at) or not visible_area.has_point(camera.unproject_position(at)):
			continue
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
	for petal in 5:
		var angle := petal * TAU / 5.0
		var center := Vector3(cos(angle) * 0.019, 0.012, sin(angle) * 0.019)
		_disc(surface, center, 0.013, Color.WHITE)
	_disc(surface, Vector3(0, 0.013, 0), 0.006, Color("C7B275"))
	return surface.commit()

func _disc(surface: SurfaceTool, center: Vector3, radius: float, color: Color) -> void:
	for segment in 8:
		var a := segment * TAU / 8.0
		var b := (segment + 1) * TAU / 8.0
		var points := [center, center + Vector3(cos(a), 0, sin(a)) * radius, center + Vector3(cos(b), 0, sin(b)) * radius]
		for index in [0, 1, 2, 2, 1, 0]:
			surface.set_color(color)
			surface.set_normal(Vector3.UP)
			surface.add_vertex(points[index])
