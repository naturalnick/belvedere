extends "res://tests/manor_test.gd"

func opening_slides() -> Array[Vector2i]:
	var slides: Array[Vector2i] = []
	var opening := ManorRules.opening_start()
	var reachable: Array[ManorRules] = [opening]
	var visited: Array[int] = [opening.player]
	while not reachable.is_empty():
		var state: ManorRules = reachable.pop_front()
		for direction in 4:
			if state.can_slide(direction):
				slides.append(Vector2i(state.player, direction))
			if state.can_walk(direction):
				var next := state.copy()
				next.apply(ManorRules.WALK, direction)
				if not visited.has(next.player):
					visited.append(next.player)
					reachable.append(next)
	return slides

func run() -> void:
	create_timer(40).timeout.connect(func() -> void: quit(1))
	check(opening_slides() == [Vector2i(8, ManorRules.E)], "Laundry east is the only slide reachable from the Bedroom opening")
	var coins := ManorCoins.new()
	check(not coins.collect(7), "the Foyer has no coin")
	check(coins.collect(0) and coins.collect(1) and not coins.collect(0), "each room's coin can be picked up once")
	check(not coins.insert_one(), "pending coins cannot be spent before presentation")
	coins.receive_next()
	check(coins.available == 1 and coins.pending == [1], "presentation credits exactly one coin")
	check(coins.insert_one() and coins.available == 0 and coins.inserted == 1, "one insertion spends one coin")

	var main := start_manor()
	await physics_frame
	await physics_frame
	check(main.coins.pending.is_empty() and main.coins.available == 0 and main.rules.board[7] == 8 and main.rules.board[8] == -1, "Laundry starts bottom-center with the gap to its right and no coin")
	check(not main.coin_hud.count.visible, "an empty wallet shows no coin count")
	var lamp := main.home_lights.lamps[8]
	check(main.home_lights.lamps.values().all(func(each: ManorBeacon) -> bool: return not each.lit), "no lamp is lit while no room is home")
	check(main.home_lights.progress_lights[6].material_override == ManorGeometry.material("595C59"), "Foyer shows Laundry is not yet home")
	var driver := add_driver(main)
	for direction in driver.walk_route(8):
		await driver.walk_direction(direction, true)
	var guide := main.first_home_guide
	guide.set_process(false)
	check(main.rules.player == 8 and not guide.active and not main.controls_locked() and not lamp.lit, "entering the Laundry away from home does nothing")
	var openings := [0]
	for id in main.rooms:
		for door in main.rooms[id].doors:
			door.swung.connect(func(opening: bool) -> void: openings[0] += int(opening))
	await driver.objective_action(Vector2i(ManorRules.SLIDE, ManorRules.E), true)
	check(openings[0] > 0, "the doors open on docking without waiting for the guided look")
	check(main.rules.board[8] == 8 and guide.active and main.controls_locked() and not lamp.lit and main.coins.pending.is_empty(), "sliding the Laundry home starts the guided look with the lamp still off")
	var entry_position := main.player.position
	guide._process(0.95)
	var toward_lamp := (lamp.globe.global_position - main.player.camera.global_position).normalized()
	check((-main.player.camera.global_basis.z).dot(toward_lamp) > 0.999, "guided view centers the actual lamp")
	var elapsed_before := guide.elapsed
	main.release_pointer()
	guide._process(3.0)
	check(guide.elapsed == elapsed_before and not lamp.lit, "pause freezes the guided look")
	main.resume_play()
	var guided_yaw := main.player.rotation.y
	main.player.automated = false
	var mouse := InputEventMouseMotion.new()
	mouse.screen_relative = Vector2(300, 100)
	main.player._unhandled_input(mouse)
	main.player.automated = true
	main.player.bot_drive = Vector3.RIGHT
	await physics_frame
	await physics_frame
	main.player.bot_drive = Vector3.ZERO
	check(main.player.rotation.y == guided_yaw and main.player.position == entry_position and not main.player.begin_interact(), "guided look blocks mouse, movement and interactions")
	guide._process(0.85)
	check(lamp.lit and lamp.light.light_color == Color("FFF0DA") and guide.active, "the lamp turns warm during the look")
	guide._process(1.0)
	var drawer := main.coin_drawers[8]
	check(not guide.active and not main.controls_locked() and not drawer.opened and main.coins.pending.is_empty(), "the look ends on the lamp and leaves the drawer closed")
	main.refresh_progress()
	check(not guide.active, "refreshing never repeats the guided look")
	check(main.home_lights.progress_lights[6].material_override == ManorGeometry.glowing_material("FFF0DA"), "Foyer globe lights when Laundry comes home")

	main.player.global_position = drawer.to_global(Vector3(0, 0, drawer.travel + 0.85))
	main.player.global_position.y = 0.02
	main.player.aim_at(drawer.front_hit.global_position)
	await physics_frame
	await physics_frame
	check(main.player.begin_interact() and drawer.opened, "trying the drawer of a home room opens it")
	drawer._process(ManorCoinDrawer.OPEN_TIME)
	main.player.aim_at(drawer.coin.global_position)
	await physics_frame
	await physics_frame
	check(main.player.begin_interact() and main.coins.pending == [8], "normal interaction picks the physical coin up from the drawer")
	driver.queue_free()
	var before := main.coin_hud.presentation
	main.release_pointer()
	main.coin_hud._process(2)
	check(main.coin_hud.presentation == before and main.coins.available == 0 and not main.coin_hud.visible, "pause hides and preserves coin presentation")
	main.resume_play()
	main.coin_hud.presentation = 0.0
	main.coin_hud._process(0.2)
	main.coin_hud._input(key_press())
	check(not main.coin_hud.accepted, "a press while the coin is still arriving is ignored")
	main.coin_hud._process(0.4)
	check(main.coins.available == 0 and main.coin_hud.presentation > 0.5, "coin is presented before inventory increments")
	main.coin_hud._process(5.0)
	check(main.coins.available == 0 and main.coin_hud.presentation == ManorCoinHUD.HOLD_AT and main.controls_locked(), "presented coin waits in view, with the player held, until a press")
	main.coin_hud._input(key_press(KEY_ESCAPE))
	check(not main.coin_hud.accepted, "Escape does not accept the coin")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	main.coin_hud._input(click)
	main.coin_hud._process(ManorCoinHUD.PRESENT_TIME - ManorCoinHUD.HOLD_AT)
	check(main.coins.available == 1 and main.coin_hud.count.text == "1" and main.coin_hud.count.visible, "a mouse press sends the coin to the visible inventory count")

	# Move the Laundry away in a fixture: lighting changes, ownership and the open drawer do not.
	main.rules.board[8] = -1
	main.rules.board[7] = 8
	main.refresh_progress()
	check(not lamp.lit and main.coins.available == 1 and drawer.opened, "moving a room away puts out its lamp without touching its coin")
	var globe := main.home_lights.progress_lights[6]
	check(globe.material_override == ManorGeometry.material("595C59"), "Foyer globe goes dark when its room leaves home")
	main.rules.board[7] = -1
	main.rules.board[8] = 8
	main.refresh_progress()
	check(lamp.lit and globe.material_override == ManorGeometry.glowing_material("FFF0DA"), "lamp and Foyer globe relight when the room returns")
	check(main.coins.available == 1 and main.coins.pending.is_empty(), "returning a room cannot farm coins")

	# An unopened drawer only works while its room is home.
	var bedroom_drawer := main.coin_drawers[0]
	check(main.rules.board[0] != 0, "fixture Bedroom is away from home")
	check(bedroom_drawer.interact() and not bedroom_drawer.opened, "an away room's drawer rattles instead of opening")
	bedroom_drawer._process(1)
	var home_board := main.rules.board.duplicate()
	var bedroom_slot := home_board.find(0)
	var bedroom_occupant := home_board[0]
	home_board[bedroom_slot] = bedroom_occupant
	home_board[0] = 0
	main.rules.board = home_board
	check(bedroom_drawer.interact() and bedroom_drawer.opened, "the same drawer opens once its room is home")
	home_board[0] = bedroom_occupant
	home_board[bedroom_slot] = 0
	main.rules.board = home_board
	bedroom_drawer._process(ManorCoinDrawer.OPEN_TIME)
	check(bedroom_drawer.opened and bedroom_drawer.coin.visible, "an opened drawer stays open and keeps its coin after its room leaves home")
	main.fall_recovery._wake()
	check(main.coins.available == 1, "fall recovery retains coins")
	main.queue_free()
	await process_frame
	finish("Coins")
