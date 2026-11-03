class_name ManorBeacon
extends Node3D

var globe: MeshInstance3D
var light: OmniLight3D
var state := 0

func _ready() -> void:
	var brass := ManorGeometry.material("B39459", 0.004)
	ManorGeometry.cylinder(self, 0.09, 0.05, Vector3(0, 0.72, 0), brass)
	ManorGeometry.cylinder(self, 0.012, 0.43, Vector3(0, 0.48, 0), brass)
	ManorGeometry.cylinder(self, 0.055, 0.06, Vector3(0, 0.245, 0), brass)
	var shade := MeshInstance3D.new()
	var shell := CylinderMesh.new()
	shell.top_radius = 0.10
	shell.bottom_radius = 0.27
	shell.height = 0.24
	shell.radial_segments = 24
	shell.cap_bottom = false
	shade.mesh = shell
	shade.material_override = ManorGeometry.material("DDD3BD", 0.006)
	shade.position.y = 0.10
	add_child(shade)
	var rim := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.255
	ring.outer_radius = 0.275
	ring.rings = 32
	ring.ring_segments = 8
	rim.mesh = ring
	rim.material_override = brass
	rim.position.y = -0.02
	add_child(rim)
	# A shallow frosted lens exposes the on/off state from across the room.
	globe = MeshInstance3D.new()
	var lens := SphereMesh.new()
	lens.radius = 0.25
	lens.height = 0.09
	lens.radial_segments = 24
	lens.rings = 8
	globe.mesh = lens
	globe.position.y = -0.025
	add_child(globe)
	light = OmniLight3D.new()
	light.omni_range = 5.5
	light.light_color = Color("FFF0DA")
	add_child(light)
	set_state(0)

func set_state(value: int) -> void:
	state = value
	globe.material_override = ManorGeometry.glowing_material("FFF0DA") if value == 1 else ManorGeometry.material("77766E")
	light.light_energy = 0.85 if value == 1 else 0.0
