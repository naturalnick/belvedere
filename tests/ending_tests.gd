extends "res://tests/manor_test.gd"

func click_at(at: Vector2) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = at
	click.pressed = true
	root.push_input(click, true)
	click.pressed = false
	root.push_input(click, true)

func run() -> void:
	var main := start_manor()
	await physics_frame
	await physics_frame
	check(main.home_lights.lamps.size() == 7 and not main.home_lights.lamps.has(7), "exactly seven pendants, excluding Foyer")
	check(main.home_lights.progress_lights.size() == 7, "separate Foyer chandelier tracks seven room placements")
	for lamp: ManorBeacon in main.home_lights.lamps.values():
		check(not lamp.is_processing() and lamp.globe.scale == Vector3.ONE, "home lamps have no continuous animation or scaling")
		check((lamp.light.light_energy > 0) == lamp.lit, "only rooms that are home emit light")
	var front: ManorDoor
	for door in main.rooms[7].doors:
		if door.is_front:
			front = door
	for mesh: MeshInstance3D in front.find_children("*", "MeshInstance3D", true, false):
		check(not mesh.material_override is StandardMaterial3D, "front door has no transparent glass material")
	check(not front.opened and front.gate.collision_layer == 1, "bonus door starts locked")
	main.rules.player = 8
	check(main.rules.apply(ManorRules.SLIDE, ManorRules.E), "Laundry slides home in the ending fixture")
	main.refresh_progress()
	for id in main.home_lights.lamps:
		check(main.home_lights.lamps[id].lit == (main.rules.board[id] == id), "a room's lamp tracks whether it is home")
	for room in ManorCoins.ROOMS:
		main.coins.collect(room)
	while not main.coins.pending.is_empty():
		receive_coin(main)
	for i in 7:
		check(main.player_piano.interact(), "piano accepts coin %d" % (i + 1))
		while main.player_piano.busy:
			await process_frame
	main.audio.end_song()
	check(not main.controls_locked() and not main.play_gate.visible and not front.opened and not main.won, "spending every coin neither ends play nor unlocks the exit")
	for bell_room in ManorBells.WORD:
		main.bells.ring(ManorBells.LETTERS.find_key(bell_room))
	check(main.bells.complete and not main.controls_locked() and not main.play_gate.visible and not front.opened and not main.won, "finishing the bells neither ends play nor unlocks the exit")
	main.rules.board = PackedInt32Array(ManorRules.HOME)
	for id in main.rooms:
		main.rooms[id].position = ManorGeometry.center(id)
	main.refresh_progress()
	check(main.won and not front.opened and front.gate.collision_layer == 1, "assembled house keeps the exit locked for the conservatory key")
	preload("res://tools/conservatory_fixture.gd").finish_reveal(main)
	check(main.conservatory.unlock_exit(front), "collected conservatory key unlocks the solid exit")
	await create_timer(ManorConservatory.UNLOCK_TIME + 1.0).timeout
	check(absf(front.leaves[0].rotation.y) < deg_to_rad(50) and front.gate.collision_layer == 1, "red door opens slowly and blocks passage through its panels")
	await create_timer(ManorDoor.EXIT_OPEN_SECONDS).timeout
	check(front.gate.collision_layer == 0 and is_equal_approx(front.leaves[0].rotation.y, deg_to_rad(-100)), "fully open exit permits passage")
	check(not main.ending.title.visible and not main.ending.credit.visible and not main.ending.music_credit.visible and not main.ending.thanks.visible, "ending lettering waits until the carpet sequence")
	check(main.carpet.visible and main.ending.active and main.ending.rainbow.visible, "carpet and rainbow activate only for bonus")
	main.ending.set_process(false)
	main.player.set_physics_process(false)
	main.player.position = Vector3(0, 0, 16)
	main.player.aim_at(Vector3(0, 1.3, 36))
	for i in 500:
		main.ending._process(0.12)
	check(main.ending.total_spawned > ManorEnding.FLOWER_LIMIT and main.ending.spawned == ManorEnding.FLOWER_LIMIT, "continuous flower growth uses bounded recycling")
	check(main.ending.flowers.multimesh.mesh.get_aabb().end.y < 0.02, "flowers are stemless low blooms")
	for at in main.ending.positions:
		check(main.player.camera.is_position_in_frustum(at), "every new flower is inside the actual camera view")
		check(absf(at.x) > 9.55 or absf(at.z) > 9.55, "flowers stay off house footprint")
		check(not (absf(at.x) < 1.15 and at.z > 9.2 and at.z < 23), "flowers stay off carpet")
		var offset := at - main.player.position
		offset.y = 0
		check(offset.length() <= 12.01 and offset.length() >= 2.49, "flowers grow within the forward range")
	var saved_fov := main.player.camera.fov
	for fov in [60, 100]:
		main.player.camera.fov = fov
		main.player.position.z = 10.0
		var before := main.ending.total_spawned
		for step in 120:
			main.player.position.z += 0.08
			main.player.aim_at(Vector3(0, 1.3, 36))
			var previous := main.ending.total_spawned
			main.ending._process(ManorEnding.SPROUT_INTERVAL)
			if main.ending.total_spawned > previous:
				var newest := main.ending.positions[(main.ending.total_spawned - 1) % ManorEnding.FLOWER_LIMIT]
				check(main.player.camera.is_position_in_frustum(newest), "moving player's new blooms stay in view at FOV %d" % fov)
		check(main.ending.total_spawned - before >= 110, "visible planting keeps up with the sprout rate at FOV %d" % fov)
	main.player.camera.fov = saved_fov
	main.rules.player = 7
	main.player.position = Vector3(0, 0, 9.5)
	main.update_occupant()
	check(main.in_finale and main.controls_locked(), "crossing unlocked front door begins finale")
	var finish_time := main.run_stats.elapsed_seconds
	check(main.run_stats.finished and not main.run_summary.visible, "run timer stops on entering the finale and results stay hidden")
	main.ending.set_process(true)
	await create_timer(2.0).timeout
	check(main.ending.title.modulate.a > 0 and main.ending.title.modulate.a < 1 and main.ending.credit.modulate.a == 0, "title fades slowly during the walk before any credits")
	main.release_pointer()
	var paused_position := main.player.position
	var paused_alpha := main.ending.title.modulate.a
	var paused_ages := main.ending.ages.duplicate()
	await create_timer(0.3).timeout
	check(main.player.position == paused_position and main.ending.title.modulate.a == paused_alpha and main.ending.ages == paused_ages, "pause freezes walking, title fade and flowers")
	main.resume_play()
	await create_timer(ManorEnding.WALK_SECONDS - 2.0 + 0.2).timeout
	check(main.player.position.is_equal_approx(Vector3(0, -0.02, 22)), "player stops at carpet end")
	check(main.ending.credit.modulate.a > 0 and main.ending.credit.modulate.a < 1 and main.ending.music_credit.modulate.a == 0 and main.ending.thanks.modulate.a == 0, "credit begins fading only after arrival")
	main.release_pointer()
	paused_alpha = main.ending.credit.modulate.a
	var paused_flowers := main.ending.total_spawned
	await create_timer(0.3).timeout
	check(main.ending.credit.modulate.a == paused_alpha and main.ending.total_spawned == paused_flowers and not main.fade.visible, "pause freezes credits and keeps the menu unobscured")
	main.resume_play()
	await create_timer(ManorEnding.CREDIT_FADE_SECONDS).timeout
	check(is_equal_approx(main.ending.credit.modulate.a, 1) and main.ending.music_credit.modulate.a < 0.5 and main.ending.thanks.modulate.a == 0, "the game credit is readable before the music credit")
	await create_timer(ManorEnding.MUSIC_CREDIT_FADE_SECONDS).timeout
	check(is_equal_approx(main.ending.music_credit.modulate.a, 1) and main.ending.thanks.modulate.a == 0, "both credits are readable before the thank-you appears")
	await create_timer(ManorEnding.CREDIT_GAP_SECONDS + 2.0).timeout
	check(main.ending.thanks.modulate.a > 0 and main.ending.thanks.modulate.a < 1 and not main.at_title, "thank-you fades in after the additional wait")
	check(not main.run_summary.revealed, "totals wait until every ending line has faded in")
	root.push_input(key_press())
	check(not main.run_summary.exiting, "early key presses cannot skip the credits")
	while not main.run_summary.ready_to_continue:
		await process_frame
	check(main.run_summary.visible and is_equal_approx(main.run_summary.modulate.a, 1) and main.ending.thanks.modulate.a == 1, "totals and button fade in after the completed credits")
	main.player.automated = false
	if main.pointer_watch != null:
		main.pointer_watch.captured = func() -> bool: return false
		main.pointer_watch.locked = true
		main.pointer_watch._process(ManorPointerWatch.LOCK_TIMEOUT + 0.1)
		check(not main.play_gate.visible, "ending pointer release does not trigger the web pause menu")
	await create_timer(0.4).timeout
	check(not main.at_title and is_zero_approx(main.fade.color.a) and main.run_stats.elapsed_seconds == finish_time, "completed ending waits for input without increasing run time")
	main.release_pointer()
	await process_frame
	check(not main.run_summary.visible, "pause hides the results behind the menu")
	main.run_summary._continue()
	check(not main.run_summary.exiting, "Continue cannot accept the results while paused")
	main.resume_play()
	await process_frame
	var repeated := key_press()
	repeated.echo = true
	root.push_input(repeated)
	root.push_input(InputEventMouseMotion.new())
	for code in [KEY_SPACE, KEY_ENTER, KEY_TAB, KEY_F12]:
		root.push_input(key_press(code))
	var screenshot := key_press(KEY_3)
	screenshot.meta_pressed = true
	screenshot.shift_pressed = true
	root.push_input(screenshot)
	click_at(Vector2(10, 10))
	check(not main.run_summary.exiting and not main.play_gate.visible, "keys, screenshot shortcuts and clicks outside Continue leave results visible")
	root.push_input(key_press(KEY_ESCAPE))
	check(main.play_gate.visible and not main.run_summary.exiting, "Escape pauses instead of dismissing the ending")
	main.resume_play()
	await process_frame
	click_at(main.run_summary.continue_button.get_global_rect().get_center())
	check(main.run_summary.exiting and not main.at_title, "clicking Continue begins the fade back to menu")
	await create_timer(ManorRunSummary.FADE_SECONDS + 0.2).timeout
	check(main.at_title and main.play_gate.mode == "title" and not main.run_summary.visible, "Continue returns to title with results hidden")
	check(not main.ending.is_processing(), "flower updates stop at title")
	main.queue_free()
	await process_frame
	var fresh := start_manor()
	check(fresh.run_stats.shifts == 0 and fresh.run_stats.sleeps == 0 and fresh.run_stats.falls == 0 and fresh.run_stats.elapsed_seconds == 0, "a new game starts with fresh run statistics")
	check(fresh.coins.inserted == 0 and fresh.coins.available == 0 and fresh.coins.pending.is_empty() and fresh.bells.progress == 0 and not fresh.bells.complete, "a fresh game resets the wallet, songs, bells and presentation queue")
	fresh.rules.board = PackedInt32Array(ManorRules.HOME)
	fresh.refresh_progress()
	check(fresh.won and fresh.coins.collected.is_empty() and fresh.coins.pending.is_empty(), "assembling the house awards no coins")
	check(not fresh.play_gate.visible and not fresh.bells.complete and not fresh.trophy_case.opened and not fresh.trophy_case.owned, "assembling the house leaves the trophy to the bells")
	fresh.queue_free()
	await process_frame
	finish("Endings")
