extends SceneTree

const SHELL_LAYER := 1 << 19
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func run() -> void:
	var main: Manor = load("res://scenes/manor.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var to_sun := ManorGeometry.to_sun()
	var sun: DirectionalLight3D = main.find_children("*", "DirectionalLight3D", false, false)[0]
	check(sun.global_transform.basis.z.is_equal_approx(to_sun), "trimming uses the rendered sun direction")
	var trimmed := 0
	var casting := 0
	for id in main.rooms:
		var room: ManorRoom = main.rooms[id]
		var furniture: Node3D
		for child in room.get_children():
			if child is ManorFurnishings or child is ManorBedroom:
				furniture = child
		for geometry: GeometryInstance3D in furniture.find_children("*", "GeometryInstance3D", true, false):
			var material := geometry.material_override
			check(material == null or material.next_pass == null, "room %d furniture outlines are separate shells" % id)
			if ManorStaticBatch.is_outline_shell(geometry):
				check(geometry.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "outline shells never enter the shadow map")
		_add_shell_collision(main, room, furniture)
		await physics_frame
		await physics_frame
		var space := main.get_world_3d().direct_space_state
		for geometry: GeometryInstance3D in furniture.find_children("*", "GeometryInstance3D", true, false):
			if ManorStaticBatch.is_outline_shell(geometry) or not geometry.material_override is ShaderMaterial:
				continue
			if geometry.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				casting += 1
				continue
			trimmed += 1
			var reached := false
			for box in ManorSunReach.boxes_in_room(geometry, room):
				box = box.grow(-0.001)
				for i in 125:
					var point := room.global_transform * (box.position + box.size * Vector3(i % 5, i / 5 % 5, i / 25) / 4.0)
					var ray := PhysicsRayQueryParameters3D.create(point, point + to_sun * 60.0, SHELL_LAYER)
					ray.hit_back_faces = true
					if space.intersect_ray(ray).is_empty():
						reached = true
						break
				if reached:
					break
			check(not reached, "room %d piece %s without shadows is never sunlit" % [id, geometry.name])
		for body in main.get_children():
			if body is StaticBody3D and body.collision_layer == SHELL_LAYER:
				body.free()
	print("Furniture shadow casters: %d kept, %d never sunlit" % [casting, trimmed])
	check(trimmed > casting, "most enclosed furniture leaves the shadow map")
	main.queue_free()
	await process_frame
	print("Shadows: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

# Opaque architecture only: glass, door leaves and lintels count as open, which can only add light.
func _add_shell_collision(main: Manor, room: ManorRoom, furniture: Node3D) -> void:
	var open: Array[Node] = [furniture, room.lever, room.overview_roof, room.overview_edges]
	open.append_array(room.door_headers)
	for door in room.doors:
		open.append_array(door.leaves)
	for geometry: GeometryInstance3D in room.find_children("*", "GeometryInstance3D", true, false):
		if not geometry.material_override is ShaderMaterial or ManorStaticBatch.is_outline_shell(geometry):
			continue
		if open.any(func(part: Node) -> bool: return part == geometry or part.is_ancestor_of(geometry)):
			continue
		var mesh: Mesh = geometry.multimesh.mesh if geometry is MultiMeshInstance3D else (geometry as MeshInstance3D).mesh
		var transforms: Array[Transform3D] = []
		if geometry is MultiMeshInstance3D:
			for i in geometry.multimesh.instance_count:
				transforms.append(geometry.global_transform * ManorStaticBatch.instance_transform(geometry, i))
		else:
			transforms.append(geometry.global_transform)
		var faces := PackedVector3Array()
		for transform in transforms:
			for vertex in mesh.get_faces():
				faces.append(transform * vertex)
		var shape := ConcavePolygonShape3D.new()
		shape.set_faces(faces)
		shape.backface_collision = true
		var collider := CollisionShape3D.new()
		collider.shape = shape
		var body := StaticBody3D.new()
		body.collision_layer = SHELL_LAYER
		body.collision_mask = 0
		body.add_child(collider)
		main.add_child(body)
