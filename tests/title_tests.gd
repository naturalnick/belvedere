extends SceneTree
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func run() -> void:
	var main: Manor = load("res://scenes/manor.tscn").instantiate()
	root.add_child(main)
	check(main.scene_fade.color.a == 1.0 and main.play_gate.modulate.a == 1.0, "scene begins dark while menu UI is fully visible")
	var wall := main.wall_title
	check(main.at_title and main.play_gate.mode == "title" and main.controls_locked(), "new game waits on the wall title")
	check(main.rules.player == 0 and main.rules.valid(), "Bedroom start has valid occupancy")
	check(wall.tiles.size() == 9 and wall.get_parent() == main.rooms[0], "nine squares are attached to the Bedroom")
	check(wall.tiles.slice(0, 8).all(func(tile: MeshInstance3D) -> bool: return tile.material_override == ManorGeometry.material(ManorWallTitle.TILE_COLOR, 0.0)), "all non-target squares share one dark color")
	check(wall.tiles[8].material_override == wall.blue_material and main.coins.awarded.is_empty(), "initial blue corner grants no coin")
	check(wall.tiles[8].position.is_equal_approx(Vector3(-0.235, 1.945, 0)), "southeast starting target appears bottom-left when facing west")
	check(wall.tiles[0].position.is_equal_approx(Vector3(0.235, 2.415, 0)), "northwest board corner appears top-right on the wall map")
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
	main.objectives.active = 3
	main.refresh_progress()
	check(wall.tiles[5].material_override == wall.blue_material and wall.tiles[8].material_override != wall.blue_material, "blue marker uses target room 3 current slot 5, not its home slot")
	main.rules.board = PackedInt32Array([6, 2, 5, 0, -1, 3, 7, 1, 8])
	main.rules.player = 3
	for id in main.rooms:
		main.rooms[id].position = ManorGeometry.center(main.rules.board.find(id))
	main.gap_floors.clear()
	main.gap_floors[4] = main.gap_floor
	main.gap_floor.position = ManorGeometry.center(4) + Vector3.DOWN * 0.02
	main.player.global_position = main.rooms[3].to_global(Vector3(0, 0.02, 1.2))
	main.player.automated = true
	check(main.request_slide(ManorRules.W), "target room can slide into the adjacent gap")
	await main.slide_finished
	check(main.objectives.active == 3 and wall.tiles[4].material_override == wall.blue_material and wall.tiles[5].material_override != wall.blue_material, "blue marker follows the target room after a real slide")
	main.objectives.active = -1
	wall.refresh(-1, main.rules.board)
	check(wall.tiles.all(func(tile: MeshInstance3D) -> bool: return tile.material_override != wall.blue_material), "no blue square remains after all targets are complete")
	var tile_position := wall.tiles[0].global_position
	main.rooms[0].position += Vector3.RIGHT * ManorGeometry.PITCH
	check(wall.tiles[0].global_position.is_equal_approx(tile_position + Vector3.RIGHT * ManorGeometry.PITCH), "fixture travels with its Bedroom wall")
	main.return_to_title()
	check(main.at_title and wall.lettering.visible and not main.fresh_title, "return restores the wall menu and marks next Play as a new game")
	check(main.player.global_position.is_equal_approx(main.rooms[0].to_global(ManorWallTitle.SPAWN)), "returning title uses the Bedroom's current position")
	main.queue_free()
	await process_frame
	print("Wall title: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
