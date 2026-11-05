extends SceneTree

var checks := 0
var failures := 0
var clinks := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)


func press(key: Key = KEY_SPACE) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = true
	return event

func receive_coin(main: Manor) -> void:
	main.coin_hud._process(ManorCoinHUD.HOLD_AT)
	main.coin_hud._input(press())
	main.coin_hud._process(ManorCoinHUD.PRESENT_TIME)

func run() -> void:
	create_timer(40).timeout.connect(func() -> void: quit(1))
	var coins := ManorCoins.new()
	coins.award([0, 0, 7, 1])
	check(coins.pending == [0, 1] and coins.available == 0, "only distinct objective rooms queue coins; no invisible inventory grant")
	check(not coins.insert_one(), "pending coins cannot be spent before presentation")
	coins.receive_next()
	check(coins.available == 1 and coins.pending == [1], "presentation credits exactly one coin")
	check(coins.insert_one() and coins.available == 0 and coins.remaining() == 6, "one deposit consumes one coin")
	coins.award(ManorObjectives.ROOMS)
	while not coins.pending.is_empty():
		coins.receive_next()
	while coins.remaining() > 0:
		check(coins.insert_one(), "remaining distinct rewards can be deposited")
	coins.award(ManorObjectives.ROOMS)
	coins.receive_next()
	check(coins.pending.is_empty() and coins.available == 0 and not coins.insert_one(), "completed rewards cannot be farmed or deposited twice")

	var main: Manor = load("res://scenes/manor.tscn").instantiate()
	root.add_child(main)
	main.start_play()
	main.player.automated = true
	main.audio.cued.connect(func(group: String) -> void:
		if group == "coin_insert":
			clinks += 1)
	await physics_frame
	await physics_frame
	check(main.coins.pending.is_empty() and main.coins.available == 0 and main.objectives.active == 8 and main.rules.board[7] == 8 and main.rules.board[8] == -1, "Laundry starts blue at bottom-center with the gap to its right and no coin")
	main.coin_hud._process(3.0)
	main.refresh_progress()
	check(main.coins.pending.is_empty() and main.coins.available == 0, "waiting or refreshing cannot earn the first coin")
	check(not main.coin_hud.count.visible, "an empty wallet shows no coin count")
	var target := main.objectives.active
	var lamp := main.objective_display.lamps[target]
	check(lamp.light.light_color == Color("6EBFFF") and lamp.state == 1, "starting target is blue before its slide home")
	check(lamp.shade.material_override == ManorGeometry.material("B4CFDF", 0.006), "active shade has a subtle blue tint")
	check(main.objective_display.progress_lights[6].material_override == ManorGeometry.material("595C59"), "Foyer shows Laundry is not yet home")
	var driver: Node = load("res://tools/demo_driver.gd").new()
	root.add_child(driver)
	driver.main = main
	driver.started = Time.get_ticks_msec()
	for direction in driver.walk_route(8):
		await driver.walk_direction(direction, true)
	var guide := main.first_coin_guide
	guide.set_process(false)
	main.refresh_progress()
	check(main.rules.player == 8 and not guide.active and not main.controls_locked() and lamp.state == 1 and main.coins.pending.is_empty(), "entering Laundry leaves its lamp blue and earns nothing")
	await driver.objective_action(Vector2i(ManorRules.SLIDE, ManorRules.E), true)
	check(main.rules.board[8] == 8 and main.rules.board[7] == -1 and guide.active and main.controls_locked() and lamp.state == 1 and main.coins.pending.is_empty(), "sliding Laundry home starts the guided look before awarding")
	var entry_position := main.player.position
	guide._process(0.95)
	var toward_lamp := (lamp.globe.global_position - main.player.camera.global_position).normalized()
	check((-main.player.camera.global_basis.z).dot(toward_lamp) > 0.999, "guided view centers the actual target lamp")
	var elapsed_before := guide.elapsed
	main.release_pointer()
	guide._process(3.0)
	check(guide.elapsed == elapsed_before and lamp.state == 1, "pause freezes the guided look before completion")
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
	main.coin_hud._process(0.4)
	check(lamp.state == 2 and guide.holding_reward() and main.coin_hud.presentation == 0, "warm light is shown before the token presentation starts")
	guide._process(0.5)
	check(main.coins.pending == [8] and main.coins.available == 0, "sliding the target home queues its coin presentation")
	check(main.objectives.completed.has(8) and main.objectives.active != 8, "first slide completes the initial target and selects the next one")
	check(lamp.state == 2 and lamp.light.light_color == Color("FFF0DA"), "visited home room becomes warm")
	check(lamp.shade.material_override == ManorGeometry.material("DDD3BD", 0.006), "completed shade returns to cream")
	driver.queue_free()
	var before := main.coin_hud.presentation
	main.release_pointer()
	main.coin_hud._process(2)
	check(main.coin_hud.presentation == before and main.coins.available == 0 and not main.coin_hud.visible, "pause hides and preserves coin presentation")
	main.resume_play()
	main.coin_hud.presentation = 0.0
	main.coin_hud._process(0.2)
	main.coin_hud._input(press())
	check(not main.coin_hud.accepted, "a press while the coin is still arriving is ignored")
	main.coin_hud._process(0.4)
	check(main.coins.available == 0 and main.coin_hud.presentation > 0.5, "coin is presented before inventory increments")
	main.coin_hud._process(5.0)
	check(main.coins.available == 0 and main.coin_hud.presentation == ManorCoinHUD.HOLD_AT and main.controls_locked(), "presented coin waits in view, with the player held, until a press")
	main.coin_hud._input(press(KEY_ESCAPE))
	check(not main.coin_hud.accepted, "Escape does not accept the coin")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	main.coin_hud._input(click)
	main.coin_hud._process(ManorCoinHUD.PRESENT_TIME - ManorCoinHUD.HOLD_AT)
	check(main.coins.available == 1 and main.coin_hud.count.text == "1", "a mouse press sends the coin to the visible inventory count")
	check(main.coin_hud.count.visible, "the wallet appears when the first coin arrives")
	guide._process(0.0)
	guide.set_process(true)
	check(not guide.active and not main.controls_locked(), "control returns only after the token arrives in the wallet")
	main.refresh_progress()
	check(not guide.active, "revisiting or refreshing never repeats the guided look")
	check(main.coins.available == 1 and main.coins.pending.is_empty(), "refreshing the same board cannot grant another coin")

	# Move a completed room away in a fixture: lighting changes, ownership does not.
	main.rules.board[8] = -1
	main.rules.board[7] = 8
	main.refresh_progress()
	check(main.objective_display.lamps[8].state == 0 and main.coins.available == 1, "moving an earned room away extinguishes its lamp without removing its coin")
	var globe := main.objective_display.progress_lights[6]
	check(globe.material_override == ManorGeometry.material("595C59"), "Foyer globe goes dark when its room leaves home")
	main.rules.board[7] = -1
	main.rules.board[8] = 8
	main.refresh_progress()
	check(globe.material_override == ManorGeometry.glowing_material("FFF0DA"), "Foyer globe relights when the room returns")
	check(main.coins.available == 1 and main.coins.pending.is_empty(), "returning a completed room cannot farm coins")

	main.rules.player = 7
	main.player.global_position = main.coin_device.to_global(Vector3(0, 0.02, 1.55))
	main.player.aim_at(main.coin_device.to_global(Vector3(0, 0.84, 0.32)))
	await physics_frame
	await physics_frame
	var hit := main.player.focus()
	check(not hit.is_empty() and hit.collider.has_meta("coin_device"), "device slot is reachable through the real interaction ray")
	main.player.begin_interact()
	await process_frame
	check(main.coins.available == 0 and main.coins.inserted == 1 and main.coin_hud.count.text == "0", "focused interaction inserts exactly one coin and updates HUD")
	check(not main.coin_hud.count.visible, "depositing the last held coin hides the wallet again")
	for piece in main.coin_device.token.find_children("*", "MeshInstance3D", true, false):
		check(piece.material_override is ShaderMaterial, "the slot coin compiles no shader of its own on first insert")
	check(main.coin_device.token.visible and main.coin_device.remaining_label.text == "6", "device presents an insertion and remaining requirement")
	main.player.release_interact()
	main.release_pointer()
	await create_timer(0.8).timeout
	check(main.coin_device.busy and clinks == 0 and main.coins.inserted == 1, "pausing an insertion preserves its single deposit and suspends its clink")
	main.resume_play()
	await create_timer(0.75).timeout
	check(clinks == 1 and not main.coin_device.token.visible, "accepted insertion produces one recorded coin clink")
	main.coins.award([0])
	receive_coin(main)
	main.player.begin_interact()
	check(not main.player.begin_interact(), "device rejects overlapping insertions while its slot is occupied")
	main.player.release_interact()
	await create_timer(0.75).timeout
	check(main.coins.inserted == 2 and main.coins.available == 0 and clinks == 2, "another interaction inserts one coin and clinks once")
	main.player.begin_interact()
	main.player.release_interact()
	await create_timer(0.75).timeout
	check(main.coins.inserted == 2 and clinks == 2, "empty interaction neither deposits nor plays a false clink")
	main.fall_recovery._wake()
	check(main.coins.inserted == 2 and main.coins.awarded.size() == 2, "fall recovery retains earned and deposited coins")
	main.queue_free()
	await process_frame
	print("Coins: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
