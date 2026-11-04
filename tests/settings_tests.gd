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
	main.start_play()
	main.player.automated = true
	var original := main.preferences
	var path := "user://settings-test-%d.cfg" % OS.get_process_id()
	main.preferences.storage_path = path
	main.release_pointer()
	main.play_gate._open_settings()
	var panel: ManorSettingsPanel = main.play_gate.settings_panel
	panel.sliders["fov"].value = 92
	panel.sliders["sensitivity"].value = 0.004
	panel.toggles["invert_y"].button_pressed = true
	panel.sliders["master"].value = 0.6
	panel.sliders["effects"].value = 0.4
	panel.sliders["music"].value = 0.2
	check(main.controls_locked(), "settings lock game input")
	check(main.player.camera.fov == 92 and is_equal_approx(main.player.sensitivity, 0.004), "view sliders update actual camera and mouse")
	check(main.player.invert_y, "toggle applies preference")
	for pair in [["Master", 0.6], ["Effects", 0.4], ["Music", 0.2]]:
		check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(pair[0]))), pair[1]), "volume slider controls its bus")
	var saved := ManorPreferences.new()
	saved.load_file(path)
	check(saved.fov == 92 and saved.invert_y and is_equal_approx(saved.music, 0.2), "settings persist")
	main.play_gate._close_settings()
	check(main.play_gate.mode == "pause" and main.play_gate.settings_button.has_focus(), "back returns to pause with focus")
	main.play_gate.show_mode("title")
	main.play_gate._open_settings()
	main.play_gate._close_settings()
	check(main.play_gate.mode == "title", "settings remembers title origin")
	for dimensions in [Vector2(1280, 720), Vector2(640, 480), Vector2(360, 640)]:
		panel.size = dimensions
		panel._layout()
		for control: Control in panel.get_children():
			check(Rect2(Vector2.ZERO, dimensions).encloses(control.get_rect()), "settings fit supported viewport")
	main.play_gate.show_mode("pause")
	main.binoculars.owned = false
	main.play_gate._open_controls()
	var controls: ManorControlsPanel = main.play_gate.controls_panel
	check(not controls.rows[ManorControlsPanel.ACTIONS.find("Binoculars")].visible, "unearned binoculars are absent from controls")
	main.play_gate._close_controls()
	main.binoculars.owned = true
	main.play_gate._open_controls()
	check(controls.rows[ManorControlsPanel.ACTIONS.find("Binoculars")].visible, "owned binoculars reveal the B control")
	for dimensions in [Vector2(1280, 720), Vector2(640, 480), Vector2(360, 640)]:
		controls.size = dimensions
		controls._layout()
		for control: Control in controls.get_children():
			check(Rect2(Vector2.ZERO, dimensions).encloses(control.get_rect()), "controls fit supported viewport")
	main.play_gate._close_controls()
	var gap := Node3D.new()
	root.add_child(gap)
	ManorGeometry.build_gap_floor(gap)
	check(gap.get_child_count() == 2, "gap contains only slab mesh and slab collider")
	check(gap.get_child(0).mesh.get_aabb().end.y + gap.get_child(0).position.y == 0, "tracks never rise above slab")
	DirAccess.remove_absolute(path)
	original.load_file()
	original.apply(main.player)
	main.queue_free()
	gap.queue_free()
	await process_frame
	print("Settings and tracks: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
