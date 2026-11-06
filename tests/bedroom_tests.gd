extends "res://tests/manor_test.gd"

func run() -> void:
	var main := start_manor()
	await physics_frame
	await physics_frame
	for id in main.rooms:
		check(main.rooms[id].has_node("BedroomFurnishings") == (id == 0), "Bedroom furnishings remain isolated to room 0")
	var room: ManorRoom = main.rooms[0]
	var furniture: Node3D = room.get_node("BedroomFurnishings")
	var meshes := furniture.find_children("*", "GeometryInstance3D", true, false)
	print("Bedroom: %d furniture meshes" % meshes.size())
	# The moving drawer and removable coin cannot join the furniture's static batches.
	check(meshes.size() <= 68, "bedroom and interactive drawer stay within mesh budget")
	check(not furniture.is_processing(), "furniture has no ambient animation")
	var driver := add_driver(main)
	main.rules.player = 0
	main.player.position = room.position + Vector3(0, 0.02, 1.2)
	for i in range(25):
		var angle := -PI / 2 + i * PI / 24.0
		var at := room.position + Vector3(sin(angle), 0, cos(angle)) * 0.75
		await driver.walk_to(at)
		check(Vector2(main.player.position.x - at.x, main.player.position.z - at.z).length() < 0.15, "east, south and west lever approaches remain walkable")
	for direction in [Vector3.RIGHT, Vector3.BACK, Vector3.LEFT]:
		await driver.walk_to(room.position + direction * 0.75)
		await driver.walk_to(room.position + direction * 2.5)
		check(main.rules.player == 0, "door and west-window approaches remain inside room")
		await driver.walk_to(room.position + direction * 0.75)
		await driver.walk_to(room.position + Vector3(0, 0, 1.2))
	await driver.walk_to(room.position + Vector3(-2.0, 0, 0))
	await driver.walk_to(room.position + Vector3(-2.0, 0, -2.0))
	check(main.player.position.distance_to(room.position + Vector3(-2.0, 0, -2.0)) < 0.15, "west aisle reaches the north windows beside the bed and table")
	await driver.walk_to(room.position + Vector3(-2.0, 0, 0))
	var state := ManorRules.new([1, 2, 3, 0, -1, 5, 6, 7, 8], 0)
	state.lawn_access = true
	main.rules = state
	for id in main.rooms:
		main.rooms[id].position = ManorGeometry.center(state.board.find(id))
	main.gap_floor.position = ManorGeometry.center(4) + Vector3.DOWN * 0.02
	main.player.position = room.position + Vector3(0, 0.02, 1.2)
	main.refresh_doors(true)
	await physics_frame
	await driver.approach_lever(room)
	main.player.aim_at(room.lever.global_position + Vector3.UP * 0.8)
	await physics_frame
	var bed: Node3D = furniture.get_node("Bed")
	var before := bed.global_position
	check(main.player.begin_interact(), "lever remains reachable in furnished room")
	main.player.select_pull(ManorRules.E)
	main.player.release_interact()
	check(main.sliding, "lever starts furnished-room slide")
	await create_timer(0.7).timeout
	check(bed.global_position.x > before.x and bed.global_position.x < before.x + 6.25, "furniture moves during slide")
	while main.sliding:
		await process_frame
	check(bed.global_position.is_equal_approx(before + Vector3.RIGHT * 6.25), "furniture rides exactly one slot")
	check(main.rules.valid(), "furnished slide preserves rules")
	main.queue_free()
	driver.queue_free()
	await process_frame
	finish("Bedroom")
