extends "res://tests/manor_test.gd"

func face_bed(main: Manor) -> void:
	main.fall_recovery._wake()
	await physics_frame
	await physics_frame

func shift_once(main: Manor) -> void:
	for room in main.rooms:
		var state := main.rules.copy()
		state.player = room
		for direction in 4:
			if not state.can_slide(direction):
				continue
			main.rules = state
			main.player.position = main.rooms[room].position + Vector3(0, 0.02, 1.2)
			check(main.request_slide(direction), "a real room shift starts")
			check(not main.bed_sleep.available() and not main.bed_sleep.interact(), "bed remains inactive before the first shift commits")
			await main.slide_finished
			while not main.coins.pending.is_empty():
				main.coins.receive_next()
			return
	check(false, "opening has a legal shift")

func run() -> void:
	create_timer(45).timeout.connect(func() -> void: quit(1))
	var main := start_manor()
	main.first_home_guide.seen = true
	var opening := main.rules.board.duplicate()
	await face_bed(main)
	var hit := main.player.focus()
	check(not hit.is_empty() and hit.collider.has_meta("bed"), "real interaction ray hits the bed")
	check(not main.player.begin_interact() and not main.bed_sleep.available(), "bed does nothing before the first shift")
	await shift_once(main)
	await face_bed(main)
	var shifted := main.rules.board.duplicate()
	var at_bed := main.player.global_transform
	check(main.player.begin_interact() and main.play_gate.mode == "sleep" and main.controls_locked(), "bed opens confirmation after the first completed shift")
	check(main.play_gate.title_label.text == "Start over?" and main.play_gate.primary.text == "Sleep" and main.play_gate.secondary.text == "Cancel", "confirmation offers only Sleep and Cancel")
	check(main.play_gate.secondary.has_focus(), "Cancel receives initial keyboard focus")
	main.play_gate._activate_secondary()
	check(not main.play_gate.visible and main.rules.board == shifted and main.player.global_transform == at_bed, "Cancel preserves the layout and viewpoint")
	check(main.player.begin_interact(), "bed can be used again after cancelling")
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	main.play_gate._unhandled_key_input(escape)
	var web_entry := OS.get_cmdline_user_args().has("--web-entry")
	check(main.play_gate.visible == web_entry and main.rules.board == shifted, "Escape cancels without resetting and respects browser pointer capture")
	if web_entry:
		check(main.play_gate.mode == "pause", "browser Escape leaves Resume available for pointer recapture")
		main.resume_play()
	main.coins.collected.assign([1, 3, 8])
	main.bells.ring(0)
	main.bells.ring(6)
	main.coins.available = 2
	main.coins.inserted = 1
	main.coins.changed.emit()
	main.binoculars.owned = true
	main.binoculars.reward_claimed = true
	main.study_safe.counts.assign(ManorFruitClue.COUNTS)
	main.study_safe.unlocked = true
	main.study_safe.door.rotation.y = deg_to_rad(-105)
	main.stopwatch.owned = true
	main.stopwatch.claimed = true
	main.stopwatch.model.reparent(main.stopwatch, true)
	main.foundation_hatch.emptied = true
	main.stopwatch.solver.build()
	check(main.player.begin_interact(), "owned rewards still permit bed interaction")
	main.play_gate._activate_primary()
	main.play_gate._activate_primary()
	check(main.bed_sleep.sleeping and main.recovering and not main.play_gate.visible, "Sleep begins one locked transition")
	check(not main.player.begin_interact() and not main.request_slide(ManorRules.N), "sleep blocks further interactions and slides")
	await create_timer(0.3).timeout
	check(main.fade.color.a > 0 and main.fade.color.a < 1 and main.rules.board == shifted, "layout remains unchanged while fading out")
	await create_timer(0.8).timeout
	check(main.rules.board == opening and main.slides == 0 and main.recovering, "layout resets under darkness before waking")
	while main.bed_sleep.sleeping:
		await process_frame
	for tick in 4:
		await physics_frame
	check(not main.controls_locked() and is_zero_approx(main.fade.color.a), "wake restores controls and clears the fade")
	check(main.rules.player == 0 and main.rules.valid() and main.player.position.distance_to(main.rooms[0].to_global(ManorFallRecovery.BEDSIDE)) < 0.1, "player wakes safely by the bed in its original room position")
	for room in main.rooms:
		check(main.rooms[room].position.is_equal_approx(ManorGeometry.center(opening.find(room))), "room geometry returns to the opening layout")
	check(main.gap_floor.position.is_equal_approx(ManorGeometry.center(opening.find(-1)) + Vector3.DOWN * 0.02), "gap floor returns to the opening gap")
	check(not main.bed_sleep.available() and not main.player.begin_interact(), "bed waits for another shift after sleep")
	check(main.coins.collected == [1, 3, 8] and main.coins.available == 2 and main.coins.inserted == 1 and main.coins.pending.is_empty(), "sleep preserves collected and spent tokens without awarding duplicates")
	check(main.bells.progress == 2, "sleep keeps bell progress")
	check(main.binoculars.owned and main.binoculars.reward_claimed and main.study_safe.unlocked and is_equal_approx(main.study_safe.door.rotation.y, deg_to_rad(-105)), "binoculars and their open safe retain progress")
	check(main.stopwatch.owned and main.stopwatch.claimed and main.foundation_hatch.emptied, "stopwatch and emptied hatch retain progress")
	check(main.stopwatch.remaining == main.stopwatch.solver.assembly_distance(main.rules), "stopwatch hint updates to the reset layout")
	check(main.stopwatch.toggle(), "retained stopwatch remains usable after waking")
	main.stopwatch.reset_view()
	# Tokens may be finished while the house still needs assembling.
	main.coins.collected.assign(ManorCoins.ROOMS)
	main.coins.available = ManorCoins.ROOMS.size() - main.coins.inserted
	main.slides = 1
	check(main.player.begin_interact(), "finishing the token quest still allows resetting an unfinished house")
	main.play_gate._activate_primary()
	while main.bed_sleep.sleeping:
		await process_frame
	check(main.coins.collected.size() == 7 and not main.won and main.coins.available == 6, "tokens survive resetting the rooms")
	main.rules = ManorRules.new(PackedInt32Array(ManorRules.HOME), 0)
	main.rules.lawn_access = main.bed_sleep.opening_rules.lawn_access
	main.slides = 1
	for room in main.rooms:
		main.rooms[room].position = ManorGeometry.center(room)
	main.gap_floor.position = ManorGeometry.center(4) + Vector3.DOWN * 0.02
	await face_bed(main)
	main.refresh_progress()
	check(main.won and not main.bed_sleep.available() and not main.player.begin_interact(), "assembling the house disables bed interaction")
	main.bed_sleep.sleep()
	check(not main.bed_sleep.sleeping and not main.play_gate.visible and main.rules.board == PackedInt32Array(ManorRules.HOME), "disabled bed cannot reset the completed puzzle")
	check(main.conservatory.revealing() and not main.carpet.visible and not main.ending.active, "trying the bed preserves the conservatory reveal without bypassing the key")
	main.player.bot_drive = Vector3.BACK
	var before := main.player.position
	await create_timer(0.4).timeout
	check(main.player.position.distance_to(before) > 0.7, "player can walk away after waking")
	main.queue_free()
	await process_frame
	finish("Bed sleep")
