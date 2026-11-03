extends SceneTree
const FIXTURE = preload("res://tools/furnishing_fixture.gd")
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
	main.player.automated = true
	var driver: Node = load("res://tools/demo_driver.gd").new()
	root.add_child(driver)
	driver.main = main
	driver.started = Time.get_ticks_msec()
	Engine.time_scale = 4.0
	for id in [1, 2, 3, 5, 6, 7, 8]:
		FIXTURE.place(main, id)
		await physics_frame
		await physics_frame
		var room: ManorRoom = main.rooms[id]
		var furniture: Node3D = room.get_node("Furnishings")
		var meshes := furniture.find_children("*", "GeometryInstance3D", true, false)
		print("Room %d: %d furniture meshes" % [id, meshes.size()])
		check(meshes.size() <= 90, "room %d furniture mesh budget" % id)
		check(not furniture.is_processing(), "furniture is static")
		check(furniture.find_children("*", "Light3D", true, false).is_empty(), "decorative lamps cannot compete with objective light")
		for i in range(1, 13 if id == 6 else 25):
			var angle := i * TAU / 24.0
			var target := room.position + Vector3(sin(angle), 0, cos(angle)) * 1.2
			await driver.walk_to(target)
			check(Vector2(main.player.position.x - target.x, main.player.position.z - target.z).length() < 0.15, "room %d clear lever approach" % id)
		if id == 6:
			# The centred dining set replaces the west half of the ring with an aisle.
			for local_point in [Vector3(0, 0, 1.98), Vector3(-2.70, 0, 1.98), Vector3(-2.70, 0, 0), Vector3(-2.70, 0, -1.98), Vector3(0, 0, -1.98)]:
				await driver.walk_to(room.position + local_point)
				check(main.rules.player == id, "dining table and both ends have a walkable aisle")
			await driver.walk_to(room.position + Vector3(0, 0, 1.2))
		for direction in ManorGeometry.DIRECTIONS:
			if id == 6 and direction == Vector3.LEFT:
				continue
			await driver.walk_to(room.position + direction * 1.2)
			await driver.walk_to(room.position + direction * 2.5)
			check(main.rules.player == id, "room %d clear side approach" % id)
			await driver.walk_to(room.position + direction * 1.2)
			await driver.walk_to(room.position + Vector3(0, 0, 1.2))
		for direction in 4:
			if ManorRules.side(id, direction) != ManorRules.WINDOW:
				continue
			var normal: Vector3 = ManorGeometry.DIRECTIONS[direction]
			var tangent := Vector3(-normal.z, 0, normal.x)
			var eye := room.position + Vector3.UP * 1.65
			for offset in [-1.6, 1.6]:
				var ray := PhysicsRayQueryParameters3D.create(eye, eye + normal * 3.10 + tangent * offset)
				ray.exclude = [main.player.get_rid()]
				var hit := main.get_world_3d().direct_space_state.intersect_ray(ray)
				check(not hit.is_empty() and not furniture.is_ancestor_of(hit.collider), "room %d furniture leaves window view clear" % id)
		await driver.approach_lever(room)
		main.player.aim_at(room.lever.global_position + Vector3.UP * 0.8)
		await physics_frame
		check(main.player.begin_interact(), "room %d lever reachable" % id)
		main.player.select_pull(ManorRules.E)
		var solids := furniture.find_children("*", "StaticBody3D", true, false)
		var before: Array[Vector3] = []
		for body in solids:
			before.append(body.global_position)
		main.player.release_interact()
		check(main.sliding, "room %d slide starts" % id)
		while main.sliding:
			await process_frame
		for i in solids.size():
			check(solids[i].global_position.is_equal_approx(before[i] + Vector3.RIGHT * 6.25), "furniture collision rides room %d" % id)
		check(main.rules.valid(), "furnished slide preserves rules")
	check(driver.failures == 0, "physical walk driver passed")
	print("Furnishings: %d checks, %d failures" % [checks, failures])
	main.queue_free()
	driver.queue_free()
	await process_frame
	quit(1 if failures else 0)
