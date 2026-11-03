class_name ManorObjectiveDisplay
extends Node3D

var lamps: Dictionary[int, ManorBeacon] = {}
var progress_lights: Array[MeshInstance3D] = []

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

func refresh(objectives: ManorObjectives) -> void:
	for id in lamps:
		lamps[id].set_state(2 if objectives.completed.has(id) else (1 if objectives.active == id else 0))
	for i in progress_lights.size():
		progress_lights[i].material_override = ManorGeometry.glowing_material("FFF0C2") if objectives.completed.has(ManorObjectives.ROOMS[i]) else ManorGeometry.material("595C59")
