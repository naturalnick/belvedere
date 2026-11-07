extends "res://tests/manor_test.gd"

func run() -> void:
	var main := load_manor()
	check(main.scene_fade.color.a == 1.0 and main.play_gate.modulate.a == 1.0, "scene begins dark while menu UI is fully visible")
	var wall := main.wall_title
	check(main.at_title and main.play_gate.mode == "title" and main.controls_locked(), "new game waits on the wall title")
	check(main.rules.player == 0 and main.rules.valid(), "Bedroom start has valid occupancy")
	check(wall.tiles.size() == 9 and wall.get_parent() == main.rooms[0], "nine squares are attached to the Bedroom")
	for slot in 9:
		check(wall.tiles[slot].material_override == ManorGeometry.material(ManorWallTitle.TILE_COLOR, 0.0), "every square is the same plain colour")
	var opening_view := main.player.camera.global_transform
	main.play_gate._open_settings()
	check(not wall.lettering.visible and main.at_title, "settings hide wall lettering without starting play")
	main.play_gate._close_settings()
	check(wall.lettering.visible, "return from settings restores title")
	main.play_gate._activate_primary()
	check(main.at_title and main.controls_locked() and main.play_gate.starting, "Play locks the view during the fade")
	main.play_gate._activate_primary()
	await create_timer(0.25).timeout
	check(main.play_gate.modulate.a > 0 and main.play_gate.modulate.a < 1 and is_equal_approx(main.play_gate.modulate.a, wall.lettering.modulate.a), "title lettering and Play fade together")
	main.play_gate._layout()
	check(wall.lettering.modulate.a < 1, "resize preserves fade progress")
	while main.play_gate.starting:
		await process_frame
	check(not main.at_title and not main.play_gate.visible and not wall.lettering.visible, "Play removes temporary title UI")
	check(main.player.camera.global_transform == opening_view and not main.controls_locked(), "starting play preserves the camera and unlocks control")
	main.play_gate._layout()
	check(not wall.lettering.visible, "resizing during play cannot restore the temporary title")
	main.rules.board = PackedInt32Array([6, 2, 5, 0, -1, 3, 7, 1, 8])
	main.rules.player = 3
	for id in main.rooms:
		main.rooms[id].position = ManorGeometry.center(main.rules.board.find(id))
	main.gap_floor.position = ManorGeometry.center(4) + Vector3.DOWN * 0.02
	main.player.global_position = main.rooms[3].to_global(Vector3(0, 0.02, 1.2))
	main.player.automated = true
	check(main.request_slide(ManorRules.W), "a room can slide into the adjacent gap")
	await main.slide_finished
	check(wall.tiles.all(func(tile: MeshInstance3D) -> bool: return tile.material_override == ManorGeometry.material(ManorWallTitle.TILE_COLOR, 0.0)), "the grid stays plain after a slide")
	var tile_position := wall.tiles[0].global_position
	main.rooms[0].position += Vector3.RIGHT * ManorGeometry.PITCH
	check(wall.tiles[0].global_position.is_equal_approx(tile_position + Vector3.RIGHT * ManorGeometry.PITCH), "fixture travels with its Bedroom wall")
	main.return_to_title()
	check(main.at_title and wall.lettering.visible and not main.fresh_title, "return restores the wall menu and marks next Play as a new game")
	check(main.player.global_position.is_equal_approx(main.rooms[0].to_global(ManorWallTitle.SPAWN)), "returning title uses the Bedroom's current position")
	main.queue_free()
	await process_frame
	finish("Wall title")
