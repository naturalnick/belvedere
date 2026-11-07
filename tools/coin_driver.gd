extends Node

func run(driver: Node) -> void:
	var main: Manor = driver.main
	driver._check(main.coins.collected.is_empty() and main.coins.available == 0, "no starting coin")
	for direction in driver.walk_route(8):
		await driver.objective_action(Vector2i(ManorRules.WALK, direction), true)
	main.player.aim_at(main.rooms[8].global_position + Vector3.UP * 2.4)
	await driver.shot("dark_lamp")
	await driver.objective_action(Vector2i(ManorRules.SLIDE, ManorRules.E), true)
	driver._check(main.first_home_guide.active and main.controls_locked(), "the first room home starts the guided lamp look")
	while main.first_home_guide.elapsed < 1.0:
		await get_tree().process_frame
	await driver.shot("guided_turn")
	while not main.first_home_guide.completed:
		await get_tree().process_frame
	await driver.shot("guided_warm")
	while main.first_home_guide.active:
		await get_tree().process_frame
	driver._check(main.coins.pending.is_empty() and not main.coin_drawers[8].opened, "the drawer waits to be tried")
	await driver.collect_room_coin(8, true)
	await driver.shot("coin_count")
	preload("res://tools/furnishing_fixture.gd").place(main, 5)
	await get_tree().physics_frame
	await driver.walk_to(main.player_piano.to_global(Vector3(0, 0, 1.75)))
	main.player.aim_at(main.player_piano.to_global(Vector3(0, 0.95, 0)))
	await driver.shot("piano_front")
	await driver.walk_to(main.player_piano.to_global(Vector3(-1.3, 0, 1.2)))
	main.player.aim_at(main.player_piano.to_global(Vector3(0, 0.8, 0.2)))
	await driver.shot("piano_side")
	await driver.walk_to(main.player_piano.to_global(Vector3(0.3, 0, 1.15)))
	main.player.aim_at(main.player_piano.to_global(ManorPianoArt.SLOT_POSITION))
	await get_tree().physics_frame
	var hit := main.player.focus()
	driver._check(not hit.is_empty() and hit.collider.has_meta("piano"), "native interaction ray reaches the piano")
	main.player.automated = false
	driver.key_event(KEY_E, true)
	await get_tree().process_frame
	driver._check(main.coins.inserted == 1, "one fresh press inserts exactly one coin")
	await get_tree().create_timer(0.22).timeout
	await driver.shot("coin_inserting")
	while main.player_piano.busy:
		await get_tree().process_frame
	driver.key_event(KEY_E, false)
	main.player.automated = true
	await get_tree().create_timer(1.0).timeout
	main.player.aim_at(main.player_piano.to_global(Vector3(0, 0.95, 0)))
	await driver.shot("piano_playing")
	driver._check(main.audio.song_playing(), "the song is playing")
	for room in ManorCoins.ROOMS:
		main.coins.collect(room)
	await driver.accept_rewards()
	while main.coins.available > 0:
		driver._check(main.player_piano.interact(), "the piano takes every coin")
		while main.player_piano.busy:
			await get_tree().process_frame
	await driver.shot("piano_all_coins")
