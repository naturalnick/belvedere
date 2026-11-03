class_name ManorBeacon
extends Node3D

var globe: MeshInstance3D
var shutters: Array[Node3D] = []
var light: OmniLight3D
var state := 0

func _ready() -> void:
	var brass := ManorGeometry.material("C9A04A")
	ManorGeometry.cylinder(self, 0.025, 0.5, Vector3(0, 0.45, 0), brass)
	ManorGeometry.cylinder(self, 0.34, 0.09, Vector3(0, 0.2, 0), brass)
	globe = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.25
	sphere.height = 0.5
	sphere.radial_segments = 16
	sphere.rings = 8
	globe.mesh = sphere
	add_child(globe)
	for i in 4:
		var pivot := Node3D.new()
		add_child(pivot)
		pivot.rotation.y = i * PI / 2.0
		var shutter := Node3D.new()
		pivot.add_child(shutter)
		shutter.position = Vector3(0, 0.20, 0.29)
		shutter.rotation.x = -1.15
		ManorGeometry.box(shutter, Vector3(0.23, 0.42, 0.045), Vector3(0, -0.21, 0), brass)
		shutters.append(shutter)
	light = OmniLight3D.new()
	light.omni_range = 5.5
	light.light_color = Color("FFD990")
	add_child(light)
	set_state(0)

func set_state(value: int) -> void:
	state = value
	globe.material_override = ManorGeometry.glowing_material("FFD37F" if value == 1 else "FFF0C2") if value > 0 else ManorGeometry.material("595C59")
	light.light_energy = 0.85 if value == 1 else (0.35 if value == 2 else 0.0)
