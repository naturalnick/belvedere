extends SceneTree
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
	await physics_frame
	await physics_frame
	for id in main.rooms:
		check(main.rooms[id].has_node("BedroomFurnishings") == (id == 0), "Bedroom furnishings remain isolated to room 0")
	var room: ManorRoom = main.rooms[0]
	var furniture: Node3D = room.get_node("BedroomFurnishings")
	check(furniture.find_children("*", "MeshInstance3D", true, false).size() <= 60, "trial furniture stays within mesh budget")
	check(not furniture.is_processing(), "furniture has no ambient animation")
	var driver: Node = load("res://tools/demo_driver.gd").new()
	root.add_child(driver)
	driver.main = main
	driver.started = Time.get_ticks_msec()
	main.rules.player = 0
	main.player.position = room.position + Vector3(0, 0.02, 1.2)
	for i in range(1, 25):
		var angle := i * TAU / 24.0
		var at := room.position + Vector3(sin(angle), 0, cos(angle)) * 1.2
		await driver.walk_to(at)
		check(Vector2(main.player.position.x - at.x, main.player.position.z - at.z).length() < 0.15, "1.2 m lever ring remains walkable")
	for direction in ManorGeometry.DIRECTIONS:
		await driver.walk_to(room.position + direction * 1.2)
		await driver.walk_to(room.position + direction * 2.5)
		check(main.rules.player == 0, "all four side approaches remain inside room")
		await driver.walk_to(room.position + direction * 1.2)
		await driver.walk_to(room.position + Vector3(0, 0, 1.2))
	var state := ManorRules.new([1, 2, 3, 0, -1, 5, 6, 7, 8], 0)
	state.courtyards = true
	main.rules = state
	for id in main.rooms:
		main.rooms[id].position = ManorGeometry.center(state.board.find(id))
	main.gap_floors.clear()
	main.gap_floors[4] = main.gap_floor
	main.gap_floor.position = ManorGeometry.center(4) + Vector3.DOWN * 0.02
	main.player.position = room.position + Vector3(0, 0.02, 1.2)
	main.refresh_doors(true)
	await physics_frame
	await driver.approach_lever(room)
	main.player.aim_at(room.lever.global_position + Vector3.UP * 0.8)
	await physics_frame
	var bed: Node3D = furniture.get_node("Bed")
	var before := bed.global_position
	var rider := room.to_local(main.player.global_position)
	check(main.player.begin_interact(), "lever remains reachable in furnished room")
	main.player.select_pull(ManorRules.E)
	main.player.release_interact()
	check(main.sliding, "lever starts furnished-room slide")
	await create_timer(0.7).timeout
	check(bed.global_position.x > before.x and bed.global_position.x < before.x + 6.25, "furniture moves during slide")
	while main.sliding:
		await process_frame
	check(bed.global_position.is_equal_approx(before + Vector3.RIGHT * 6.25), "furniture rides exactly one slot")
	check(room.to_local(main.player.global_position).distance_to(rider) < 0.001, "player stays with furnished room")
	check(main.rules.valid(), "furnished slide preserves rules")
	check(driver.failures == 0, "physical walk and input driver passed")
	print("Bedroom trial: %d checks, %d failures" % [checks, failures])
	main.queue_free()
	driver.queue_free()
	await process_frame
	quit(1 if failures else 0)
