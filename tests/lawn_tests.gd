extends "res://tests/manor_test.gd"

func lawn_rules() -> void:
	var state := ManorRules.opening_start()
	state.lawn_access = true
	state.player = -1
	check(state.valid() and state.slot() == 8, "gap has a player position")
	check(not state.can_slide(ManorRules.N), "no slides while in the gap")
	check(state.apply(ManorRules.WALK, ManorRules.S) and state.player == ManorRules.OUTSIDE, "edge gap exits to lawn")
	check(not state.can_slide(ManorRules.N), "no slides from lawn")
	check(not state.apply(ManorRules.ENTER_GAP, 6), "cannot enter occupied cell from lawn")
	check(state.apply(ManorRules.ENTER_GAP, 8) and state.slot() == 8, "can reenter through the gap")
	var center := ManorRules.new(PackedInt32Array(ManorRules.HOME), ManorRules.OUTSIDE)
	center.lawn_access = true
	check(not center.apply(ManorRules.ENTER_GAP, 4), "cannot enter interior cell from lawn")
	var rng := RandomNumberGenerator.new()
	rng.seed = 60203
	for i in 3000:
		var actions := state.moves()
		check(not actions.is_empty(), "lawn state has a legal action")
		if actions.is_empty():
			break
		var action := actions[rng.randi_range(0, actions.size() - 1)]
		check(state.apply(action.x, action.y), "enumerated action applies")
		check(state.valid(), "walks and slides preserve lawn state")
		check(state.copy().key() == state.key(), "copy retains gap and outside position")
		check(ManorRules.from_key(state.key()).key() == state.key(), "key round trip retains lawn state")

func run() -> void:
	lawn_rules()
	var main := start_manor()
	await physics_frame
	await physics_frame
	check(main.rooms.size() == 8 and main.rules.board.count(-1) == 1, "default launch is eight rooms, one gap")
	check(main.rules.board == ManorRules.opening_start().board, "default starts with Laundry bottom-center")
	check(main.rules.valid() and main.rules.lawn_access, "outdoor access remains enabled")
	var driver := add_driver(main)
	await driver.complete_opening_slide()
	for direction in driver.walk_route(7):
		await driver.walk_direction(direction)
	await driver.walk_direction(ManorRules.E)
	await driver.walk_to(Vector3(0, 0, 11))
	check(main.rules.player == ManorRules.OUTSIDE and main.rules.valid(), "gap exits onto lawn")
	check(not main.request_slide(ManorRules.N), "cannot slide from lawn")
	await driver.walk_to(ManorGeometry.center(7))
	check(main.rules.player == -1 and main.rules.slot() == 7, "gap permits reentry")
	await driver.walk_direction(ManorRules.W)
	await driver.approach_lever(main.rooms[7])
	main.player.aim_at(main.rooms[7].lever.global_position + Vector3.UP * 0.8)
	check(main.player.begin_interact(), "lever reachable after lawn excursion")
	main.player.select_pull(ManorRules.E)
	main.player.release_interact()
	check(main.sliding, "slide starts")
	while main.sliding:
		await process_frame
	check(main.rules.slot() == 7 and main.rules.board.count(-1) == 1 and main.gap_floor.position.is_equal_approx(ManorGeometry.center(6) + Vector3.DOWN * 0.02), "slide moves the gap to the vacated slot")
	check(main.rules.valid(), "state remains valid after the slide")
	for door in main.rooms[7].doors:
		if door.is_front:
			check(not door.opened and door.gate.collision_layer == 1, "front door stays locked")
	main.queue_free()
	driver.queue_free()
	await process_frame
	finish("Lawn")
