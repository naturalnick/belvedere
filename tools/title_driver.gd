extends Node

func run(driver: Node) -> void:
	var main: Manor = driver.main
	var wall := main.wall_title
	driver._check(main.at_title and main.rules.player == 0 and main.controls_locked(), "new game opens at the Bedroom wall")
	driver._check(wall.lettering.visible and wall.tiles.size() == 9 and main.coins.awarded.is_empty(), "title has nine permanent squares and no starting reward")
	driver._check(wall.tiles[8].material_override == wall.blue_material, "opening target is the lower-left blue square")
	await driver.shot("00_scene_fade")
	await get_tree().create_timer(1.0).timeout
	await driver.shot("01_title")
	main.play_gate._open_controls()
	await driver.shot("controls_owned")
	main.play_gate._close_controls()
	main.binoculars.owned = false
	main.play_gate._open_controls()
	await driver.shot("controls_unearned")
	main.play_gate._close_controls()
	main.binoculars.owned = true
	await driver.hover_button(main.play_gate.primary, "hover_play")
	await driver.hover_button(main.play_gate.sound_button, "hover_sound")
	await driver.hover_button(main.play_gate.settings_button, "hover_settings")
	var gate := main.play_gate
	driver._check(gate.primary.text == "Play" and not ManorInkButton.keyboard_nav, "wall Play is lettering and only the hovered button is marked")
	gate.primary.grab_focus()
	driver.key_event(KEY_SHIFT, true)
	driver.key_event(KEY_SHIFT, false)
	await get_tree().process_frame
	driver._check(ManorInkButton.keyboard_nav and gate.primary.has_focus(), "keyboard input tints the focused button")
	await driver.shot("focus_keyboard")
	main.play_gate._open_settings()
	await driver.hover_button(main.play_gate.settings_panel.toggles["invert_y"], "hover_invert")
	await driver.hover_button(main.play_gate.settings_panel.back, "hover_back")
	main.play_gate._close_settings()
	var original_size := get_window().size
	for dimensions in [Vector2i(640, 480), Vector2i(360, 640)]:
		get_window().size = dimensions
		await get_tree().create_timer(0.15).timeout
		driver._check(Rect2(Vector2.ZERO, main.play_gate.size).encloses(main.play_gate.primary.get_rect()), "wall Play remains reachable after resize")
		main.play_gate._open_controls()
		await driver.shot("controls_%d" % dimensions.x)
		main.play_gate._close_controls()
		main.play_gate._open_settings()
		await driver.shot("settings_%d" % dimensions.x)
		main.play_gate._close_settings()
		await driver.shot("02_title_small" if dimensions.x == 640 else "03_title_portrait")
	get_window().size = original_size
	await get_tree().create_timer(0.15).timeout
	var opening_view := main.player.camera.global_transform
	driver.mouse_button(true)
	driver.mouse_button(false)
	await get_tree().create_timer(0.25).timeout
	driver._check(main.play_gate.starting and main.play_gate.modulate.a > 0 and main.play_gate.modulate.a < 1 and wall.lettering.modulate.a < 1, "title and Play visibly fade together")
	await driver.shot("03_start_fade")
	while main.play_gate.starting:
		await get_tree().process_frame
	await driver.check_pointer_input()
	driver._check(not main.at_title and not wall.lettering.visible and not main.play_gate.visible, "Play removes temporary title and button")
	driver._check(main.player.camera.global_transform.origin.distance_to(opening_view.origin) < 0.05, "Play keeps the player in the same viewpoint")
	driver._check(wall.tiles.all(func(tile: MeshInstance3D) -> bool: return tile.is_visible_in_tree()), "physical wall fixture remains during play")
	get_window().size = Vector2i(640, 480)
	await get_tree().create_timer(0.15).timeout
	driver._check(not wall.lettering.visible, "resizing during play keeps the title hidden")
	get_window().size = original_size
	await get_tree().create_timer(0.15).timeout
	await driver.shot("04_playing")
	main.release_pointer()
	await driver.hover_button(main.play_gate.primary, "hover_resume")
	main.resume_play()
	main.objectives.active = 3
	main.refresh_progress()
	driver._check(wall.tiles[main.rules.board.find(3)].material_override == wall.blue_material and wall.tiles[8].material_override == ManorGeometry.material(ManorWallTitle.TILE_COLOR, 0.0), "blue square locates the target room in the current layout")
	await driver.shot("05_grid_target")
	main.return_to_title()
	driver._check(main.at_title and wall.lettering.visible, "return to menu restores the Bedroom wall title")
	await driver.shot("06_title_return")
