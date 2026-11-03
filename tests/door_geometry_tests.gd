extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var door := ManorDoor.new()
	root.add_child(door)
	door.build("3F6B4F")
	var overlaps := 0
	for leaf in door.leaves:
		var parts: Array[AABB] = []
		for node in leaf.get_children():
			if node is MeshInstance3D and node.mesh is BoxMesh and node.material_override is ShaderMaterial:
				if node.material_override.get_shader_parameter("base_color") == Color("6E4A33"):
					parts.append(node.transform * node.mesh.get_aabb())
			elif node is MultiMeshInstance3D and node.multimesh.mesh is BoxMesh and node.material_override.get_shader_parameter("base_color") == Color("6E4A33"):
				for index in node.multimesh.instance_count:
					parts.append(node.transform * ManorStaticBatch.instance_transform(node, index) * node.multimesh.mesh.get_aabb())
		assert(parts.size() == 11, "Door test must inspect every wooden part, including batches")
		for i in parts.size():
			for j in range(i + 1, parts.size()):
				var overlap := parts[i].intersection(parts[j]).size
				if minf(overlap.x, minf(overlap.y, overlap.z)) > 0.00001:
					overlaps += 1
	print("Door joinery: %d overlapping parts" % overlaps)
	door.queue_free()
	await process_frame
	quit(1 if overlaps else 0)
