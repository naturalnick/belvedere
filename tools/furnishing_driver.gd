extends Node
const FIXTURE = preload("res://tools/furnishing_fixture.gd")
const PLAN_VIEWS := {"plan_doorway": Vector3(-2.65, 0, 0), "plan_lever": Vector3(-1.25, 0, 0), "plan_near": Vector3(1.6, 0, 0)}
const NAMES := {1: "bathroom", 2: "study", 3: "kitchen", 5: "living", 6: "dining", 7: "foyer", 8: "laundry"}

func run(driver: Node) -> void:
	var main: Manor = driver.main
	var selected := PackedInt32Array(NAMES.keys())
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--rooms="):
			selected.clear()
			for value in arg.trim_prefix("--rooms=").split(","):
				selected.append(int(value))
	for id in selected:
		driver._check(NAMES.has(id), "selected furnishing room exists")
		print("Furnishing gallery: ", NAMES[id], " (independent slide fixture)")
		FIXTURE.place(main, id)
		await get_tree().physics_frame
		await get_tree().physics_frame
		var room: ManorRoom = main.rooms[id]
		await driver.walk_to(room.position + Vector3(0, 0, 2.30))
		main.player.aim_at(room.position + Vector3(0, 1.0, -1.80))
		await driver.shot("%s_north" % NAMES[id])
		await driver.walk_to(room.position + Vector3(0, 0, -2.30))
		main.player.aim_at(room.position + Vector3(0, 1.0, 1.80))
		await driver.shot("%s_south" % NAMES[id])
		if id == 3:
			await driver.walk_to(room.position + Vector3(-1.0, 0, 1.3))
			main.player.aim_at(room.position + Vector3(-2.38, 1.0, 2.28))
			await driver.shot("kitchen_bowl_detail")
		if id == 6:
			await driver.walk_to(room.position + Vector3(1.2, 0, 1.6))
			main.player.aim_at(room.position + Vector3(2.60, 1.15, 1.9))
			await driver.shot("dining_shelf_detail")
			await driver.walk_to(room.position + Vector3(-0.6, 0, 2.0))
			main.player.aim_at(room.position + Vector3(-1.60, 0.95, 2.56))
			await driver.shot("dining_serving_table")
		if id == 7:
			for side in [-1, 1]:
				await driver.walk_to(main.coin_device.to_global(Vector3(side * 0.80, 0, 1.15)))
				main.player.aim_at(main.coin_device.to_global(Vector3(0, 1.48, 0)))
				await driver.shot("trophy_case_left" if side < 0 else "trophy_case_right")
		if id == 8:
			var plan := room.position + Vector3(2.99, 1.62, 0)
			for shot_name: String in PLAN_VIEWS:
				await driver.walk_to(room.position + PLAN_VIEWS[shot_name])
				main.player.aim_at(plan)
				await driver.shot(shot_name)
		await driver.approach_lever(room)
		main.player.aim_at(room.lever.global_position + Vector3.UP * 0.8)
		await get_tree().physics_frame
		await driver.hold_lever_input(ManorRules.E, true)
		var furniture: Node3D = room.get_node("Furnishings")
		var before := furniture.global_position
		var rider := room.to_local(main.player.global_position)
		driver.release_lever_input(true)
		driver._check(main.sliding, "real input slides " + NAMES[id])
		main.player.aim_at(room.position + Vector3(-1.8, 0.8, -2.0))
		await get_tree().create_timer(0.7).timeout
		driver._check(furniture.global_position.x > before.x and furniture.global_position.x < before.x + 6.25, "furniture moves mid-slide")
		await driver.shot("%s_slide" % NAMES[id])
		while main.sliding:
			await get_tree().process_frame
		driver._check(furniture.global_position.is_equal_approx(before + Vector3.RIGHT * 6.25), "furniture rides full slide")
		driver._check(room.to_local(main.player.global_position).distance_to(rider) < 0.001, "rider stays in furnished room")
