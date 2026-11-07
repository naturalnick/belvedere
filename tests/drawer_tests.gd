extends "res://tests/manor_test.gd"

func run() -> void:
	create_timer(180).timeout.connect(func() -> void:
		printerr("FAIL: drawer route timed out")
		quit(1))
	var main := start_manor()
	main.first_home_guide.seen = true
	var driver := add_driver(main)
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
	check(main.coin_drawers.size() == 7, "seven rooms have coin drawers")
	for id in ManorCoins.ROOMS:
		preload("res://tools/furnishing_fixture.gd").place(main, id)
		var drawer := main.coin_drawers[id]
		await physics_frame
		var approach := drawer.to_global(Vector3(0, 0, drawer.travel + 0.85))
		approach.y = 0.02
		await driver.walk_to(approach)
		var fixture_board := main.rules.board.duplicate()
		if id == 3:
			# The fixture's west slot is the Kitchen's real home, so test its lock from a swapped board.
			main.rules.board[3] = fixture_board[5]
			main.rules.board[5] = 3
		main.player.aim_at(drawer.front_hit.global_position)
		await physics_frame
		var sound_before := cues.count("lever_blocked")
		check(main.player.begin_interact() and cues.count("lever_blocked") == sound_before + 1, "room %d drawer rattles through normal interaction" % id)
		check(not drawer.opened and not drawer.take_coin() and main.coins.pending.is_empty(), "locked drawer cannot grant a coin")
		check(not drawer.coin.visible, "a closed drawer's coin is not drawn")
		drawer._process(0.06)
		check(absf(drawer.tray.position.z) > 0.001, "locked drawer physically rattles")
		drawer._process(1)
		check(is_zero_approx(drawer.tray.position.z), "rattle returns to its closed position")
		if capture:
			await driver.shot("drawer_%d_closed" % id)
		# The fixture keeps the room away from home, so bring it home the way a slide would.
		var away := main.rules.board.find(id)
		var occupant := main.rules.board[id]
		main.rules.board[id] = id
		main.rules.board[away] = occupant
		drawer.was_home = false
		main.home_lights.refresh(main.rules)
		drawer.refresh_home()
		var clicks := cues.count("drawer_unlock")
		drawer._process(ManorCoinDrawer.UNLOCK_DELAY * 0.5)
		check(cues.count("drawer_unlock") == clicks, "room %d unlock waits until after the lamp lights" % id)
		main.sliding = true
		drawer._process(ManorCoinDrawer.UNLOCK_DELAY * 0.8)
		main.sliding = false
		drawer._process(ManorCoinDrawer.UNLOCK_DELAY * 0.8)
		check(cues.count("drawer_unlock") == clicks, "room %d unlock restarts its wait after another slide" % id)
		drawer._process(ManorCoinDrawer.UNLOCK_DELAY * 0.3)
		check(cues.count("drawer_unlock") == clicks + 1, "room %d drawer clicks unlocked once" % id)
		check(not drawer.opened and drawer.tray.position.z == 0.0 and main.coins.pending.is_empty(), "a room coming home never opens its drawer by itself")
		main.player.aim_at(drawer.front_hit.global_position)
		await physics_frame
		var hit := main.player.focus()
		check(not hit.is_empty() and hit.collider == drawer.front_hit, "room %d drawer front is reachable" % id)
		check(main.player.begin_interact() and drawer.opened and main.coins.pending.is_empty(), "trying the drawer of a home room opens it without collecting its coin")
		main.rules.board = fixture_board
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
	main.queue_free()
	driver.queue_free()
	await process_frame
	finish("Coin drawers")
