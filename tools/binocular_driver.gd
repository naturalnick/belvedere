extends Node

func run(driver: Node) -> void:
	var main: Manor = driver.main
	var binoculars := main.binoculars
	driver._check(not binoculars.owned, "binoculars start unowned")
	# Grant them for the viewing shots; the safe reward is captured afterwards and still presents once.
	binoculars.owned = true
	await get_tree().create_timer(0.18).timeout
	var original_view := main.player.camera.global_transform
	var original_fov := main.player.camera.fov
	var original_shadows: Dictionary[Light3D, bool] = {}
	for light: Light3D in main.find_children("*", "Light3D", true, false):
		original_shadows[light] = light.shadow_enabled
	await _press_b(driver)
	driver._check(binoculars.phase == ManorBinoculars.Phase.RAISING, "B raises binoculars")
	await get_tree().create_timer(0.27).timeout
	await driver.shot("binoculars_raising")
	await get_tree().create_timer(0.15).timeout
	await driver.shot("binoculars_approaching")
	await get_tree().create_timer(0.07).timeout
	await driver.shot("binoculars_eyecups")
	await get_tree().create_timer(0.56).timeout
	driver._check(binoculars.phase == ManorBinoculars.Phase.OVERVIEW, "raise reaches overhead camera")
	driver._check(original_shadows.keys().all(func(light: Light3D) -> bool: return light.shadow_enabled == original_shadows[light]), "rendered overview retains normal cast shadows")
	await driver.shot("binoculars_overview")
	_check_framing(driver)
	var window_size := get_window().size
	for dimensions in [Vector2i(800, 800), Vector2i(640, 900)]:
		get_window().size = dimensions
		await get_tree().process_frame
		await get_tree().process_frame
		await driver.shot("binoculars_%dx%d" % [dimensions.x, dimensions.y])
		_check_framing(driver)
	get_window().size = window_size
	await get_tree().process_frame
	main.player.automated = false
	driver.key_event(KEY_ESCAPE, true)
	driver.key_event(KEY_ESCAPE, false)
	await get_tree().process_frame
	driver._check(main.play_gate.visible and binoculars.overhead, "Escape pauses the overhead view")
	await driver.shot("binoculars_paused")
	main.resume_play()
	main.player.automated = true
	await _press_b(driver)
	await get_tree().create_timer(0.34).timeout
	await driver.shot("binoculars_lowering")
	await get_tree().create_timer(0.40).timeout
	driver._check(binoculars.phase == ManorBinoculars.Phase.IDLE and main.player.camera.is_current(), "B restores first-person camera")
	driver._check(main.player.camera.global_transform.is_equal_approx(original_view) and main.player.camera.fov == original_fov, "position, aim and FOV survive binocular use")
	await driver.shot("binoculars_returned")
	var safe := main.study_safe
	main.player.position = safe.to_global(Vector3(0, 0.02, 1.6))
	main.player.velocity = Vector3.ZERO
	main.rules.player = 2
	main.player.aim_at(safe.handle.global_position)
	await get_tree().physics_frame
	await get_tree().physics_frame
	for i in 4:
		for tap in ManorFruitClue.COUNTS[i]:
			safe.interact(i)
	main.player.automated = false
	driver.key_event(KEY_E, true)
	driver.key_event(KEY_E, false)
	await get_tree().process_frame
	main.player.automated = true
	while not binoculars.presenting:
		await get_tree().process_frame
	await get_tree().create_timer(0.24).timeout
	await driver.shot("binoculars_safe_pop")
	await get_tree().create_timer(0.65).timeout
	await driver.shot("binoculars_reward")
	await get_tree().create_timer(1.5).timeout
	driver._check(binoculars.presenting and not binoculars.reward_claimed and binoculars.reward.visible, "binocular reward waits in view for a press")
	await driver.accept_rewards()
	driver._check(binoculars.reward_claimed and binoculars.owned and not binoculars.reward.visible, "a key press sends the safe reward to inventory once")
	await driver.shot("binoculars_acquired")
	await _press_b(driver)
	await get_tree().create_timer(1.1).timeout
	await driver.shot("binoculars_from_study")
	driver._check(binoculars.overhead, "reward is usable from Study")
	await _press_b(driver)
	await get_tree().create_timer(0.75).timeout

func _press_b(driver: Node) -> void:
	driver.main.player.automated = false
	driver.key_event(KEY_B, true)
	await get_tree().process_frame
	var phase: int = driver.main.binoculars.phase
	var repeat := InputEventKey.new()
	repeat.physical_keycode = KEY_B
	repeat.keycode = KEY_B
	repeat.pressed = true
	repeat.echo = true
	Input.parse_input_event(repeat)
	await get_tree().process_frame
	driver._check(driver.main.binoculars.phase == phase, "holding B does not retrigger the transition")
	driver.key_event(KEY_B, false)
	driver.main.player.automated = true

func _check_framing(driver: Node) -> void:
	var camera: Camera3D = driver.main.binoculars.overview_camera
	var bounds := get_viewport().get_visible_rect().grow(-12)
	for x in [-9.375, 9.375]:
		for z in [-9.375, 9.375]:
			driver._check(bounds.has_point(camera.unproject_position(Vector3(x, 0, z))), "entire board fits with a margin")
