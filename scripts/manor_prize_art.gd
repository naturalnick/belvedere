class_name ManorPrizeArt
extends RefCounted

const BELL_EMBLEM: Texture2D = preload("res://assets/bell_engraving.svg")

static func reward_label(parent: Control, text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color("F6EEE1"))
	label.add_theme_color_override("font_shadow_color", Color("30251B"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(label)
	return label

static func layout_reward_text(view_size: Vector2, title: Label, hint: Label) -> void:
	var text_scale := minf(view_size.x / 1100.0, view_size.y / 720.0)
	title.add_theme_font_size_override("font_size", maxi(24, int(64 * text_scale)))
	hint.add_theme_font_size_override("font_size", maxi(16, int(25 * text_scale)))
	title.position = view_size * Vector2(0.52, 0.5) - Vector2(0, 55 * text_scale)
	hint.position = view_size * Vector2(0.52, 0.5) + Vector2(0, 25 * text_scale)

static func trophy(parent: Node3D) -> Node3D:
	var result := Node3D.new()
	parent.add_child(result)
	var gold := ManorGeometry.material("D6AD55", 0.003)
	var bright := ManorGeometry.material("EED393", 0.002)
	ManorGeometry.box(result, Vector3(0.34, 0.055, 0.26), Vector3(0, 0.028, 0), ManorGeometry.material("364C50", 0.003))
	ManorGeometry.cylinder(result, 0.12, 0.035, Vector3(0, 0.072, 0), gold)
	ManorGeometry.cylinder(result, 0.035, 0.14, Vector3(0, 0.155, 0), gold)
	var cup := MeshInstance3D.new()
	cup.name = "BellCup"
	cup.mesh = _bell_cup()
	cup.material_override = gold
	result.add_child(cup)
	for side in [-1.0, 1.0]:
		var handle := MeshInstance3D.new()
		handle.name = "LeftHandle" if side < 0 else "RightHandle"
		handle.mesh = _trophy_handle(side)
		handle.material_override = gold
		result.add_child(handle)
	var rim := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.194
	ring.outer_radius = 0.211
	ring.rings = 32
	ring.ring_segments = 8
	rim.mesh = ring
	rim.material_override = bright
	rim.position.y = 0.456
	result.add_child(rim)
	return result

static func _trophy_handle(side: float) -> ArrayMesh:
	var start := Vector3(side * 0.160, 0.418, 0)
	var upper := Vector3(side * 0.320, 0.478, 0)
	var lower := Vector3(side * 0.290, 0.245, 0)
	var end := Vector3(side * 0.095, 0.275, 0)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for step in 25:
		var t := step / 24.0
		var u := 1.0 - t
		var center := start * u * u * u + upper * 3 * u * u * t + lower * 3 * u * t * t + end * t * t * t
		var tangent := ((upper - start) * 3 * u * u + (lower - upper) * 6 * u * t + (end - lower) * 3 * t * t).normalized()
		var across := Vector3(-tangent.y, tangent.x, 0)
		for segment in 8:
			var angle := segment * TAU / 8
			var normal := Vector3.BACK * cos(angle) + across * sin(angle)
			surface.set_normal(normal)
			surface.add_vertex(center + normal * 0.012)
	for step in 24:
		for segment in 8:
			var a := step * 8 + segment
			var b := step * 8 + (segment + 1) % 8
			for index in [a, b, a + 8, b, b + 8, a + 8]:
				surface.add_index(index)
	return surface.commit()

static func _bell_cup() -> ArrayMesh:
	# Closed outer/inner profile: the flared bell mouth has a real hollow interior.
	var profile: Array[Vector2] = [
		Vector2(0, 0.210), Vector2(0.045, 0.210), Vector2(0.071, 0.225),
		Vector2(0.085, 0.255), Vector2(0.095, 0.300), Vector2(0.110, 0.350),
		Vector2(0.140, 0.405), Vector2(0.176, 0.435), Vector2(0.205, 0.450),
		Vector2(0.205, 0.459), Vector2(0.191, 0.459), Vector2(0.187, 0.450),
		Vector2(0.164, 0.435), Vector2(0.127, 0.405), Vector2(0.097, 0.350),
		Vector2(0.081, 0.300), Vector2(0.071, 0.264), Vector2(0.052, 0.242),
		Vector2(0, 0.240),
	]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in range(profile.size() - 1):
		for segment in 32:
			var corners: Array[Vector3] = []
			for pair: Vector2i in [Vector2i(p, segment), Vector2i(p, segment + 1), Vector2i(p + 1, segment), Vector2i(p + 1, segment + 1)]:
				var angle := pair.y * TAU / 32
				var section := profile[pair.x]
				corners.append(Vector3(cos(angle) * section.x, section.y, sin(angle) * section.x))
			for index in [0, 1, 2, 1, 3, 2]:
				surface.add_vertex(corners[index])
	surface.generate_normals()
	return surface.commit()

static func coin(parent: Node3D) -> Node3D:
	var result := Node3D.new()
	parent.add_child(result)
	var blue := ManorGeometry.material("426C97", 0.001)
	var disk := ManorGeometry.cylinder(result, 0.067, 0.009, Vector3.ZERO, blue)
	disk.rotation.x = PI / 2
	# The toon shader's programs are already compiled. A StandardMaterial3D here froze slow machines
	# for seconds on the first insert, while its PBR shader compiled.
	var etched: ShaderMaterial = ManorGeometry.printed_material(BELL_EMBLEM)
	etched.set_shader_parameter("self_light", 0.0)
	etched.set_shader_parameter("print_cutout", true)
	for side in [-1, 1]:
		var face := ManorGeometry.cylinder(result, 0.054, 0.002, Vector3(0, 0, side * 0.0055), ManorGeometry.material("6F9FC8", 0.0))
		face.rotation.x = PI / 2
		var engraving := MeshInstance3D.new()
		var face_art := QuadMesh.new()
		face_art.size = Vector2(0.11, 0.11)
		engraving.mesh = face_art
		engraving.material_override = etched
		engraving.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		engraving.position.z = side * 0.0067
		engraving.rotation.y = PI if side < 0 else 0.0
		result.add_child(engraving)
	return result

static func draw_coin(canvas: Control, at: Vector2, radius: float, turn: float = 0.0, emblem: bool = false) -> void:
	# Keep drawing units in pixels: scaling a unit circle also scales its antialias fringe into a halo.
	canvas.draw_set_transform(at, 0, Vector2(maxf(0.12, absf(cos(turn))), 1))
	canvas.draw_circle(Vector2(0, radius * 0.025), radius, Color("355A80"), true, -1, true)
	canvas.draw_circle(Vector2.ZERO, radius * 0.96, Color("6F9FC8"), true, -1, true)
	canvas.draw_circle(Vector2.ZERO, radius * 0.82, Color("B4D2E8"), false, maxf(1.0, radius * 0.025), true)
	canvas.draw_circle(Vector2.ZERO, radius * 0.76, Color("426C97"), false, maxf(0.8, radius * 0.012), true)
	if radius > 30:
		for i in 32:
			var direction := Vector2.from_angle(i * TAU / 32)
			canvas.draw_line(direction * radius * 0.88, direction * radius * 0.92, Color("426C97"), 1.0, true)
	if emblem:
		var art_size := Vector2.ONE * radius * 1.85
		canvas.draw_texture_rect(BELL_EMBLEM, Rect2(-art_size / 2.0, art_size), false)
	canvas.draw_set_transform(Vector2.ZERO)
