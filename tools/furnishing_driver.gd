extends Node
const FIXTURE = preload("res://tools/furnishing_fixture.gd")
const NAMES := {1: "bathroom", 2: "study", 3: "kitchen", 5: "living", 6: "dining", 7: "foyer", 8: "laundry"}

func run(driver: Node) -> void:
	var main: Manor = driver.main
	for id in NAMES:
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
