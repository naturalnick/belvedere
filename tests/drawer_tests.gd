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
	create_timer(180).timeout.connect(func() -> void:
		printerr("FAIL: drawer route timed out")
		quit(1))
	var main: Manor = load("res://scenes/manor.tscn").instantiate()
	root.add_child(main)
	main.start_play()
	main.player.automated = true
	main.first_coin_guide.seen = true
	var driver: Node = load("res://tools/demo_driver.gd").new()
	root.add_child(driver)
	driver.main = main
	driver.started = Time.get_ticks_msec()
	var capture := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			capture = true
			driver.shots_dir = ProjectSettings.globalize_path(arg.trim_prefix("--shots="))
			DirAccess.make_dir_recursive_absolute(driver.shots_dir)
	if not capture:
		Engine.time_scale = 3.0
	var cues: Array[String] = []
	main.audio.cued.connect(func(group: String) -> void: cues.append(group))
	check(main.coin_drawers.size() == 7, "exactly seven objective rooms have coin drawers")
	for id in ManorObjectives.ROOMS:
		preload("res://tools/furnishing_fixture.gd").place(main, id)
		var drawer := main.coin_drawers[id]
		await physics_frame
		var approach := drawer.to_global(Vector3(0, 0, drawer.travel + 0.85))
		approach.y = 0.02
		await driver.walk_to(approach)
		main.player.aim_at(drawer.front_hit.global_position)
		await physics_frame
		var sound_before := cues.count("lever_blocked")
		check(main.player.begin_interact() and cues.count("lever_blocked") == sound_before + 1, "room %d drawer rattles through normal interaction" % id)
		check(not drawer.opened and not drawer.take_coin() and main.coins.pending.is_empty(), "locked drawer cannot grant a coin")
		drawer._process(0.06)
		check(absf(drawer.tray.position.z) > 0.001, "locked drawer physically rattles")
		drawer._process(1)
		check(is_zero_approx(drawer.tray.position.z), "rattle returns to its closed position")
		if capture:
			await driver.shot("drawer_%d_closed" % id)
		main.coins.award([id])
		check(main.coins.pending.is_empty() and not main.controls_locked(), "objective completion opens a drawer without presenting or collecting its coin")
		drawer._process(0.2)
		main.release_pointer()
		var at := drawer.tray.position
		drawer._process(1)
		check(drawer.tray.position == at, "pause holds drawer opening")
		main.resume_play()
		await create_timer(0.7).timeout
		check(drawer.opened and drawer.coin.visible and drawer.coin_hit.collision_layer == 1, "open drawer exposes the physical coin")
		if id == 2:
			await driver.walk_to(main.rooms[id].position + Vector3(0, 0, 1.2))
			var before := drawer.coin.global_position
			check(main.request_slide(ManorRules.E), "room can shift with an uncollected drawer coin")
			while main.sliding:
				await process_frame
			check(drawer.coin.global_position.is_equal_approx(before + Vector3.RIGHT * ManorGeometry.PITCH) and drawer.coin.visible, "open drawer and waiting coin ride the room together")
		await driver.collect_room_coin(id, capture)
		check(main.coins.collected.has(id) and not drawer.coin.visible and drawer.coin_hit.collision_layer == 0, "physical pickup removes only that coin")
		check(is_equal_approx(drawer.tray.position.z, drawer.travel) and drawer.opened and not drawer.take_coin(), "empty drawer stays open and cannot duplicate its coin")
		main.player.aim_at(drawer.front_hit.global_position)
		check(drawer.interact(), "empty drawer can still rattle without closing")
		drawer._process(1)
		check(is_equal_approx(drawer.tray.position.z, drawer.travel), "empty drawer settles at its open position")
	# A layout reset preserves both the opened furniture and the wallet.
	main.bed_sleep._reset_layout()
	check(main.coins.available == 7 and main.coins.collected.size() == 7, "all seven picked-up coins survive sleep reset")
	for drawer in main.coin_drawers.values():
		check(drawer.opened and not drawer.coin.visible and is_equal_approx(drawer.tray.position.z, drawer.travel), "sleep retains visibly empty open drawers")
	check(driver.failures == 0, "all drawer walking routes and pickup rays pass")
	main.queue_free()
	driver.queue_free()
	await process_frame
	print("Coin drawers: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
