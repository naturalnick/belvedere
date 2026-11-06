extends SceneTree

var checks := 0
var failures := 0
var acquisitions := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func press(key: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = true
	return event

func run() -> void:
	create_timer(45).timeout.connect(func() -> void: quit(1))
	var main: Manor = load("res://scenes/manor.tscn").instantiate()
	root.add_child(main)
	main.player.automated = true
	var watch := main.stopwatch
	var hatch := main.foundation_hatch
	watch.set_process(false)
	watch.acquired.connect(func() -> void: acquisitions += 1)
	check(not watch.toggle() and not watch.owned and not watch.hud.shows_icon(), "unowned stopwatch has no inventory icon and cannot raise")
	check(not hatch.visible and not watch.model.is_visible_in_tree() and hatch.lid_hit.collision_layer == 0 and not hatch.interact(), "covered hatch is hidden, noncolliding and inaccessible")
	watch.solver.build_step(1)
	check(watch.solver.assembly_distance(main.rules) == -1, "partial BFS never publishes a provisional hint")
	while not watch.solver.build_step(127):
		pass
	watch.refresh_count()
	check(watch.remaining == 18 and watch.model.readout.text == "18", "incremental solver finds the opening's exact minimum")
	preload("res://tools/stopwatch_fixture.gd").place(main)
	var fixture_board := main.rules.board.duplicate()
	var fixed_position := hatch.global_position
	check(main.slides == 10 and hatch.exposed(), "legal ten-slide fixture exposes the northwest hatch")
	check(main.objectives.completed.size() > 0 and not main.objectives.all_completed, "fixture retains partial blue-token progress")
	for tick in 6:
		await physics_frame
	var ray := main.player.focus()
	check(not ray.is_empty() and ray.collider == hatch.lid_hit, "real interaction ray reaches the closed hatch")
	var resting_pose := watch.model.global_transform
	check(main.player.begin_interact() and hatch.opened and hatch.busy and main.controls_locked(), "one E press opens the hatch and holds the player for the reveal")
	await create_timer(0.25).timeout
	check(hatch.contents.visible and watch.model.global_transform.is_equal_approx(resting_pose), "watch is revealed in place as the lid opens")
	check(not main.request_slide(ManorRules.N) and not watch.toggle(), "opening prevents slides and item use")
	main.release_pointer()
	await process_frame
	var angle := hatch.lid.rotation.x
	await create_timer(0.15).timeout
	check(is_equal_approx(angle, hatch.lid.rotation.x), "pause freezes hatch opening")
	main.resume_play()
	await create_timer(0.85).timeout
	check(not hatch.busy and watch.presenting and main.controls_locked(), "opening automatically starts the watch reward without a second interaction")
	check(watch.reward_origin.is_equal_approx(resting_pose) and watch.model.global_transform.is_equal_approx(resting_pose), "reward begins at the exact hatch pose without a pop")
	check(not hatch.interact(), "opened hatch cannot award twice")
	watch._input(press(KEY_T))
	check(not watch.accepted, "opening press cannot skip the arriving reward")
	watch._process(ManorStopwatch.LIFT_TIME / 2)
	check(watch.model.global_position.y > resting_pose.origin.y and is_equal_approx(watch.model.global_position.x, resting_pose.origin.x) and is_equal_approx(watch.model.global_position.z, resting_pose.origin.z), "watch first rises vertically out of the hatch")
	check(watch.model.global_basis.get_scale().is_equal_approx(Vector3.ONE), "initial lift preserves the physical watch size")
	check(hatch.opened and not hatch.busy, "hatch stays fully open while the watch lifts out")
	watch._process(ManorStopwatch.ARRIVE_TIME - ManorStopwatch.LIFT_TIME / 2 - 0.1)
	watch._input(press(KEY_T))
	check(not watch.accepted, "a press during the flight cannot snap the watch into place")
	check(hatch.emptied and hatch.busy, "hatch closes automatically once the watch clears it")
	watch._process(1.0)
	check(watch.presenting and not watch.owned and watch.reward_hint.text == ManorStopwatch.DESCRIPTION, "reward holds with the agreed description")
	var reward_position := main.player.position
	main.player.bot_drive = Vector3.RIGHT
	await physics_frame
	await physics_frame
	check(watch.presenting and main.player.position.is_equal_approx(reward_position), "walking cannot bypass the acquisition presentation")
	main.player.bot_drive = Vector3.ZERO
	main.release_pointer()
	watch._process(1.0)
	await process_frame
	var closing_angle := hatch.lid.rotation.x
	await create_timer(0.15).timeout
	check(is_equal_approx(hatch.lid.rotation.x, closing_angle), "pause freezes automatic closing")
	check(watch.reward_elapsed == ManorStopwatch.HOLD_AT and not watch.reward_title.visible and not watch.model.visible, "pause hides and suspends the reward")
	main.resume_play()
	await create_timer(1.0).timeout
	check(not hatch.opened and not hatch.busy and is_zero_approx(hatch.lid.rotation.x) and hatch.lid_hit.collision_layer == 0, "empty hatch settles shut without an interaction target")
	watch._process(0.0)
	watch._input(press(KEY_T))
	watch._process(0.7)
	check(watch.owned and not watch.presenting and acquisitions == 1 and watch.phase == ManorStopwatch.Phase.IDLE, "fresh T accepts once without also raising")
	check(watch.hud.shows_icon() and watch.hud.icon_position() == Vector2(watch.hud.size.x - 146, 40), "owned watch occupies the inventory slot beside coins")
	var arrival := main.player.camera.unproject_position(watch.model.global_position)
	check(arrival.distance_to(watch.hud.icon_position()) < 0.1, "accepted reward arrives at its inventory icon")
	check(not hatch.interact(), "closed empty hatch cannot be reopened or award another watch")
	main.player.automated = false
	# The headless display cannot capture a pointer; the rendered capture exercises T.
	watch.toggle()
	check(watch.phase == ManorStopwatch.Phase.RAISING and main.controls_locked(), "T raises owned watch and locks movement")
	var repeat := press(KEY_T)
	repeat.echo = true
	main.player._unhandled_input(repeat)
	check(watch.phase == ManorStopwatch.Phase.RAISING, "key repeat does not retrigger use")
	watch._process(0.5)
	check(watch.phase == ManorStopwatch.Phase.VIEWING and watch.model.visible, "watch reaches readable inspection pose")
	main.binoculars.owned = true
	check(watch.hud.icon_position().x == watch.hud.size.x - 192, "watch shifts left to make room for owned binoculars")
	check(not main.binoculars.toggle() and not main.player.begin_interact(), "watch inspection excludes binoculars and world interactions")
	main.player._unhandled_input(press(KEY_P))
	watch._process(0.1)
	check(main.play_gate.visible and not watch.model.visible and not watch.hud.shows_icon(), "P pauses inspection and hides watch behind menu")
	main.player.automated = true
	main.player.bot_drive = Vector3.RIGHT
	var paused_position := main.player.position
	await physics_frame
	await physics_frame
	check(watch.phase == ManorStopwatch.Phase.VIEWING and main.player.position.is_equal_approx(paused_position), "movement intent during pause neither walks nor stows the watch")
	main.player.bot_drive = Vector3.ZERO
	main.player.automated = false
	main.resume_play()
	watch._process(0.0)
	check(watch.model.visible, "resume restores inspection")
	main.player._unhandled_input(press(KEY_ESCAPE))
	check(watch.phase == ManorStopwatch.Phase.LOWERING and not main.play_gate.visible, "Escape lowers without opening pause")
	watch._process(0.4)
	check(not watch.locks_player() and not watch.model.visible, "lowering restores normal movement")
	main.player.automated = true
	for during_raise in [false, true]:
		check(watch.toggle(), "watch can be raised for walking check")
		watch._process(0.15 if during_raise else 0.5)
		var walking_start := main.player.position
		main.player.bot_drive = Vector3.RIGHT
		await physics_frame
		await physics_frame
		check(watch.phase == ManorStopwatch.Phase.LOWERING and main.player.position.x > walking_start.x, "walking starts immediately and stows a raising or viewed watch")
		check(main.controls_locked() and not main.controls_locked(true) and not main.player.begin_interact() and not main.binoculars.toggle(), "lowering permits movement while keeping interactions and binoculars blocked")
		watch._process(0.4)
		check(watch.phase == ManorStopwatch.Phase.IDLE and not watch.model.visible, "walking finishes with the watch stowed")
		main.player.bot_drive = Vector3.ZERO
		await physics_frame
		await physics_frame
	check(main.binoculars.toggle(), "binoculars can still be raised")
	main.binoculars.set_process(false)
	main.binoculars._process(0.7)
	main.binoculars._process(0.5)
	var binocular_position := main.player.position
	main.player.bot_drive = Vector3.RIGHT
	await physics_frame
	await physics_frame
	check(main.binoculars.phase == ManorBinoculars.Phase.OVERVIEW and main.player.position.is_equal_approx(binocular_position), "walking neither dismisses binoculars nor moves the player during their overview")
	main.player.bot_drive = Vector3.ZERO
	main.binoculars.reset_view()
	main.binoculars.set_process(true)
	main.play_gate._open_controls()
	check(main.play_gate.controls_panel.rows[6].visible, "owned-only control lists Stopwatch T")
	main.play_gate._close_controls()
	main.resume_play()
	var expected := watch.remaining
	check(expected == 8, "ten-slide fixture leaves exactly eight shifts to assemble")
	main.rules.player = ManorRules.OUTSIDE
	main.rules.gap_slot = -1
	watch.refresh_count()
	check(watch.remaining == expected, "lawn and reachable gap have identical minimum counts")
	main.rules.player = 3
	main.player.position = main.rooms[3].position + Vector3(0, 0.02, 1.0)
	main.rules.gap_slot = -1
	check(main.request_slide(ManorRules.N), "Kitchen can cover the closed hatch")
	check(not hatch.visible and hatch.lid_hit.collision_layer == 0, "hatch cannot clip a moving room")
	check(not watch.toggle(), "cannot inspect during room motion")
	while main.sliding:
		await process_frame
	watch.refresh_count()
	check(hatch.global_position == fixed_position and not hatch.visible and not hatch.opened and hatch.emptied, "hatch stays fixed and remembers collection beneath a room")
	check(watch.remaining == 7, "temporarily moving Kitchen out of home advances the optimal route and reads seven")
	main.coins.pending.clear()
	check(main.request_slide(ManorRules.S), "room can uncover the hatch again")
	while main.sliding:
		await process_frame
	check(hatch.visible and not hatch.opened and hatch.emptied and hatch.lid_hit.collision_layer == 0 and main.rules.board == fixture_board, "uncovering retains the closed empty hatch without duplicating the item")
	main.fall_recovery._wake()
	check(watch.owned and watch.claimed, "fall recovery retains the stopwatch")
	main.rules = ManorRules.new()
	main.rules.lawn_access = true
	watch.refresh_count()
	check(watch.remaining == 0 and watch.model.readout.text == "0", "assembled house reads zero in the actual game mode")
	main.return_to_title()
	check(not watch.model.visible and not watch.locks_player(), "return to title clears inspection")
	main.queue_free()
	await process_frame
	print("Stopwatch: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
