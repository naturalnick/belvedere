extends "res://tests/manor_test.gd"

func receive_pending(main: Manor) -> void:
	while not main.coins.pending.is_empty():
		main.coins.receive_next()

func run() -> void:
	create_timer(35).timeout.connect(func() -> void: quit(1))
	var main := load_manor()
	var stats := main.run_stats
	stats.set_process(false)
	stats._process(30.0)
	check(stats.elapsed_seconds == 0 and not stats.started, "title time is excluded")
	main.start_play()
	main.player.automated = true
	main.first_home_guide.seen = true
	stats._process(12.75)
	check(stats.elapsed_seconds == 12.75 and stats.time_text() == "0:12", "active play accumulates time with a minutes and seconds readout")
	for mode in ["pause", "settings", "controls", "sleep"]:
		main.play_gate.show_mode(mode)
		stats._process(20)
		check(stats.elapsed_seconds == 12.75, "%s menu pauses the timer" % mode)
	main.resume_play()
	stats._process(0.25)
	check(stats.elapsed_seconds == 13, "closing a menu resumes the timer")
	stats.elapsed_seconds = 3661.8
	check(stats.time_text() == "1:01:01", "long runs include hours")
	stats.elapsed_seconds = 13
	main.rules.player = 8
	main.player.position = main.rooms[8].position + Vector3(0, 0.02, 1.2)
	var opening := main.rules.board.duplicate()
	check(not main.request_slide(ManorRules.N) and stats.shifts == 0, "blocked shifts do not count")
	check(main.request_slide(ManorRules.E) and stats.shifts == 0, "shift counts wait for committed movement")
	await main.slide_finished
	receive_pending(main)
	check(stats.shifts == 1, "first completed shift counts once")
	check(main.request_slide(ManorRules.W), "reverse room shift starts")
	await main.slide_finished
	receive_pending(main)
	check(stats.shifts == 2 and main.rules.board == opening, "back-and-forth room movement counts both shifts")
	main.fall_recovery._wake()
	await physics_frame
	await physics_frame
	check(main.player.begin_interact(), "bed opens for tracked sleep")
	main.play_gate._activate_secondary()
	check(stats.sleeps == 0 and stats.shifts == 2, "cancelling sleep leaves statistics unchanged")
	check(main.player.begin_interact(), "bed can be used after cancelling")
	main.play_gate._activate_primary()
	main.play_gate._activate_primary()
	check(stats.sleeps == 1 and stats.sleep_count() == "1", "confirmed bed sleep counts once without an asterisk")
	stats._process(2.0)
	while main.bed_sleep.sleeping:
		await process_frame
	check(main.slides == 0 and stats.shifts == 2 and stats.sleeps == 1 and stats.elapsed_seconds == 15, "bed reset retains cumulative shifts, sleeps and time")
	main.rules.player = 8
	main.player.position = main.rooms[8].position + Vector3(0, 0.02, 1.2)
	check(main.request_slide(ManorRules.E), "rooms remain movable after sleeping")
	await main.slide_finished
	receive_pending(main)
	check(main.slides == 1 and stats.shifts == 3, "new shifts add to the cumulative count after a bed reset")
	main.fall_recovery._recover()
	main.fall_recovery._recover()
	check(stats.sleeps == 2 and stats.falls == 1 and stats.sleep_count() == "2*", "fall recovery counts once as a sleep and marks the total")
	while main.recovering:
		await process_frame
	check(stats.sleeps == 2 and stats.shifts == 3, "waking from a fall does not count again or reset shifts")
	main.rules.board = PackedInt32Array(ManorRules.HOME)
	main.refresh_progress()
	receive_pending(main)
	preload("res://tools/conservatory_fixture.gd").finish_reveal(main)
	for door in main.rooms[7].doors:
		if door.is_front:
			main.conservatory.unlock_exit(door)
			main.conservatory._process(ManorConservatory.UNLOCK_TIME)
			door.set_open(true, true)
	main.begin_finale()
	stats._process(100)
	check(stats.finished and stats.elapsed_seconds == 15, "entering the finale freezes active run time")
	main.finale_motion.kill()
	main.run_summary.reveal()
	check(main.run_summary.totals.text == "Shifts 3\nSleeps 2*\nTime 0:15", "end-screen totals include cumulative shifts and marked sleeps")
	check(main.run_summary.continue_hint.text == "Any key to continue", "ending shows the continue hint")
	main.return_to_title()
	stats._process(50)
	check(stats.elapsed_seconds == 15 and not main.run_summary.visible, "menu return preserves the finished record and hides results")
	main.queue_free()
	await process_frame
	finish("Run tracking")
