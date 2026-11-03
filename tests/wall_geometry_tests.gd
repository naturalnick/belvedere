extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	for id in [0, 1, 2, 3, 5, 6, 7, 8]:
		var room := ManorRoom.new()
		world.add_child(room)
		room.build(id)
		room.position = ManorGeometry.center(id)
	var boxes: Array[Dictionary] = []
	collect(world, boxes)
	var conflicts := 0
	for i in boxes.size():
		for j in range(i + 1, boxes.size()):
			if boxes[i].material == boxes[j].material:
				continue
			var a: AABB = boxes[i].bounds
			var b: AABB = boxes[j].bounds
			for axis in 3:
				var u := (axis + 1) % 3
				var v := (axis + 2) % 3
				var overlap_u := minf(a.end[u], b.end[u]) - maxf(a.position[u], b.position[u])
				var overlap_v := minf(a.end[v], b.end[v]) - maxf(a.position[v], b.position[v])
				if overlap_u < 0.005 or overlap_v < 0.005:
					continue
				for sign_value in [0, 1]:
					var face_a: float = a.position[axis] if sign_value == 0 else a.end[axis]
					var face_b: float = b.position[axis] if sign_value == 0 else b.end[axis]
					if absf(face_a - face_b) < 0.0001:
						conflicts += 1
						print("Coplanar faces: %s / %s (axis %d, face %d)" % [boxes[i].path, boxes[j].path, axis, sign_value])
	print("Wall geometry: %d overlapping coplanar same-facing box faces" % conflicts)
	world.queue_free()
	await process_frame
	quit(1 if conflicts else 0)

func collect(node: Node, boxes: Array[Dictionary]) -> void:
	if node is MeshInstance3D and node.mesh is BoxMesh and node.material_override is ShaderMaterial:
		# Lever geometry is unrelated; this fixture isolates architecture and joinery.
		var ancestor := node.get_parent()
		var room: ManorRoom
		while ancestor != null:
			if ancestor is ManorRoom:
				room = ancestor
				break
			ancestor = ancestor.get_parent()
		if room != null and not room.lever.is_ancestor_of(node):
			boxes.append({"bounds": node.global_transform * node.get_aabb(), "material": node.material_override.get_shader_parameter("base_color"), "room": room.room_id, "path": str(node.get_path())})
	for child in node.get_children():
		collect(child, boxes)
