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
	main.start_play()
	main.player.automated = true
	await physics_frame
	await physics_frame
	check(main.objective_display.lamps.size() == 7 and not main.objective_display.lamps.has(7), "exactly seven pendants, excluding Foyer")
	check(main.objective_display.progress_lights.size() == 7, "separate Foyer chandelier tracks seven room placements")
	check(main.objective_display.lamps[main.objectives.active].state == 1, "active room has active pendant")
	for lamp: ManorBeacon in main.objective_display.lamps.values():
		check(not lamp.is_processing() and lamp.globe.scale == Vector3.ONE, "objective lamps have no continuous animation or scaling")
		check((lamp.light.light_energy > 0) == (lamp.state > 0), "target and in-place rooms emit light")
	var front: ManorDoor
	for door in main.rooms[7].doors:
		if door.is_front:
			front = door
	for mesh: MeshInstance3D in front.find_children("*", "MeshInstance3D", true, false):
		check(not mesh.material_override is StandardMaterial3D, "front door has no transparent glass material")
	check(not front.opened and front.gate.collision_layer == 1, "bonus door starts locked")
	main.objectives.completed.assign([0, 1, 2, 3, 5, 6])
	main.objectives.active = 8
	main.rules.player = 8
	main.refresh_progress()
	for id in main.objective_display.lamps:
		var lamp: ManorBeacon = main.objective_display.lamps[id]
		check(lamp.state == (2 if main.rules.board[id] == id else 0), "completed room lamp tracks placement, not earned progress")
	check(main.objectives.all_completed and not main.won, "all coins can be earned independently of assembled house")
	check(not main.controls_locked() and not main.play_gate.visible, "earning the last coin does not end play")
	check(not front.opened and not main.carpet.visible and not main.ending.active, "coin objectives do not unlock bonus exit")
	main.coins.award(ManorObjectives.ROOMS)
	while not main.coins.pending.is_empty():
		main.coin_hud._process(ManorCoinHUD.PRESENT_TIME)
	for i in 7:
		check(main.coin_device.interact(), "device accepts coin %d" % (i + 1))
		while main.coin_device.busy:
			await process_frame
	check(main.controls_locked() and main.play_gate.mode == "victory", "seventh deposit opens the trophy ending")
	check(main.play_gate.title_label.text == "Thanks for Playing" and main.play_gate.trophy_view.visible, "ending presents a trophy and Thanks for Playing")
	check(not front.opened and not main.won, "trophy prize leaves the original door locked")
	check(main.play_gate.primary.has_focus() and main.play_gate.primary.text == "Keep Playing", "ending offers a keyboard-focusable Keep Playing button")
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
	check(not main.controls_locked(), "Enter continues after trophy victory")
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
	main.queue_free()
	await process_frame
	var fresh: Manor = load("res://scenes/manor.tscn").instantiate()
	root.add_child(fresh)
	fresh.start_play()
	fresh.player.automated = true
	check(fresh.coins.inserted == 0 and fresh.coins.available == 0 and fresh.coins.pending.is_empty() and fresh.objectives.active == 8, "a fresh game resets the wallet, device and presentation queue")
	fresh.rules.board = PackedInt32Array(ManorRules.HOME)
	fresh.refresh_progress()
	check(fresh.won and fresh.coins.awarded.size() == 7, "assembling the house first grants all outstanding room coins")
	check(not fresh.play_gate.visible and fresh.coins.inserted == 0, "house-first ending never bypasses the trophy's coin deposits")
	fresh.queue_free()
	await process_frame
	print("Endings: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
