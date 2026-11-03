extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func run() -> void:
	var main: Manor = load("res://scenes/manor.tscn").instantiate()
	root.add_child(main)
	main.player.automated = true
	await physics_frame
	await physics_frame
	check(main.objective_display.lamps.size() == 7 and not main.objective_display.lamps.has(7), "exactly seven pendants, excluding Foyer")
	check(main.objective_display.progress_lights.size() == 7, "separate Foyer chandelier tracks seven objectives")
	check(main.objective_display.lamps[main.objectives.active].state == 1, "active room has active pendant")
	for lamp: ManorBeacon in main.objective_display.lamps.values():
		check(not lamp.is_processing() and lamp.globe.scale == Vector3.ONE, "objective lamps have no continuous animation or scaling")
		for shutter in lamp.shutters:
			check(is_equal_approx(shutter.rotation.x, -1.15), "every lamp stays open, including inactive lamps")
	var front: ManorDoor
	for door in main.rooms[7].doors:
		if door.is_front:
			front = door
	for mesh: MeshInstance3D in front.find_children("*", "MeshInstance3D", true, false):
		check(not mesh.material_override is StandardMaterial3D, "front door has no transparent glass material")
	check(not front.opened and front.gate.collision_layer == 1, "bonus door starts locked")
	main.objectives.completed.assign([0, 1, 2, 3, 5, 6])
	main.objectives.active = 8
	main.refresh_progress()
	check(main.objectives.main_won and not main.won, "main win can happen independently of bonus")
	check(main.controls_locked() and main.play_gate.mode == "victory", "main victory stops input and offers explicit finish")
	check(not front.opened and not main.carpet.visible and not main.ending.active, "main win does not unlock bonus exit")
	check(main.play_gate.primary.has_focus() and main.play_gate.primary.accessibility_name == "Continue", "victory offers a named keyboard-focusable continue icon")
	var accept := InputEventKey.new()
	accept.keycode = KEY_ENTER
	accept.physical_keycode = KEY_ENTER
	accept.pressed = true
	Input.parse_input_event(accept)
	await process_frame
	var release: InputEventKey = accept.duplicate()
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame
	check(not main.controls_locked(), "Enter continues after main victory")
	main.rules.board = PackedInt32Array(ManorRules.HOME)
	for id in main.rooms:
		main.rooms[id].position = ManorGeometry.center(id)
	main.refresh_progress()
	check(main.won and front.opened and front.gate.collision_layer == 0, "assembled house opens bonus exit")
	check(main.carpet.visible and main.ending.active and main.ending.rainbow.visible, "carpet and rainbow activate only for bonus")
	main.ending.set_process(false)
	main.player.set_physics_process(false)
	main.player.position = Vector3(0, 0, 16)
	for i in 500:
		main.ending._process(0.12)
	check(main.ending.total_spawned > ManorEnding.FLOWER_LIMIT and main.ending.spawned == ManorEnding.FLOWER_LIMIT, "continuous flower growth uses bounded recycling")
	for at in main.ending.positions:
		check(absf(at.x) > 9.55 or absf(at.z) > 9.55, "flowers stay off house footprint")
		check(not (absf(at.x) < 1.15 and at.z > 9.2 and at.z < 23), "flowers stay off carpet")
		var offset := at - main.player.position
		offset.y = 0
		check(offset.length() <= 7.01 and offset.length() >= 2.49, "flowers grow near player")
	main.rules.player = 7
	main.player.position = Vector3(0, 0, 9.5)
	main.update_occupant()
	check(main.in_finale and main.controls_locked(), "crossing unlocked front door begins finale")
	await create_timer(11.6).timeout
	check(main.at_title and main.play_gate.mode == "title", "finale returns to title")
	check(not main.ending.is_processing(), "flower updates stop at title")
	print("Endings: %d checks, %d failures" % [checks, failures])
	main.queue_free()
	await process_frame
	quit(1 if failures else 0)
