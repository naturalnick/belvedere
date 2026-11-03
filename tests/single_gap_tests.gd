extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func run() -> void:
	var main: Manor = load("res://scenes/manor.tscn").instantiate()
	root.add_child(main)
	main.player.automated = true
	await physics_frame
	await physics_frame
	check(main.rooms.size() == 8 and main.gap_floors.size() == 1, "default launch is eight rooms, one gap")
	check(main.rules.board == ManorRules.from_seed("A").board, "default retains familiar seed A arrangement")
	check(main.rules.valid() and main.rules.courtyards and main.perimeter.is_empty(), "outdoor access remains enabled")
	var driver: Node = load("res://tools/demo_driver.gd").new()
	root.add_child(driver)
	driver.main = main
	driver.started = Time.get_ticks_msec()
	await driver.walk_direction(ManorRules.E)
	await driver.walk_to(Vector3(0, 0, 11))
	check(main.rules.player == ManorRules.OUTSIDE and main.rules.valid(), "single gap still exits onto lawn")
	check(not main.request_slide(ManorRules.N), "cannot slide from lawn")
	await driver.walk_to(ManorGeometry.center(7))
	check(main.rules.player == -1 and main.rules.slot() == 7, "single gap permits reentry")
	await driver.walk_direction(ManorRules.W)
	await driver.approach_lever(main.rooms[7])
	main.player.aim_at(main.rooms[7].lever.global_position + Vector3.UP * 0.8)
	check(main.player.begin_interact(), "lever reachable after lawn excursion")
	main.player.select_pull(ManorRules.E)
	main.player.release_interact()
	check(main.sliding, "slide starts")
	while main.sliding:
		await process_frame
	check(main.rules.slot() == 7 and main.rules.board.count(-1) == 1 and main.gap_floors.has(6), "slide moves sole gap to vacated slot")
	check(main.rules.valid(), "single-gap state remains valid")
	for door in main.rooms[7].doors:
		if door.is_front:
			check(not door.opened and door.gate.collision_layer == 1, "front door stays locked")
	var state := main.rules.copy()
	state.board = PackedInt32Array(ManorRules.HOME)
	check(not state.solved(), "restoring layout does not add a win trigger")
	check(ManorRules.from_key(main.rules.key()).key() == main.rules.key(), "single-gap outdoor state key round trips")
	print("Single gap: %d checks, %d failures" % [checks, failures])
	main.queue_free()
	driver.queue_free()
	await process_frame
	quit(1 if failures else 0)
