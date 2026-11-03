class_name ManorObjectiveDisplay
extends Node3D

var lamps: Dictionary[int, ManorBeacon] = {}
var progress_lights: Array[MeshInstance3D] = []
var target: Node3D
var phase := 0.0

func setup(game: Manor) -> void:
	for id in ManorObjectives.ROOMS:
		var lamp := ManorBeacon.new()
		lamp.position.y = 2.25
		game.rooms[id].add_child(lamp)
		lamps[id] = lamp
	var chandelier := Node3D.new()
	chandelier.position.y = 2.4
	game.rooms[7].add_child(chandelier)
	var brass := ManorGeometry.material("C9A04A")
	ManorGeometry.cylinder(chandelier, 0.025, 0.6, Vector3(0, 0.3, 0), brass)
	for i in 7:
		var angle := float(i) / 7 * TAU
		var radial := Vector3(cos(angle), 0, sin(angle))
		var arm := ManorGeometry.box(chandelier, Vector3(0.8, 0.035, 0.035), radial * 0.4, brass)
		arm.rotation.y = -angle
		var globe := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.14
		sphere.height = 0.28
		sphere.radial_segments = 12
		sphere.rings = 6
		globe.mesh = sphere
		chandelier.add_child(globe)
		globe.position = radial * 0.8 + Vector3.DOWN * 0.12
		progress_lights.append(globe)
	target = Node3D.new()
	add_child(target)
	var lit := ManorGeometry.glowing_material("FFD37F")
	for i in 32:
		var angle := float(i) / 32 * TAU
		var segment := ManorGeometry.box(target, Vector3(0.34, 0.018, 0.07), Vector3(sin(angle) * 1.7, 0.025, cos(angle) * 1.7), lit)
		segment.rotation.y = angle
	for d in 4:
		var arrow := Node3D.new()
		target.add_child(arrow)
		arrow.rotation.y = -d * PI / 2
		for sign_value in [-1, 1]:
			var tip := ManorGeometry.box(arrow, Vector3(0.05, 0.02, 0.35), Vector3(sign_value * 0.12, 0.025, -2.1), lit)
			tip.rotation.y = sign_value * PI / 4

func refresh(objectives: ManorObjectives, instant: bool = false) -> void:
	for id in lamps:
		lamps[id].set_state(2 if objectives.completed.has(id) else (1 if objectives.active == id else 0), instant)
	for i in progress_lights.size():
		progress_lights[i].material_override = ManorGeometry.glowing_material("FFF0C2") if objectives.completed.has(ManorObjectives.ROOMS[i]) else ManorGeometry.material("595C59")
	target.visible = objectives.active >= 0
	if target.visible:
		target.position = ManorGeometry.center(objectives.active)

func _process(delta: float) -> void:
	phase += delta
	if target != null:
		var pulse := 1.0 + 0.025 * sin(phase * 2.6)
		target.scale = Vector3(pulse, 1, pulse)
