extends Node

func run(driver: Node) -> void:
	var main: Manor = driver.main
	# Earn the introduction through play; stage later rewards for the short prize gallery.
	driver._check(main.coins.awarded.is_empty() and main.coins.available == 0, "no starting coin before moving the blue room home")
	var first_room := main.objectives.active
	var path := ManorObjectives.nearest_goal(main.rules, [first_room], true)
	for action: Vector2i in path.path:
		if action.x == ManorRules.WALK and ManorRules.neighbor(main.rules.slot(), action.y) == main.rules.board.find(first_room):
			await driver.walk_to(ManorGeometry.center(main.rules.slot()) + ManorGeometry.DIRECTIONS[action.y] * 2.65)
			main.player.aim_at(main.rooms[first_room].global_position + Vector3.UP * 2.4)
			await driver.shot("blue_shade")
		await driver.objective_action(action, true)
	driver._check(main.first_coin_guide.active and main.controls_locked(), "first room starts guided lamp look")
	while main.first_coin_guide.elapsed < 1.0:
		await get_tree().process_frame
	await driver.shot("guided_blue")
	while not main.first_coin_guide.completed:
		await get_tree().process_frame
	await driver.shot("guided_warm")
	while main.first_coin_guide.holding_reward():
		await get_tree().process_frame
	driver._check(main.coins.pending == [first_room] and main.objectives.active != first_room, "moving room home presents first coin and changes target")
	await get_tree().create_timer(0.35).timeout
	await driver.shot("coin_presented")
	await get_tree().create_timer(1.5).timeout
	driver._check(main.coins.pending == [first_room] and main.coins.available == 0 and main.coin_hud.presentation == ManorCoinHUD.HOLD_AT, "presented coin waits in view for a press")
	await driver.accept_rewards()
	while main.first_coin_guide.active:
		await get_tree().process_frame
	main.player.aim_at(main.rooms[first_room].global_position + Vector3.UP * 2.4)
	if main.wall_title != null:
		driver._check(main.wall_title.tiles[main.rules.board.find(main.objectives.active)].material_override == main.wall_title.blue_material and main.wall_title.tiles[first_room].material_override != main.wall_title.blue_material, "first earned coin advances the permanent wall target")
	await driver.shot("warm_shade")
	await driver.shot("coin_count")
	main.coins.award(ManorObjectives.ROOMS)
	await driver.accept_rewards()
	await deposit_all(driver)
	await driver.shot("ending_1")
	await driver.hover_button(main.play_gate.primary, "hover_keep_playing")
	await driver.hover_button(main.play_gate.secondary, "hover_quit")
	var original_size := get_window().size
	get_window().size = Vector2i(640, 480)
	await get_tree().process_frame
	await driver.shot("ending_1_small")
	get_window().size = original_size
	await get_tree().process_frame
	driver.key_event(KEY_ENTER, true)
	driver.key_event(KEY_ENTER, false)
	await get_tree().process_frame
	driver._check(not main.play_gate.visible, "Keep Playing resumes through keyboard")
	await driver.shot("trophy_released")
	driver._check(not main.won, "trophy ending does not open the assembled-house exit")
	driver._check(not main.coin_device.interact(), "finished device accepts no more coins or ending triggers")
	main.show_coin_ending()
	main.play_gate.secondary.grab_focus()
	driver.key_event(KEY_ENTER, true)
	driver.key_event(KEY_ENTER, false)
	await get_tree().process_frame
	driver._check(main.at_title and main.play_gate.mode == "title", "Quit to Menu returns to title")
	await driver.shot("coin_title")

func deposit_all(driver: Node) -> void:
	var main: Manor = driver.main
	for direction in driver.walk_route(7):
		await driver.walk_direction(direction)
	await driver.walk_to(main.coin_device.to_global(Vector3(0, 0, 2.60)))
	await driver.walk_to(main.coin_device.to_global(Vector3(0, 0, 1.55)))
	main.player.aim_at(main.coin_device.to_global(Vector3(0, 1.25, 0.3)))
	await driver.shot("coin_device")
	main.player.aim_at(main.coin_device.to_global(Vector3(0, 0.84, 0.32)))
	await get_tree().physics_frame
	var hit := main.player.focus()
	driver._check(not hit.is_empty() and hit.collider.has_meta("coin_device"), "native interaction ray reaches cabinet")
	for i in range(main.coins.inserted, 7):
		main.player.automated = false
		var keyboard := i % 2 == 0
		if keyboard:
			driver.key_event(KEY_E, true)
		else:
			driver.mouse_button(true)
		await get_tree().process_frame
		driver._check(main.coins.inserted == i + 1, "one fresh press inserts exactly one coin")
		if i == 0:
			await get_tree().create_timer(0.22).timeout
			await driver.shot("coin_inserting")
		while main.coin_device.busy:
			await get_tree().process_frame
		if keyboard:
			var repeat := InputEventKey.new()
			repeat.physical_keycode = KEY_E
			repeat.keycode = KEY_E
			repeat.pressed = true
			repeat.echo = true
			Input.parse_input_event(repeat)
			await get_tree().process_frame
			driver._check(main.coins.inserted == i + 1, "held E never spends a second coin")
			driver.key_event(KEY_E, false)
		else:
			driver.mouse_button(false)
		main.player.automated = true
		if i == 0:
			await driver.shot("coin_deposited")
	driver._check(main.coins.available == 0 and main.coins.remaining() == 0, "seven deposits exhaust the wallet and device requirement")
	driver._check(main.play_gate.visible and main.play_gate.mode == "victory", "last deposit presents the trophy completion screen")
