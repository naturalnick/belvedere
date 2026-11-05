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
	create_timer(25).timeout.connect(func() -> void:
		printerr("FAIL: fall recovery timed out")
		quit(1))
	var main: Manor = load("res://scenes/manor.tscn").instantiate()
	root.add_child(main)
	main.start_play()
	main.player.automated = true
	# Move Bedroom to a different slot so respawning at its home or old position fails.
	var old_slot := main.rules.board.find(0)
	var gap := main.rules.board.find(-1)
	main.rules.board[gap] = 0
	main.rules.board[old_slot] = -1
	main.rooms[0].position = ManorGeometry.center(gap)
	main.gap_floor.position = ManorGeometry.center(old_slot) + Vector3.DOWN * 0.02
	var layout := main.rules.board.duplicate()
	var earned := main.objectives.completed.duplicate()
	main.rules.player = ManorRules.OUTSIDE
	main.player.position = Vector3(109.5, 0, 0)
	main.player.bot_drive = Vector3.RIGHT
	await create_timer(0.5).timeout
	check(main.player.position.x > 110.3 and main.player.position.y < 0, "player walks off the edge with no boundary wall")
	while main.fall_recovery.elapsed < 14.8:
		await physics_frame
	check(not main.controls_locked() and main.fade.color.a == 0, "fifteen-second fall keeps controls and view unobstructed")
	var elapsed := main.fall_recovery.elapsed
	var paused_position := main.player.position
	main.release_pointer()
	await create_timer(0.2).timeout
	check(main.fall_recovery.elapsed == elapsed and main.player.position == paused_position, "pause suspends both the fall and its timer")
	main.resume_play()
	check(main.player.position.y < -150, "flat underside does not catch falling player")
	var drop_y := main.player.position.y
	await create_timer(0.4).timeout
	check(main.recovering and main.fade.color.a > 0, "fall fades out after fifteen seconds")
	check(main.player.position.y < drop_y, "fall continues during fade-out")
	await create_timer(1.6).timeout
	check(not main.recovering and is_zero_approx(main.fade.color.a), "wake-up fades back in and restores controls")
	check(main.run_stats.sleeps == 1 and main.run_stats.falls == 1 and main.run_stats.sleep_count() == "1*", "walking off the map counts exactly one marked sleep")
	check(main.player.position.distance_to(main.rooms[0].to_global(ManorFallRecovery.BEDSIDE)) < 0.1, "wake beside bed in moved Bedroom")
	check(main.rules.player == 0 and main.rules.gap_slot == -1, "respawn restores room occupancy")
	check(main.rules.board == layout and main.objectives.completed == earned and main.slides == 0, "recovery preserves puzzle and objective progress")
	await create_timer(0.4).timeout
	check(main.player.is_on_floor(), "bedside position is safe on the floor")
	main.player.bot_drive = Vector3.BACK
	var before := main.player.position
	await create_timer(0.4).timeout
	check(main.player.position.distance_to(before) > 0.7, "player can walk away from bed after recovery")
	# One slide from assembled, so the next target stays reachable once this one completes.
	main.rules.board = PackedInt32Array([0, -1, 2, 3, 1, 5, 6, 7, 8])
	for id in main.rooms:
		main.rooms[id].position = ManorGeometry.center(main.rules.board.find(id))
	main.objectives.active = 0
	main.first_coin_guide.seen = true
	main.rules.player = ManorRules.OUTSIDE
	main.fall_recovery._recover()
	await create_timer(0.7).timeout
	check(main.objectives.completed.has(0) and main.coin_drawers[0].opened, "waking in the home blue room completes its objective")
	main.queue_free()
	await process_frame
	print("Fall recovery: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
