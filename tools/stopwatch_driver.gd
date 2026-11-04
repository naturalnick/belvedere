extends Node

func run(driver: Node) -> void:
	var main: Manor = driver.main
	var watch := main.stopwatch
	var hatch := main.foundation_hatch
	preload("res://tools/stopwatch_fixture.gd").place(main, true)
	while not watch.solver.ready:
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	await driver.shot("stopwatch_approach")
	# Walk in from the lawn through the actual collision geometry.
	main.player.bot_drive = Vector3.RIGHT
	while main.player.position.x < -5.55:
		await get_tree().physics_frame
	main.player.bot_drive = Vector3.ZERO
	main.player.position = hatch.position + Vector3(0, 0.02, 1.0)
	main.player.aim_at(hatch.handle.global_position)
	await get_tree().create_timer(0.2).timeout
	await driver.shot("stopwatch_hatch_closed")
	driver._check(main.player.begin_interact(), "real ray opens foundation hatch")
	await get_tree().create_timer(0.45).timeout
	await driver.shot("stopwatch_hatch_opening")
	await get_tree().create_timer(0.38).timeout
	await driver.shot("stopwatch_hatch_open")
	while not watch.presenting:
		await get_tree().process_frame
	driver._check(watch.claimed, "opening automatically collects the watch")
	await get_tree().create_timer(0.22).timeout
	await driver.shot("stopwatch_lifting")
	await get_tree().create_timer(0.65).timeout
	await driver.shot("stopwatch_flying")
	await get_tree().create_timer(0.6).timeout
	await driver.shot("stopwatch_reward")
	await get_tree().create_timer(0.45).timeout
	driver._check(hatch.emptied and not hatch.opened and not hatch.busy and is_zero_approx(hatch.lid.rotation.x), "hatch automatically settles closed behind the reward")
	await driver.shot("stopwatch_hatch_reclosed")
	var window_size := get_window().size
	var content_size := get_window().content_scale_size
	get_window().content_scale_size = Vector2i(640, 900)
	get_window().size = Vector2i(640, 900)
	await get_tree().create_timer(0.2).timeout
	await driver.shot("stopwatch_reward_portrait")
	get_window().content_scale_size = content_size
	get_window().size = window_size
	await get_tree().process_frame
	driver.key_event(KEY_T, true)
	driver.key_event(KEY_T, false)
	await get_tree().create_timer(0.7).timeout
	driver._check(watch.owned and watch.phase == ManorStopwatch.Phase.IDLE and watch.hud.shows_icon(), "accepting T collects into inventory without raising")
	await driver.shot("stopwatch_inventory")
	main.binoculars.owned = true
	await driver.shot("stopwatch_inventory_all")
	while not watch.solver.ready:
		await get_tree().process_frame
	main.player.aim_at(main.rooms[0].global_position + Vector3.UP)
	main.player.automated = false
	driver.key_event(KEY_T, true)
	driver.key_event(KEY_T, false)
	await get_tree().create_timer(0.5).timeout
	driver._check(watch.phase == ManorStopwatch.Phase.VIEWING, "T raises watch through live input")
	driver.key_event(KEY_T, true)
	driver.key_event(KEY_T, false)
	await get_tree().create_timer(0.4).timeout
	driver._check(watch.phase == ManorStopwatch.Phase.IDLE, "T also lowers the watch")
	driver.key_event(KEY_T, true)
	driver.key_event(KEY_T, false)
	await get_tree().create_timer(0.5).timeout
	main.player.automated = true
	await driver.shot("stopwatch_view")
	var view_position := main.player.position
	var view_rotation := main.player.rotation
	var camera_rotation := main.player.camera.rotation
	main.player.position = Vector3(-3.46, 0.02, -6.25)
	main.player.aim_at(main.rooms[0].position + Vector3(0, 1.65, 0))
	await driver.shot("stopwatch_near_wall")
	main.player.position = view_position
	main.player.rotation = view_rotation
	main.player.camera.rotation = camera_rotation
	for dimensions in [Vector2i(800, 800), Vector2i(640, 900), Vector2i(360, 640)]:
		get_window().content_scale_size = dimensions
		get_window().size = dimensions
		await get_tree().create_timer(0.2).timeout
		await driver.shot("stopwatch_view_%dx%d" % [dimensions.x, dimensions.y])
	get_window().content_scale_size = content_size
	get_window().size = window_size
	await get_tree().process_frame
	main.player.automated = false
	driver.key_event(KEY_ESCAPE, true)
	driver.key_event(KEY_ESCAPE, false)
	await get_tree().create_timer(0.4).timeout
	driver._check(watch.phase == ManorStopwatch.Phase.IDLE and not main.play_gate.visible, "Escape stows watch without pausing")
	driver.key_event(KEY_T, true)
	driver.key_event(KEY_T, false)
	await get_tree().create_timer(0.5).timeout
	var walking_start := main.player.position
	driver.key_event(KEY_W, true)
	await get_tree().create_timer(0.12).timeout
	driver._check(watch.phase == ManorStopwatch.Phase.LOWERING and main.player.position.distance_to(walking_start) > 0.01, "live W starts walking while the watch lowers")
	await driver.shot("stopwatch_walk_stow")
	await get_tree().create_timer(0.3).timeout
	driver.key_event(KEY_W, false)
	driver._check(watch.phase == ManorStopwatch.Phase.IDLE and not watch.model.visible, "continued walking leaves the watch stowed")
	main.player.automated = true
	main.release_pointer()
	main.play_gate._open_controls()
	await driver.shot("stopwatch_controls")
