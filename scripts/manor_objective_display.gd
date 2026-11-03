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
	var brass := ManorGeometry.material("B39459", 0.004)
	ManorGeometry.cylinder(chandelier, 0.10, 0.05, Vector3(0, 0.57, 0), brass)
	ManorGeometry.cylinder(chandelier, 0.018, 0.19, Vector3(0, 0.45, 0), brass)
	var hoop := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.59
	ring.outer_radius = 0.63
	ring.rings = 40
	ring.ring_segments = 8
	hoop.mesh = ring
	hoop.material_override = brass
	chandelier.add_child(hoop)
	for i in 3:
		var angle := i * TAU / 3.0
		var top := Vector3(0, 0.36, 0)
		var bottom := Vector3(cos(angle), 0, sin(angle)) * 0.61
		var rod := ManorGeometry.cylinder(chandelier, 0.009, top.distance_to(bottom), (top + bottom) / 2.0, brass)
		rod.quaternion = Quaternion(Vector3.UP, (top - bottom).normalized())
	for i in 7:
		var angle := float(i) / 7 * TAU
		var radial := Vector3(cos(angle), 0, sin(angle)) * 0.61
		ManorGeometry.cylinder(chandelier, 0.045, 0.06, radial + Vector3.DOWN * 0.035, brass)
		var globe := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.085
		sphere.height = 0.17
		sphere.radial_segments = 16
		sphere.rings = 8
		globe.mesh = sphere
		chandelier.add_child(globe)
		globe.position = radial + Vector3.DOWN * 0.13
		progress_lights.append(globe)

func refresh(objectives: ManorObjectives, rules: ManorRules) -> void:
	for id in lamps:
		lamps[id].set_state(1 if objectives.active == id else (2 if rules.board[id] == id else 0))
	for i in progress_lights.size():
		progress_lights[i].material_override = ManorGeometry.glowing_material("FFF0DA") if rules.board[ManorObjectives.ROOMS[i]] == ManorObjectives.ROOMS[i] else ManorGeometry.material("595C59")
