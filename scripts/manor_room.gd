class_name ManorRoom
extends Node3D

const OVERVIEW_BORDER_WIDTH := 0.34
const OVERVIEW_BORDER_INSET := 0.035

var room_id: int
var doors: Array[ManorDoor] = []
var lever: Node3D
var stick: Node3D
var arrows: Array[Node3D] = []
var lever_motion: Tween
var ceiling: MeshInstance3D
var door_headers: Array[MeshInstance3D] = []
var overview_edges: Node3D
var overview_roof: Node3D
var roof_number: Label3D

func build(id: int) -> void:
	room_id = id
	var plaster := ManorGeometry.material("EFE4D2", 0.0)
	var accent := ManorGeometry.material(ManorGeometry.ACCENTS[id], 0.0)
	ManorGeometry.box(self, Vector3(6.25, 0.2, 6.25), Vector3(0, -0.1, 0), ManorGeometry.floor_material(id), true)
	ceiling = ManorGeometry.box(self, Vector3(6.25, 0.2, 6.25), Vector3(0, 3.1, 0), ManorGeometry.material("F6EEE1", 0.0), true)
	ceiling.name = "Ceiling"
	overview_edges = Node3D.new()
	overview_edges.name = "OverviewEdges"
	add_child(overview_edges)
	overview_edges.hide()
	_build_overview_roof()
	for d in 4:
		var wall := Node3D.new()
		add_child(wall)
		wall.position = ManorGeometry.DIRECTIONS[d] * 3.0625
		wall.rotation.y = -d * PI / 2.0
		var span := 6.0 if d % 2 == 0 else 6.25
		var side_width := (span - 1.2) / 2.0
		var mat: Material = accent if d == (first_window() + 2) % 4 else plaster
		if ManorRules.side(id, d) != ManorRules.WINDOW:
			for sign_value in [-1, 1]:
				var x: float = sign_value * (0.6 + side_width / 2.0)
				ManorGeometry.box(wall, Vector3(side_width, 3, 0.125), Vector3(x, 1.5, 0), mat, true)
			var header := ManorGeometry.box(wall, Vector3(1.2, 0.8, 0.125), Vector3(0, 2.6, 0), mat, true)
			if ManorRules.side(id, d) == ManorRules.DOOR:
				door_headers.append(header)
			var door := ManorDoor.new()
			wall.add_child(door)
			door.room_id = id
			door.direction = d
			door.is_front = ManorRules.side(id, d) == ManorRules.FRONT
			door.build("3F5E7A" if door.is_front else ManorGeometry.ACCENTS[id])
			doors.append(door)
		else:
			ManorGeometry.box(wall, Vector3(span, 0.9, 0.125), Vector3(0, 0.45, 0), mat)
			ManorGeometry.box(wall, Vector3(span, 0.6, 0.125), Vector3(0, 2.7, 0), mat)
			ManorGeometry.box(wall, Vector3(1.8, 1.5, 0.125), Vector3(0, 1.65, 0), mat)
			for sign_value in [-1, 1]:
				var outer_width := span / 2.0 - 2.3
				var x: float = sign_value * (2.3 + outer_width / 2.0)
				ManorGeometry.box(wall, Vector3(outer_width, 1.5, 0.125), Vector3(x, 1.65, 0), mat)
			for x in [-1.6, 1.6]:
				_window(wall, x)
			ManorGeometry.barrier(wall, Vector3(6.25, 3, 0.125), Vector3(0, 1.5, 0))
		_build_overview_edge(d)
	var fill := OmniLight3D.new()
	fill.position.y = 2.6
	fill.omni_range = 6.0
	fill.light_energy = 0.35
	fill.light_color = Color(ManorGeometry.ACCENTS[id]).lerp(Color("FFE2B0"), 0.7)
	add_child(fill)
	_build_lever()
	var furniture: Node3D = ManorBedroom.new() if id == 0 else ManorFurnishings.new(id)
	add_child(furniture)
	ManorStaticBatch.combine(furniture)
	ManorSunReach.trim_casters(self, furniture)
	# These pieces change visibility independently in the binocular overview.
	var skip: Array[Node] = [lever, furniture, ceiling, overview_edges, overview_roof]
	skip.append_array(door_headers)
	for door in doors:
		skip.append_array(door.leaves)
		if door.emblem != null:
			skip.append(door.emblem)
	ManorStaticBatch.combine(self, skip)

func set_overview(enabled: bool) -> void:
	ceiling.visible = not enabled
	for header in door_headers:
		header.visible = not enabled
	overview_edges.visible = enabled
	overview_roof.visible = enabled

func _build_overview_roof() -> void:
	overview_roof = Node3D.new()
	overview_roof.name = "OverviewRoof"
	add_child(overview_roof)
	overview_roof.hide()
	# Cover the ordinary wall tops so only the window-wall borders remain visible.
	ManorGeometry.box(overview_roof, Vector3(6.25, 0.08, 6.25), Vector3(0, 3.045, 0), ManorGeometry.material(ManorGeometry.ACCENTS[room_id], 0.0))
	roof_number = Label3D.new()
	roof_number.name = "RoofNumber"
	roof_number.font = preload("res://assets/fonts/Fondamento-Regular.ttf")
	roof_number.text = str(room_id + 1 if room_id < 4 else room_id)
	roof_number.font_size = 192
	roof_number.pixel_size = 0.016
	roof_number.outline_size = 0
	roof_number.modulate = Color("303B36") if room_id in [1, 3, 7] else Color("F6EEE1")
	roof_number.position.y = 3.12
	roof_number.rotation.x = -PI / 2
	roof_number.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	overview_roof.add_child(roof_number)

func _build_overview_edge(direction: int) -> void:
	if ManorRules.side(room_id, direction) != ManorRules.WINDOW:
		return
	# Separate neighboring rooms' borders; reserve corner space only for actual borders.
	var cap_span := ManorGeometry.PITCH - 2 * OVERVIEW_BORDER_INSET
	var left_trim := 0.0
	var right_trim := 0.0
	if direction % 2 == 0:
		if ManorRules.side(room_id, (direction + 3) % 4) == ManorRules.WINDOW:
			left_trim = OVERVIEW_BORDER_WIDTH
		if ManorRules.side(room_id, (direction + 1) % 4) == ManorRules.WINDOW:
			right_trim = OVERVIEW_BORDER_WIDTH
	var cap := Node3D.new()
	overview_edges.add_child(cap)
	cap.position = ManorGeometry.DIRECTIONS[direction] * (ManorGeometry.PITCH / 2 - OVERVIEW_BORDER_INSET - OVERVIEW_BORDER_WIDTH / 2)
	cap.rotation.y = -direction * PI / 2
	ManorGeometry.box(cap, Vector3(cap_span - left_trim - right_trim, 0.025, OVERVIEW_BORDER_WIDTH), Vector3((left_trim - right_trim) / 2, 3.1, 0), ManorGeometry.material("343C38", 0.0))

func first_window() -> int:
	for d in 4:
		if ManorRules.side(room_id, d) != ManorRules.DOOR:
			return d
	return 0

func _window(wall: Node3D, x: float) -> void:
	var trim := ManorGeometry.material("D9C7AE", 0.006)
	for offset in [-0.72, 0.72]:
		ManorGeometry.box(wall, Vector3(0.08, 1.6, 0.16), Vector3(x + offset, 1.65, 0.15), trim)
	for y in [0.87, 2.43]:
		ManorGeometry.box(wall, Vector3(1.36, 0.08, 0.16), Vector3(x, y, 0.15), trim)
	ManorGeometry.box(wall, Vector3(0.045, 1.5, 0.12), Vector3(x, 1.65, 0), ManorGeometry.material("D9C7AE", 0.0))
	ManorGeometry.box(wall, Vector3(1.4, 0.045, 0.12), Vector3(x, 1.65, 0), ManorGeometry.material("D9C7AE", 0.0))
	var pane := ManorGeometry.box(wall, Vector3(1.4, 1.5, 0.018), Vector3(x, 1.65, 0), ManorGeometry.glass())
	pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _build_lever() -> void:
	lever = Node3D.new()
	add_child(lever)
	var brass := ManorGeometry.material("C9A04A")
	ManorGeometry.cylinder(lever, 0.28, 0.1, Vector3(0, 0.05, 0), brass)
	ManorGeometry.cylinder(lever, 0.17, 0.3, Vector3(0, 0.2, 0), brass)
	stick = Node3D.new()
	lever.add_child(stick)
	stick.position.y = 0.35
	ManorGeometry.cylinder(stick, 0.045, 0.48, Vector3(0, 0.24, 0), brass)
	ManorGeometry.cylinder(stick, 0.1, 0.14, Vector3(0, 0.48, 0), ManorGeometry.material("6E4A33"))
	var hit := ManorGeometry.barrier(lever, Vector3(0.42, 0.95, 0.42), Vector3(0, 0.475, 0))
	hit.set_meta("lever_room", room_id)
	for d in 4:
		var arrow := Node3D.new()
		lever.add_child(arrow)
		arrow.rotation.y = -d * PI / 2.0
		ManorGeometry.box(arrow, Vector3(0.06, 0.02, 0.35), Vector3(0, 0.02, -0.57), brass)
		for sign_value in [-1, 1]:
			var tip := ManorGeometry.box(arrow, Vector3(0.06, 0.02, 0.22), Vector3(sign_value * 0.07, 0.02, -0.68), brass)
			tip.rotation.y = sign_value * PI / 4.0
		arrow.visible = false
		arrows.append(arrow)

func show_pull(direction: int, valid_directions: int, held: bool) -> void:
	if lever_motion:
		lever_motion.kill()
	for d in 4:
		arrows[d].visible = held
		for mesh: MeshInstance3D in arrows[d].get_children():
			mesh.material_override = ManorGeometry.material("F5DE8D" if held and (valid_directions & (1 << d)) != 0 else "85744E", 0.006)
	var target := Vector3.ZERO
	if direction >= 0:
		var v: Vector3 = ManorGeometry.DIRECTIONS[direction]
		target = Vector3(v.z * 0.45, 0, -v.x * 0.45)
	lever_motion = create_tween()
	lever_motion.tween_property(stick, "rotation", target, 0.12)
