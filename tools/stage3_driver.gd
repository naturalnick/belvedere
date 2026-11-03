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
	for direction in driver.walk_route(0):
		await driver.walk_direction(direction)
	var bedroom: ManorRoom = main.rooms[0]
	await driver.walk_to(bedroom.position + Vector3(0, 0, 2.2))
	main.player.aim_at(bedroom.position + Vector3(0, 1.05, -1.8))
	await driver.shot("06_bedroom_entry")
	await driver.walk_to(bedroom.position + Vector3(1.2, 0, 1.0))
	main.player.aim_at(bedroom.position + Vector3(-1.65, 0.8, -1.9))
	await driver.shot("07_bed_and_table")
	await driver.walk_to(bedroom.position + Vector3(0, 0, 1.1))
	main.player.aim_at(bedroom.position + Vector3(2.5, 1.0, 1.9))
	await driver.shot("08_wardrobe")
	main.player.aim_at(bedroom.position + Vector3(-1.9, 1.25, 2.6))
	await driver.shot("11_dresser")
	await driver.walk_to(bedroom.position + Vector3(0, 0, -1.2))
	main.player.aim_at(bedroom.position + Vector3(2.1, 0.7, -2.0))
	await driver.shot("12_reading_chair")
	driver._check(main.rules.player == 0, "trial bedroom is entered and walked physically")
	for direction in driver.walk_route(7):
		await driver.walk_direction(direction)
	await driver.objective_action(Vector2i(ManorRules.SLIDE, ManorRules.E))
	for direction in driver.walk_route(0):
		await driver.walk_direction(direction)
	await driver.approach_lever(bedroom)
	main.player.aim_at(bedroom.lever.global_position + Vector3.UP * 0.8)
	await get_tree().physics_frame
	await driver.hold_lever_input(ManorRules.S, true)
	await driver.shot("09_bedroom_lever")
	var bed: Node3D = bedroom.get_node("BedroomFurnishings/Bed")
	var before := bed.global_position
	var rider := bedroom.to_local(main.player.global_position)
	driver.release_lever_input(true)
	driver._check(main.sliding, "real input starts furnished Bedroom slide")
	main.player.aim_at(bed.global_position + Vector3.UP * 0.6)
	await get_tree().create_timer(0.7).timeout
	driver._check(bed.global_position.z > before.z and bed.global_position.z < before.z + 6.25, "bed rides room mid-slide")
	await driver.shot("10_bedroom_sliding")
	while main.sliding:
		await get_tree().process_frame
	driver._check(bed.global_position.is_equal_approx(before + Vector3.BACK * 6.25), "bed moves exactly with room")
	driver._check(bedroom.to_local(main.player.global_position).distance_to(rider) < 0.001, "player rides furnished room")

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
