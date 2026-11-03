class_name ManorBeacon
extends Node3D

var globe: MeshInstance3D
var shutters: Array[Node3D] = []
var latch: Node3D
var light: OmniLight3D
var state := 0
var phase := 0.0
var motion: Tween

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
		ManorGeometry.box(shutter, Vector3(0.23, 0.42, 0.045), Vector3(0, -0.21, 0), brass)
		shutters.append(shutter)
	latch = Node3D.new()
	add_child(latch)
	latch.position = Vector3(0, -0.23, 0)
	for i in 4:
		var pivot := Node3D.new()
		latch.add_child(pivot)
		pivot.rotation.y = i * PI / 2.0
		var short_bar := ManorGeometry.box(pivot, Vector3(0.12, 0.035, 0.035), Vector3(-0.05, 0, 0.31), brass)
		short_bar.rotation.z = -PI / 4
		var long_bar := ManorGeometry.box(pivot, Vector3(0.24, 0.035, 0.035), Vector3(0.07, 0.04, 0.31), brass)
		long_bar.rotation.z = PI / 4
	light = OmniLight3D.new()
	light.omni_range = 5.5
	light.light_color = Color("FFD990")
	add_child(light)
	set_state(0, true)

func set_state(value: int, instant: bool = false) -> void:
	state = value
	globe.material_override = ManorGeometry.glowing_material("FFD37F" if value == 1 else "FFF0C2") if value > 0 else ManorGeometry.material("595C59")
	latch.visible = value == 2
	if motion:
		motion.kill()
	motion = create_tween().set_parallel(true)
	for shutter in shutters:
		var angle := -1.15 if value > 0 else 0.0
		if instant:
			shutter.rotation.x = angle
		else:
			motion.tween_property(shutter, "rotation:x", angle, 0.5)
	if instant:
		motion.kill()

func _process(delta: float) -> void:
	phase += delta
	var pulse := 0.5 + 0.5 * sin(phase * 2.6)
	light.light_energy = (0.65 + pulse * 0.55) if state == 1 else (0.35 if state == 2 else 0.0)
	globe.scale = Vector3.ONE * (1.0 + 0.10 * pulse if state == 1 else 1.0)
