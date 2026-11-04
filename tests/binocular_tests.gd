extends SceneTree

var checks := 0
var failures := 0
var acquisitions := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func run() -> void:
	create_timer(35).timeout.connect(func() -> void: quit(1))
	var main: Manor = load("res://scenes/manor.tscn").instantiate()
	root.add_child(main)
	var item := main.binoculars
	item.set_process(false)
	item.acquired.connect(func() -> void: acquisitions += 1)
	check(item.owned == not OS.get_cmdline_user_args().has("--earn-binoculars"), "testing grant can be disabled to earn binoculars normally")
	check(not item.toggle(), "title cannot activate binoculars")
	main.start_play()
	main.player.automated = true
	for tick in 6:
		await physics_frame
	item.owned = false
	check(not item.toggle(), "unowned item cannot be used")
	item.owned = true
	var view := main.player.camera.global_transform
	var position := main.player.global_position
	var fov := main.player.camera.fov
	var viewport_bounds := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	for test_fov in [60.0, 75.0, 100.0]:
		main.player.camera.fov = test_fov
		for progress in [0.55, 0.7, 0.85, 1.0]:
			item._pose_held(progress)
			for eye_name in ["LeftEyecup", "RightEyecup"]:
				var eye: MeshInstance3D = item.held_model.get_node(eye_name)
				var bounds := eye.mesh.get_aabb()
				var fits := true
				for corner in 8:
					var at := eye.to_global(bounds.get_endpoint(corner))
					fits = fits and viewport_bounds.has_point(main.player.camera.unproject_position(at)) and main.player.camera.to_local(at).z < -main.player.camera.near
				check(fits, "both eyecups stay on screen and ahead of the near plane during approach at FOV %s" % test_fov)
	main.player.camera.fov = fov
	var original_shadows: Dictionary[Light3D, bool] = {}
	for light: Light3D in main.find_children("*", "Light3D", true, false):
		original_shadows[light] = light.shadow_enabled
	check(item.toggle() and item.held_model.visible and main.controls_locked(), "owned binoculars raise and lock walking")
	check(not item.toggle(), "repeat presses cannot interrupt a transition")
	item._process(0.25)
	var raised := item.held_model.position
	main.release_pointer()
	item._process(1.0)
	check(item.held_model.position == raised and is_equal_approx(item.elapsed, 0.25), "pause freezes the raise")
	main.resume_play()
	item._process(0.40)
	item._process(0.50)
	check(item.phase == ManorBinoculars.Phase.OVERVIEW and item.overview_camera.is_current(), "raise reaches the overhead camera")
	check((-item.overview_camera.global_basis.z).is_equal_approx(Vector3.DOWN), "overview is exactly top-down")
	check(main.player.camera.global_transform.is_equal_approx(view), "overview never changes the first-person camera")
	check(original_shadows.keys().all(func(light: Light3D) -> bool: return light.shadow_enabled == original_shadows[light]), "overview preserves normal shadows")
	for room in main.rooms.values():
		check(not room.ceiling.visible and room.overview_edges.visible and room.overview_roof.visible, "every room shows its colored roof and edge caps")
		check(room.roof_number.text == str([0, 1, 2, 3, 5, 6, 7, 8].find(room.room_id) + 1), "roof numbers follow home order with the center omitted")
		for header in room.door_headers:
			check(not header.visible, "doorway lintels cannot hide connections")
	for clue in main.fruit_clues:
		check(not clue.visible, "overhead inspection cannot reveal window-only fruit")
	check(not main.player.begin_interact() and not main.request_slide(ManorRules.E), "overview blocks interactions and room movement")
	main.coins.award([0])
	var coin_time := main.coin_hud.presentation
	main.coin_hud._process(0.5)
	check(main.coin_hud.presentation == coin_time and main.coins.available == 0, "pending coin presentation waits during binocular use")
	main.player.bot_drive = Vector3.RIGHT
	for tick in 6:
		await physics_frame
	check(main.player.global_position.is_equal_approx(position), "player stays at the original location during overview")
	main.player.bot_drive = Vector3.ZERO
	main.release_pointer()
	check(not item.toggle() and item.overhead, "pause keeps overview and blocks toggling")
	check(original_shadows.keys().all(func(light: Light3D) -> bool: return light.shadow_enabled == original_shadows[light]), "pausing overview preserves normal shadows")
	main.resume_play()
	check(item.toggle(), "second use starts lowering")
	item._process(0.25)
	item._process(0.50)
	check(item.phase == ManorBinoculars.Phase.IDLE and main.player.camera.is_current() and not main.controls_locked(), "lowering restores play")
	check(main.player.camera.global_transform.is_equal_approx(view) and main.player.camera.fov == fov, "return restores exact aim, location and configured FOV")
	check(original_shadows.keys().all(func(light: Light3D) -> bool: return light.shadow_enabled == original_shadows[light]), "lowering restores the original per-light shadow settings")
	main.coin_hud._process(ManorCoinHUD.PRESENT_TIME)
	check(main.coins.available == 1 and main.coins.pending.is_empty(), "pending coin presentation resumes after lowering")
	for room in main.rooms.values():
		check(room.ceiling.visible and not room.overview_edges.visible and not room.overview_roof.visible, "normal room rendering is restored")
	for clue in main.fruit_clues:
		check(clue.visible, "window clues return to their normal shader visibility")
	item.toggle()
	item._process(0.7)
	item._process(0.5)
	main.return_to_title()
	check(item.phase == ManorBinoculars.Phase.IDLE and main.player.camera.is_current() and main.rooms[0].ceiling.visible, "return to menu cancels overview rendering")
	check(original_shadows.keys().all(func(light: Light3D) -> bool: return light.shadow_enabled == original_shadows[light]), "returning to menu restores shadows")
	main.start_play()
	item.owned = false
	var safe := main.study_safe
	main.player.position = safe.to_global(Vector3(0, 0.02, 1.6))
	main.player.aim_at(safe.handle.global_position)
	main.rules.player = 2
	for tick in 6:
		await physics_frame
	for color in 4:
		for tap in ManorFruitClue.COUNTS[color]:
			safe.interact(color)
	safe.interact(-1)
	await create_timer(1.3).timeout
	check(item.presenting and not item.owned and main.controls_locked(), "opening the safe automatically starts its reward presentation")
	var in_safe := item.reward.global_position
	item._process(0.7)
	check(item.reward.global_position.distance_to(main.player.camera.global_position) < in_safe.distance_to(main.player.camera.global_position), "binocular reward flies toward the player")
	main.release_pointer()
	var reward_time := item.reward_elapsed
	item._process(1.0)
	check(item.reward_elapsed == reward_time and not item.owned, "reward presentation pauses without granting early")
	main.resume_play()
	item._process(1.6)
	check(item.owned and item.reward_claimed and not item.presenting and not item.reward.visible and acquisitions == 1, "reward arrives in inventory without a pickup")
	item.present_reward()
	check(not item.presenting and acquisitions == 1, "safe reward is granted only once")
	preload("res://tools/furnishing_fixture.gd").place(main, 2)
	var edge_position: Vector3 = main.rooms[2].overview_edges.global_position
	check(main.request_slide(ManorRules.E), "room can slide after the reward")
	check(not item.toggle(), "binoculars cannot start during a slide")
	while main.sliding:
		await process_frame
	for tick in 6:
		await physics_frame
	check(main.rooms[2].overview_edges.global_position.is_equal_approx(edge_position + Vector3.RIGHT * 6.25), "overview markings ride their room")
	check(main.rooms[2].roof_number.text == "3" and main.rooms[2].overview_roof.global_position == main.rooms[2].global_position, "roof and home number follow the moved Study")
	check(item.toggle(), "binoculars work after moving a room")
	item._process(0.7)
	item._process(0.5)
	check(item.overhead and main.rooms[2].position.is_equal_approx(ManorGeometry.center(4)), "overview shows the current room arrangement")
	item.reset_view()
	main.player.position.y = -1.0
	for tick in 6:
		await physics_frame
	check(not item.toggle(), "binoculars cannot suspend a fall")
	main.fall_recovery._wake()
	check(item.owned and item.reward_claimed, "fall recovery retains binocular ownership")
	main.queue_free()
	await process_frame
	print("Binoculars: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
