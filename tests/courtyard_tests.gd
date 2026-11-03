extends SceneTree

var checks := 0
var failures := 0
var main: Manor

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func run() -> void:
	var state := ManorRules.courtyard_start()
	check(state.valid() and state.board.count(-1) == 3, "six distinct rooms and three gaps")
	check(state.apply(ManorRules.WALK, ManorRules.E) and state.slot() == 7, "walk into first gap")
	var first_key := state.key()
	check(state.apply(ManorRules.WALK, ManorRules.E) and state.slot() == 8, "walk into second gap")
	check(state.key() != first_key, "gaps have distinct player positions")
	check(not state.can_slide(ManorRules.N), "no slides while in a gap")
	check(state.apply(ManorRules.WALK, ManorRules.S) and state.player == ManorRules.OUTSIDE, "edge gap exits to lawn")
	check(not state.apply(ManorRules.ENTER_GAP, 4), "cannot enter interior cell from lawn")
	check(not state.apply(ManorRules.ENTER_GAP, 6), "cannot enter occupied perimeter cell from lawn")
	check(not state.can_slide(ManorRules.N), "no slides from lawn")
	check(state.apply(ManorRules.ENTER_GAP, 0) and state.slot() == 0, "can reenter through a different edge gap")
	check(not state.can_walk(ManorRules.S), "window facing gap still blocks walking")
	check(state.apply(ManorRules.WALK, ManorRules.E) and state.player == 2, "gap can enter matching doorway")
	state = ManorRules.courtyard_start()
	check(state.apply(ManorRules.SLIDE, ManorRules.E) and state.slot() == 7, "slide targets adjacent gap, not first board gap")
	check(state.can_slide(ManorRules.E) and state.can_slide(ManorRules.W), "multiple simultaneous legal slides")
	check(state.apply(ManorRules.SLIDE, ManorRules.E) and state.slot() == 8, "choose second gap")
	check(not state.can_slide(ManorRules.E) and not state.can_walk(ManorRules.E), "house boundary blocks slides and exterior doors")
	var rng := RandomNumberGenerator.new()
	rng.seed = 60203
	for i in 3000:
		var actions := state.moves()
		check(not actions.is_empty(), "prototype has a legal action")
		if actions.is_empty():
			break
		var action := actions[rng.randi_range(0, actions.size() - 1)]
		check(state.apply(action.x, action.y), "enumerated action applies")
		check(state.valid(), "walks and slides preserve courtyard state")
		check(state.copy().key() == state.key(), "copy retains gap and outside position")
		check(ManorRules.from_key(state.key()).key() == state.key(), "key round trip retains prototype state")
		check(not state.solved(), "prototype never triggers legacy solve")
	main = load("res://scenes/manor.tscn").instantiate()
	root.add_child(main)
	main.start_play()
	main.player.automated = true
	await physics_frame
	await physics_frame
	check(main.rules.courtyards and main.rooms.size() == 6 and main.gap_floors.size() == 3, "explicit courtyard launch builds six-room setup")
	check(main.perimeter.is_empty(), "no house perimeter barrier")
	var original := main.rules.copy()
	var original_position := main.player.position
	main.rules.board = PackedInt32Array([-1, -1, 2, 0, -1, 3, 7, 1, 5])
	main.rules.player = -1
	main.rules.gap_slot = 0
	main.player.position = Vector3(-3.12, 0, -3.12)
	main.update_occupant()
	check(main.rules.slot() == 4, "diagonal corner crossing tracks connected gaps")
	main.rules = original
	main.player.position = original_position
	var driver: Node = load("res://tools/demo_driver.gd").new()
	root.add_child(driver)
	driver.main = main
	driver.started = Time.get_ticks_msec()
	await driver.walk_direction(ManorRules.E)
	await driver.walk_direction(ManorRules.E)
	check(main.rules.slot() == 8, "physical walking tracks consecutive gaps")
	await driver.walk_to(Vector3(6.25, 0, 11))
	check(main.rules.player == ManorRules.OUTSIDE, "physical exit from gap")
	await driver.walk_to(Vector3(11, 0, 11))
	await driver.walk_to(Vector3(11, 0, -11))
	await driver.walk_to(Vector3(-6.25, 0, -11))
	await driver.walk_to(ManorGeometry.center(0))
	check(main.rules.player == -1 and main.rules.slot() == 0, "walk around house and reenter different gap")
	await driver.walk_direction(ManorRules.E)
	check(main.rules.player == 2, "can enter room after outside excursion")
	await driver.approach_lever(main.rooms[2])
	main.player.aim_at(main.rooms[2].lever.global_position + Vector3.UP * 0.8)
	check(main.player.begin_interact(), "lever raycast reaches lever after reentry")
	main.player.select_pull(ManorRules.W)
	var local := main.rooms[2].to_local(main.player.global_position)
	main.player.release_interact()
	check(main.sliding, "lever begins slide after reentry")
	while main.sliding:
		await process_frame
	check(main.rules.slot() == 0 and main.gap_floors.has(1), "slide updates the correct gap floor")
	check(main.rooms[2].to_local(main.player.global_position).distance_to(local) < 0.001, "player rides slide")
	check(not main.won and not main.carpet.visible, "no reward or finale")
	for id in main.rooms:
		for door in main.rooms[id].doors:
			if door.is_front or ManorRules.neighbor(main.rules.board.find(id), door.direction) < 0:
				check(not door.opened and door.gate.collision_layer == 1, "outside-facing doors stay blocked")
	# Study east is a window: collisions must agree with the blocked logical move.
	main.player.position = main.rooms[2].position + Vector3(1.6, 0.02, 1.6)
	main.player.velocity = Vector3.ZERO
	main.player.bot_drive = Vector3.RIGHT
	await create_timer(1.0).timeout
	check(main.rules.player == 2 and main.player.position.x < main.rooms[2].position.x + 2.75, "window remains physically blocked")
	main.player.bot_drive = Vector3.ZERO
	print("Courtyard: %d checks, %d failures" % [checks, failures])
	main.queue_free()
	driver.queue_free()
	await process_frame
	quit(1 if failures else 0)
