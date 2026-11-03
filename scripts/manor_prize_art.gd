class_name ManorPrizeArt
extends RefCounted

const BELL_EMBLEM: Texture2D = preload("res://assets/bell_engraving.svg")

static func trophy(parent: Node3D) -> Node3D:
	var result := Node3D.new()
	parent.add_child(result)
	var gold := ManorGeometry.material("D6AD55", 0.003)
	var bright := ManorGeometry.material("EED393", 0.002)
	ManorGeometry.box(result, Vector3(0.34, 0.055, 0.26), Vector3(0, 0.028, 0), ManorGeometry.material("364C50", 0.003))
	ManorGeometry.cylinder(result, 0.12, 0.035, Vector3(0, 0.072, 0), gold)
	ManorGeometry.cylinder(result, 0.035, 0.14, Vector3(0, 0.155, 0), gold)
	var cup := MeshInstance3D.new()
	var bowl := CylinderMesh.new()
	bowl.top_radius = 0.19
	bowl.bottom_radius = 0.065
	bowl.height = 0.25
	bowl.cap_top = false
	bowl.radial_segments = 32
	cup.mesh = bowl
	cup.material_override = gold
	cup.position.y = 0.335
	result.add_child(cup)
	ManorGeometry.cylinder(result, 0.178, 0.012, Vector3(0, 0.442, 0), ManorGeometry.material("8D642B", 0.0))
	for side in [-1, 1]:
		var handle := MeshInstance3D.new()
		var ring := TorusMesh.new()
		ring.inner_radius = 0.075
		ring.outer_radius = 0.098
		ring.rings = 24
		ring.ring_segments = 8
		handle.mesh = ring
		handle.material_override = gold
		handle.rotation.x = PI / 2
		handle.position = Vector3(side * 0.165, 0.335, 0)
		result.add_child(handle)
	var rim := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.178
	ring.outer_radius = 0.195
	ring.rings = 32
	ring.ring_segments = 8
	rim.mesh = ring
	rim.material_override = bright
	rim.position.y = 0.46
	result.add_child(rim)
	return result

static func coin(parent: Node3D) -> Node3D:
	var result := Node3D.new()
	parent.add_child(result)
	var blue := ManorGeometry.material("426C97", 0.001)
	var disk := ManorGeometry.cylinder(result, 0.067, 0.009, Vector3.ZERO, blue)
	disk.rotation.x = PI / 2
	for side in [-1, 1]:
		var face := ManorGeometry.cylinder(result, 0.054, 0.002, Vector3(0, 0, side * 0.0055), ManorGeometry.material("6F9FC8", 0.0))
		face.rotation.x = PI / 2
		var engraving := MeshInstance3D.new()
		var face_art := QuadMesh.new()
		face_art.size = Vector2(0.11, 0.11)
		engraving.mesh = face_art
		var etched := StandardMaterial3D.new()
		etched.albedo_texture = BELL_EMBLEM
		etched.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		etched.roughness = 0.85
		engraving.material_override = etched
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
