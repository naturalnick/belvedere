extends Node

func run(driver: Node) -> void:
	var main: Manor = driver.main
	main.rules.player = ManorRules.OUTSIDE
	main.player.position = Vector3(0, 0.02, 109.3)
	main.player.aim_at(Vector3(0, 0, 125))
	await get_tree().create_timer(0.1).timeout
	await driver.shot("02_edge")
	main.player.bot_drive = Vector3.BACK
	while main.fall_recovery.elapsed < 4.3:
		if main.player.position.y < -42:
			main.player.aim_at(Vector3(0, -ManorIsland.DEPTH, 0))
		await get_tree().physics_frame
	main.player.automated = false
	var yaw := main.player.rotation.y
	var look := InputEventMouseMotion.new()
	look.screen_relative = Vector2(40, -20)
	Input.parse_input_event(look)
	await get_tree().process_frame
	await get_tree().process_frame
	driver._check(main.player.rotation.y != yaw, "real mouse look remains active during the fall")
	main.player.automated = true
	driver._check(not main.recovering and main.player.position.y < -120, "early drop stays free and passes the underside")
	main.player.aim_at(Vector3(0, -ManorIsland.DEPTH, 0))
	await driver.shot("03_underside")
	while not main.recovering:
		await get_tree().physics_frame
	driver._check(main.fall_recovery.elapsed >= 15.0 and main.fall_recovery.elapsed < 15.1, "fade begins after fifteen seconds of falling")
	await get_tree().create_timer(0.3).timeout
	await driver.shot("04_fade_out")
	while main.recovering:
		await get_tree().physics_frame
	driver._check(main.rules.player == 0, "wake in Bedroom")
	await driver.shot("05_bedside")
	main.player.set_physics_process(false)
	main.player.position = Vector3(12, 0, 3)
	main.player.aim_at(Vector3(23, 1.5, 7))
	await driver.shot("06_nearer_greenery")
