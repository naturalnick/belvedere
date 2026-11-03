extends SceneTree
## Optical probes use opaque mesh-derived colliders on a test-only layer.
## Gameplay colliders deliberately block transparent glass and cannot test sight.

const VISION_LAYER := 1 << 7
var main: Manor
var report: Dictionary = {"accepted": 0, "spawn_pass": 0, "lever_pass": 0, "spawn_turn_max": 0.0, "lever_walk_max": 0.0, "view_counts": {}, "view_pass": 0, "view_total": 0, "failures": []}

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	main = load("res://scenes/manor.tscn").instantiate()
	root.add_child(main)
	main.player.set_physics_process(false)
	main.player.set_process_unhandled_input(false)
	_add_optical_shapes(main)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/accepted_14_20.json"))
	var entries: Array = data.states
	for index in entries.size():
		var entry: Dictionary = entries[index]
		var state := ManorRules.new(PackedInt32Array(entry.board), int(entry.player))
		_place(state)
		await physics_frame
		await physics_frame
		report.accepted += 1
		_probe_spawn(index)
		_probe_lever(index)
		# Every accepted spawn's four sides, plus every room in a deterministic sample.
		_probe_sides(index, state.player)
		if index % 50 == 0:
			for id in main.rooms:
				if id != state.player:
					_probe_sides(index, id)
		if (index + 1) % 300 == 0:
			print("Geometry probes: %d / %d accepted seeds" % [index + 1, entries.size()])
	DirAccess.make_dir_recursive_absolute("res://build/fun")
	var file := FileAccess.open("res://build/fun/probes.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("Spawn %d/%d; lever %d/%d; side views %d/%d; %d failures" % [report.spawn_pass, report.accepted, report.lever_pass, report.accepted, report.view_pass, report.view_total, report.failures.size()])
	main.queue_free()
	await process_frame
	quit(0 if report.failures.is_empty() else 1)

func _place(state: ManorRules) -> void:
	main.rules = state
	main.won = false
	for id in main.rooms:
		main.rooms[id].position = ManorGeometry.center(state.board.find(id))
	main.gap_floor.position = ManorGeometry.center(state.board.find(-1)) + Vector3.DOWN * 0.02
	main.refresh_doors(true)
	main.place_player_at_spawn()

func _probe_spawn(index: int) -> void:
	var eye := main.player.camera.global_position
	var target := main.gap_floor.global_position + Vector3.DOWN * 0.03
	var forward := -main.player.camera.global_basis.z
	var direction := (target - eye).normalized()
	var horizontal := Vector2(forward.x, forward.z).angle_to(Vector2(direction.x, direction.z))
	var turn := absf(rad_to_deg(horizontal))
	var hit := _ray(eye, target)
	var visible := not hit.is_empty() and int(hit.collider.get_meta("sight_room")) == -1
	var open_door := false
	for door in main.rooms[main.rules.player].doors:
		if ManorRules.neighbor(main.rules.slot(), door.direction) == main.rules.board.find(-1):
			open_door = door.opened and door.gate.collision_layer == 0
	var in_view := main.player.camera.is_position_in_frustum(target)
	if visible and open_door and turn <= 90.0 and (in_view or turn > 0.0):
		report.spawn_pass += 1
	else:
		_fail(index, "spawn", {"visible": visible, "door": open_door, "turn": turn, "frustum": in_view})
	report.spawn_turn_max = maxf(report.spawn_turn_max, turn)

func _probe_lever(index: int) -> void:
	var room: ManorRoom = main.rooms[main.rules.player]
	var eye := main.player.camera.global_position
	var target := room.lever.global_position + Vector3.UP * 0.8
	var distance := eye.distance_to(target)
	var walk_seconds := maxf(0, distance - 2.2) / 3.0
	main.player.aim_at(target)
	var hit := main.player.focus()
	var reachable: bool = not hit.is_empty() and hit.collider.has_meta("lever_room") and int(hit.collider.get_meta("lever_room")) == main.rules.player
	if reachable and walk_seconds <= 3.0:
		report.lever_pass += 1
	else:
		_fail(index, "lever", {"ray_hit": reachable, "walk_seconds": walk_seconds})
	report.lever_walk_max = maxf(report.lever_walk_max, walk_seconds)

func _probe_sides(index: int, room_id: int) -> void:
	var room: ManorRoom = main.rooms[room_id]
	var slot := main.rules.board.find(room_id)
	for d in 4:
		var q := ManorRules.neighbor(slot, d)
		var expected := "edge" if q < 0 else ("empty" if main.rules.board[q] == -1 else "neighbour")
		var kind := "window" if ManorRules.side(room_id, d) == ManorRules.WINDOW else "door"
		if ManorRules.side(room_id, d) == ManorRules.FRONT:
			kind = "front"
			expected = "occluded"
		var bucket := kind + "/" + expected
		report.view_counts[bucket] = report.view_counts.get(bucket, 0) + 1
		report.view_total += 1
		var side: Vector3 = ManorGeometry.DIRECTIONS[d]
		var tangent: Vector3 = ManorGeometry.DIRECTIONS[(d + 1) % 4]
		var success := false
		var encountered: Array[String] = []
		# Scan glass panes from plausible eye positions, avoiding mullion centers.
		var offsets: Array[float] = []
		offsets.assign([-1.85, -1.35, 1.35, 1.85] if kind == "window" else [-0.42, -0.18, 0.18, 0.42])
		for offset in offsets:
			main.player.position = room.global_position + side * 1.7 + tangent * offset
			var eye := main.player.camera.global_position
			# Downward sightline lands in the adjoining cell, not beyond it.
			var target := room.global_position + side * 5.1 + tangent * offset + Vector3.UP * 0.45
			var hit := _ray(eye, target + (target - eye).normalized() * 1.5)
			var actual := "edge"
			if not hit.is_empty():
				var owner_id: int = hit.collider.get_meta("sight_room")
				if owner_id == room_id:
					actual = "occluded"
				elif owner_id == -1:
					actual = "empty"
				elif owner_id >= 0:
					actual = "neighbour"
			if not encountered.has(actual):
				encountered.append(actual)
			if actual == expected:
				success = true
				break
		if success:
			report.view_pass += 1
		else:
			_fail(index, bucket, {"room": room_id, "side": d, "actual": encountered})

func _add_optical_shapes(node: Node, room_id: int = -4) -> void:
	if node is ManorRoom:
		room_id = node.room_id
	elif node == main.gap_floor:
		room_id = -1
	if node is MeshInstance3D and node.visible:
		var material: Material = node.material_override
		var transparent: bool = material is BaseMaterial3D and material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED
		if not transparent:
			var body := StaticBody3D.new()
			body.collision_layer = VISION_LAYER
			body.collision_mask = 0
			body.set_meta("sight_room", room_id)
			var collision := CollisionShape3D.new()
			collision.shape = node.mesh.create_trimesh_shape()
			body.add_child(collision)
			node.add_child(body)
	for child in node.get_children():
		if not child is StaticBody3D:
			_add_optical_shapes(child, room_id)

func _ray(from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, VISION_LAYER)
	query.hit_back_faces = true
	return main.get_world_3d().direct_space_state.intersect_ray(query)

func _fail(index: int, kind: String, detail: Dictionary) -> void:
	report.failures.append({"index": index, "kind": kind, "detail": detail})
