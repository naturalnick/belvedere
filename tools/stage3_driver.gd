extends Node

func run(driver: Node) -> void:
	var main: Manor = driver.main
	main.release_pointer()
	await click(main.play_gate.settings_button)
	driver._check(main.play_gate.mode == "settings", "real gear click opens settings")
	await driver.shot("02_settings")
	await click(main.play_gate.settings_panel.back)
	driver._check(main.play_gate.mode == "pause", "real back click returns to pause")
	main.resume_play()
	await driver.walk_direction(ManorRules.E)
	await driver.walk_to(ManorGeometry.center(7) + Vector3(0, 0, 3.0))
	main.player.aim_at(ManorGeometry.center(7) + Vector3(0, 0, -1))
	await driver.shot("03_cross_tracks")
	await driver.walk_to(Vector3(0, 0, 15))
	main.player.aim_at(Vector3(0, 1.5, 0))
	await driver.shot("04_meadow")
	main.player.aim_at(Vector3(55, 2, 25))
	await driver.shot("05_landscape")
	driver._check(main.rules.player == ManorRules.OUTSIDE, "flat tracks permit walk from gap to lawn")
	await driver.walk_to(ManorGeometry.center(7))
	driver._check(main.rules.player == -1, "return to gap is clear")

func click(button: Button) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = button.global_position + button.size / 2
	Input.parse_input_event(press)
	await get_tree().process_frame
	var release: InputEventMouseButton = press.duplicate()
	release.pressed = false
	Input.parse_input_event(release)
	await get_tree().process_frame
