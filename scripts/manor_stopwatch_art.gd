class_name ManorStopwatchArt
extends Node3D

const FONT: Font = preload("res://assets/fonts/Fondamento-Regular.ttf")
var readout: Label3D

func _init() -> void:
	name = "Stopwatch"
	var brass := ManorGeometry.material("B58D4E", 0.001)
	var edge := ManorGeometry.material("725637", 0.001)
	var cream := ManorGeometry.material("F4E7CC", 0.0)
	var ink := ManorGeometry.material("3C382F", 0.0)
	_disk(0.108, 0.027, 0.0, edge)
	_disk(0.104, 0.024, 0.003, brass)
	_disk(0.089, 0.003, 0.017, cream)
	_ring(0.089, 0.099, Vector3(0, 0, 0.018), brass)
	_ring(0.077, 0.078, Vector3(0, 0, 0.020), edge)
	for i in 12:
		var angle := i * TAU / 12.0
		var tick := ManorGeometry.box(self, Vector3(0.002, 0.008 if i % 3 == 0 else 0.004, 0.001), Vector3(sin(angle) * 0.083, cos(angle) * 0.083, 0.020), ink)
		tick.rotation.z = -angle
	ManorGeometry.cylinder(self, 0.011, 0.028, Vector3(0, 0.117, 0), edge)
	ManorGeometry.cylinder(self, 0.020, 0.013, Vector3(0, 0.135, 0), brass)
	for i in 10:
		var angle := i * TAU / 10.0
		ManorGeometry.box(self, Vector3(0.002, 0.010, 0.002), Vector3(cos(angle) * 0.020, 0.135, sin(angle) * 0.020), edge)
	_ring(0.022, 0.027, Vector3(0, 0.163, 0), brass)
	readout = Label3D.new()
	readout.name = "RemainingShifts"
	readout.font = FONT
	readout.font_size = 96
	readout.pixel_size = 0.00062
	readout.outline_size = 0
	readout.modulate = Color("302B24")
	readout.position = Vector3(0, 0, 0.022)
	readout.no_depth_test = false
	add_child(readout)
	for mesh: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func set_count(value: int) -> void:
	readout.text = str(value) if value >= 0 else ""

func _disk(radius: float, depth: float, z: float, material: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = depth
	mesh.radial_segments = 48
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = material
	part.rotation.x = PI / 2
	part.position.z = z
	add_child(part)

func _ring(inner: float, outer: float, at: Vector3, material: Material) -> void:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = 48
	mesh.ring_segments = 8
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = material
	part.rotation.x = PI / 2
	part.position = at
	add_child(part)
