extends Node

var main: Manor
var shots_dir := ""
var checks := 0
var failures := 0
var shot_count := 0
var started := 0
var action_number := 0
var mode := "single-gap"

func run(game: Manor) -> void:
	main = game
	shots_dir = ProjectSettings.globalize_path("res://screenshots/capture")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			shots_dir = arg.trim_prefix("--shots=")
		if arg.begins_with("--mode="):
			mode = arg.trim_prefix("--mode=")
	if mode not in ["single-gap", "ending", "furnishings", "trees", "exterior", "fall", "coins", "bells", "title", "safe", "binoculars", "stopwatch", "sleep", "conservatory"]:
		printerr("Capture mode must be single-gap, ending, furnishings, trees, exterior, fall, coins, bells, title, safe, binoculars, stopwatch, sleep or conservatory")
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute(shots_dir)
	started = Time.get_ticks_msec()
	# Remove this mode's outputs so stale success frames cannot survive a failed run.
	var shot_names: Array = []
	if mode == "conservatory":
		shot_names = ["01_spawn", "conservatory_retracting", "conservatory_rising", "conservatory_docked", "conservatory_interior", "conservatory_roof", "conservatory_shaft", "conservatory_seating", "conservatory_planting", "red_key_pedestal", "red_key_reward", "red_door_keyhole", "red_key_unlocking", "red_key_inventory", "red_key_inventory_portrait", "red_door_unlocked"]
	elif mode == "sleep":
		shot_names = ["sleep_bed", "sleep_prompt", "sleep_prompt_portrait", "sleep_fade", "sleep_wake", "sleep_watch"]
	elif mode == "stopwatch":
		shot_names = ["stopwatch_approach", "stopwatch_hatch_closed", "stopwatch_hatch_opening", "stopwatch_hatch_open", "stopwatch_lifting", "stopwatch_flying", "stopwatch_reward", "stopwatch_hatch_reclosed", "stopwatch_reward_portrait", "stopwatch_inventory", "stopwatch_inventory_all", "stopwatch_view", "stopwatch_near_wall", "stopwatch_view_800x800", "stopwatch_view_640x900", "stopwatch_view_360x640", "stopwatch_controls"]
	elif mode == "binoculars":
		shot_names = ["binoculars_raising", "binoculars_approaching", "binoculars_eyecups", "binoculars_overview", "binoculars_800x800", "binoculars_640x900", "binoculars_lowering", "binoculars_returned", "binoculars_safe_pop", "binoculars_reward", "binoculars_reward_800x800", "binoculars_reward_640x900", "binoculars_acquired", "binoculars_from_study"]
	elif mode == "safe":
		shot_names = ["safe_closed", "safe_entered", "safe_open", "safe_room"]
		for kind in 4:
			for view in ["window", "window_empty", "inside", "closed_door", "open_door"]:
				shot_names.append("fruit_%d_%s" % [kind, view])
	elif mode == "title":
		shot_names = ["01_title", "02_title_small", "03_title_portrait", "03_start_fade", "04_playing", "06_title_return", "hover_play", "hover_sound", "hover_settings", "hover_invert", "hover_back", "hover_resume", "00_scene_fade", "controls_owned", "controls_unearned", "controls_640", "controls_360", "settings_640", "settings_360"]
	elif mode == "coins":
		shot_names = ["01_spawn", "dark_lamp", "guided_turn", "guided_warm", "drawer_8_open", "coin_presented", "drawer_8_empty", "coin_count", "piano_front", "piano_side", "coin_inserting", "piano_playing", "piano_all_coins"]
	elif mode == "bells":
		shot_names = ["bell_0", "bell_6", "bell_2", "bell_3", "bell_5", "bell_7", "letter_0", "letter_6", "letter_2", "letter_3", "letter_5", "letter_7", "letter_conservatory_3", "letter_conservatory_5", "letter_conservatory_7", "trophy_waiting", "trophy_turning", "trophy_bell"]
	elif mode == "fall":
		shot_names = ["01_spawn", "02_edge", "03_underside", "04_fade_out", "05_bedside", "06_nearer_greenery"]
	elif mode == "trees":
		shot_names = ["01_spawn", "02_meadow", "03_tree_detail", "04_house_and_trees", "05_window_view", "06_north_window", "07_east_window", "08_south_window"]
	elif mode == "exterior":
		shot_names = ["01_spawn", "01_south_facade", "02_southwest_corner", "03_wall_close", "04_gap", "05_north_facade", "06_east_facade", "07_interior_window", "08_window_onto_neighbour", "09_red_door_inside", "10_red_door_outside"]
	elif mode == "furnishings":
		shot_names = ["01_spawn", "bedroom_north", "bedroom_bed", "bedroom_wardrobe", "bedroom_dresser", "bedroom_chair", "bedroom_slide", "bathroom_washstand", "bathroom_bench", "bathroom_toilet", "kitchen_bowl_detail", "dining_shelf_detail", "dining_serving_table", "trophy_case_left", "trophy_case_right"]
		for room_name in ["bathroom", "study", "kitchen", "living", "dining", "foyer", "laundry"]:
			for view in ["north", "south", "slide", "wall_art"]:
				shot_names.append(room_name + "_" + view)
	elif mode == "single-gap":
		shot_names = ["01_spawn", "02_outside", "02_gap_mid_shift", "02_gap_landed", "03_shifted"]
	elif mode == "ending":
		shot_names = ["00_front_locked", "01_spawn", "03_home_room", "05_chandelier", "06_bonus_door", "07_flowers", "07_belvedere", "07_credit", "07_credits_paused", "07_thanks", "07_results", "07_results_portrait", "08_title"]
		if OS.get_cmdline_user_args().has("--detail-only"):
			shot_names = ["00_front_locked", "01_spawn"]
		elif OS.get_cmdline_user_args().has("--ending-only"):
			shot_names = ["06_bonus_door", "07_flowers", "07_belvedere", "07_credit", "07_credits_paused", "07_thanks", "07_results", "07_results_portrait", "08_title"]
	for name_value in shot_names:
		DirAccess.remove_absolute(shots_dir.path_join(name_value + ".png"))
	DisplayServer.window_move_to_foreground()
	get_window().grab_focus()
	get_tree().create_timer(600 if mode == "ending" else 175).timeout.connect(func() -> void:
		printerr("FAIL: capture timed out at action %d, position %s, sliding %s" % [action_number, main.player.global_position, main.sliding])
		get_tree().quit(1))
	await get_tree().create_timer(0.6).timeout
	if mode == "title":
		var title_driver: Node = load("res://tools/title_driver.gd").new()
		add_child(title_driver)
		await title_driver.run(self)
		print("Title capture: %d screenshots; %d checks, %d failures" % [shot_count, checks, failures])
		get_tree().quit(1 if failures else 0)
		return
	if main.play_gate.visible:
		await shot("00_play_gate")
		await check_pointer_input()
	if not OS.get_cmdline_user_args().has("--ending-only"):
		await shot("01_spawn")
	if mode == "sleep":
		var gallery: Node = load("res://tools/sleep_driver.gd").new()
		add_child(gallery)
		await gallery.run(self)
		print("Sleep capture: %d screenshots; %d checks, %d failures" % [shot_count, checks, failures])
		get_tree().quit(1 if failures else 0)
		return
	if mode == "stopwatch":
		var gallery: Node = load("res://tools/stopwatch_driver.gd").new()
		add_child(gallery)
		await gallery.run(self)
		print("Stopwatch capture: %d screenshots; %d checks, %d failures" % [shot_count, checks, failures])
		get_tree().quit(1 if failures else 0)
		return
	if mode == "binoculars":
		var gallery: Node = load("res://tools/binocular_driver.gd").new()
		add_child(gallery)
		await gallery.run(self)
		print("Binocular capture: %d screenshots; %d checks, %d failures" % [shot_count, checks, failures])
		get_tree().quit(1 if failures else 0)
		return
	if mode == "safe":
		var gallery: Node = load("res://tools/safe_driver.gd").new()
		add_child(gallery)
		await gallery.run(self)
		print("Safe capture: %d screenshots; %d checks, %d failures" % [shot_count, checks, failures])
		get_tree().quit(1 if failures else 0)
		return
	if mode == "coins":
		var gallery: Node = load("res://tools/coin_driver.gd").new()
		add_child(gallery)
		await gallery.run(self)
		print("Coin capture: %d screenshots; %d checks, %d failures" % [shot_count, checks, failures])
		get_tree().quit(1 if failures else 0)
		return
	if mode == "bells":
		var gallery: Node = load("res://tools/bell_driver.gd").new()
		add_child(gallery)
		await gallery.run(self)
		print("Bell capture: %d screenshots; %d checks, %d failures" % [shot_count, checks, failures])
		get_tree().quit(1 if failures else 0)
		return
	if mode == "fall":
		var fall_test: Node = load("res://tools/fall_driver.gd").new()
		add_child(fall_test)
		await fall_test.run(self)
		print("Fall capture: %d screenshots; %d checks, %d failures" % [shot_count, checks, failures])
		get_tree().quit(1 if failures else 0)
		return
	if mode == "trees":
		var gallery: Node = load("res://tools/tree_driver.gd").new()
		add_child(gallery)
		await gallery.run(self)
		print("Tree capture: %d screenshots; %d checks, %d failures" % [shot_count, checks, failures])
		get_tree().quit(1 if failures else 0)
		return
	if mode == "exterior":
		var exterior: Node = load("res://tools/exterior_driver.gd").new()
		add_child(exterior)
		await exterior.run(self)
		print("Exterior capture: %d screenshots; %d checks, %d failures" % [shot_count, checks, failures])
		get_tree().quit(1 if failures else 0)
		return
	if mode == "furnishings":
		var gallery: Node = load("res://tools/furnishing_driver.gd").new()
		add_child(gallery)
		await gallery.run(self)
		print("Furnishing capture: %d screenshots; %d checks, %d failures; %.2fs" % [shot_count, checks, failures, elapsed()])
		get_tree().quit(1 if failures else 0)
		return
	if mode == "ending":
		await objective_views()
		print("Ending capture: %d screenshots; %d checks, %d failures; %d slides; %.2fs" % [shot_count, checks, failures, main.slides, elapsed()])
		get_tree().quit(1 if failures else 0)
		return
	if mode == "conservatory":
		var gallery: Node = load("res://tools/conservatory_driver.gd").new()
		add_child(gallery)
		await gallery.run(self)
		print("Conservatory capture: %d screenshots; %d checks, %d failures" % [shot_count, checks, failures])
		get_tree().quit(1 if failures else 0)
		return
	if mode == "single-gap":
		await single_gap_views()
		print("Single-gap capture: %d screenshots; %d checks, %d failures; %.2fs" % [shot_count, checks, failures, elapsed()])
		get_tree().quit(1 if failures else 0)
		return

func single_gap_views() -> void:
	await complete_opening_slide()
	for direction in walk_route(7):
		await walk_direction(direction)
	_check(main.rooms.size() == 8 and main.rules.board.count(-1) == 1, "eight rooms and one gap")
	await check_pointer_input()
	await walk_direction(ManorRules.E)
	await walk_to(Vector3(0, 0, 12))
	_check(main.rules.player == ManorRules.OUTSIDE, "gap still leads to lawn")
	main.player.aim_at(Vector3(0, 1.4, 0))
	await shot("02_outside")
	await walk_to(ManorGeometry.center(7))
	_check(main.rules.player == -1 and main.rules.slot() == 7, "return through single gap")
	await walk_direction(ManorRules.W)
	await approach_lever(main.rooms[7])
	main.player.aim_at(main.rooms[7].lever.global_position + Vector3.UP * 0.8)
	await hold_lever_input(ManorRules.E, true)
	var source := main.rooms[7].position
	var gap_camera := Camera3D.new()
	main.add_child(gap_camera)
	gap_camera.position = source + Vector3(-4, 9, 12)
	gap_camera.look_at(source + Vector3(3, 0, 0), Vector3.UP)
	release_lever_input(true)
	_check(main.sliding, "lever starts slide")
	gap_camera.make_current()
	await get_tree().create_timer(0.75).timeout
	await shot("02_gap_mid_shift")
	while main.sliding:
		await get_tree().process_frame
	await shot("02_gap_landed")
	main.player.camera.make_current()
	gap_camera.queue_free()
	_check(main.rules.slot() == 7 and main.rules.board.count(-1) == 1 and main.gap_floor.position.is_equal_approx(ManorGeometry.center(6) + Vector3.DOWN * 0.02), "slide preserves one gap")
	_check(not main.won and not main.carpet.visible, "ordinary slide does not trigger a win")
	main.player.aim_at(ManorGeometry.center(6) + Vector3.UP * 1.4)
	await shot("03_shifted")

func approach_lever(room: ManorRoom) -> void:
	var offset := main.player.global_position - room.global_position
	offset.y = 0
	if offset.length() < 0.2:
		offset = Vector3.BACK
	await walk_to(room.global_position + offset.normalized() * 1.25)

func walk_direction(direction: int, stop_for_guide: bool = false) -> void:
	var p := main.rules.slot()
	var q := ManorRules.neighbor(p, direction)
	_check(main.rules.can_walk(direction), "doorway is legal")
	var from := ManorGeometry.center(p)
	var toward: Vector3 = ManorGeometry.DIRECTIONS[direction]
	# Approach the door on its centerline without cutting through the lever.
	await walk_to(from + toward * 1.35)
	await walk_to(ManorGeometry.center(q) - toward * 1.35, stop_for_guide)

func walk_to(target: Vector3, stop_for_guide: bool = false) -> void:
	var started := Time.get_ticks_msec()
	while true:
		if main.first_home_guide != null and main.first_home_guide.active:
			main.player.bot_drive = Vector3.ZERO
			if stop_for_guide:
				return
			press_if_reward_ready()
			await get_tree().physics_frame
			continue
		if rewards_waiting():
			# Presented rewards hold the player until accepted.
			main.player.bot_drive = Vector3.ZERO
			press_if_reward_ready()
			await get_tree().physics_frame
			continue
		var offset := target - main.player.global_position
		offset.y = 0
		if offset.length() < 0.12:
			break
		# Go around the small pedestal if the straight segment crosses it.
		var steering := target
		if main.rules.player >= 0:
			var center := ManorGeometry.center(main.rules.slot())
			var relative := main.player.global_position - center
			relative.y = 0
			var projected := clampf(-relative.dot(offset.normalized()), 0.0, offset.length())
			if (relative + offset.normalized() * projected).length() < 0.68:
				var tangent := Vector3(-offset.z, 0, offset.x).normalized()
				if relative.dot(tangent) < 0:
					tangent = -tangent
				# Dining's central table leaves the east side as the lever bypass.
				if main.rules.player == 6:
					tangent = Vector3.RIGHT
				steering = center + tangent * 0.95
		var drive := steering - main.player.global_position
		drive.y = 0
		main.player.bot_drive = drive.normalized() * minf(1.0, drive.length() * 8.0)
		main.player.aim_at(steering + Vector3.UP * 1.4)
		if Time.get_ticks_msec() - started > 12000:
			_check(false, "physical walking timed out: %s -> %s" % [main.player.global_position, target])
			get_tree().quit(1)
			return
		await get_tree().physics_frame
	main.player.bot_drive = Vector3.ZERO
	main.player.velocity = Vector3.ZERO
	await get_tree().physics_frame

func walk_route(target_room: int) -> Array[int]:
	var queue: Array[ManorRules] = [main.rules.copy()]
	var routes: Array = [[]]
	var seen: Array[int] = [main.rules.player]
	while not queue.is_empty():
		var state: ManorRules = queue.pop_front()
		var path: Array = routes.pop_front()
		if state.player == target_room:
			var result: Array[int] = []
			result.assign(path)
			return result
		for d in 4:
			if state.can_walk(d):
				var next := state.copy()
				next.apply(ManorRules.WALK, d)
				if not seen.has(next.player):
					seen.append(next.player)
					queue.append(next)
					routes.append(path + [d])
	_check(false, "walk route to Foyer exists")
	return []

func shot(label: String) -> void:
	await get_tree().process_frame
	# An occluded native window may stop redrawing while the player uses another game window.
	RenderingServer.force_draw(false)
	var output := shots_dir.path_join(label + ".png")
	var error := get_viewport().get_texture().get_image().save_png(output)
	_check(error == OK, "screenshot saved")
	shot_count += 1
	print("Screenshot: ", output)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL at action %d (%.2fs): %s" % [action_number, elapsed(), message])
		get_tree().quit(1)

func elapsed() -> float:
	return (Time.get_ticks_msec() - started) / 1000.0

func key_event(key: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = pressed
	Input.parse_input_event(event)

# Presented coins and binoculars wait in view until a fresh press.
func accept_rewards() -> void:
	while rewards_waiting():
		press_if_reward_ready()
		await get_tree().process_frame

func rewards_waiting() -> bool:
	return (main.coins != null and not main.coins.pending.is_empty()) or (main.binoculars != null and main.binoculars.presenting)

func press_if_reward_ready() -> void:
	var coin_ready := main.coin_hud.showing() and not main.coin_hud.accepted and main.coin_hud.presentation >= ManorCoinHUD.HOLD_AT
	var binoculars_ready := main.binoculars.presenting and not main.binoculars.reward_accepted and main.binoculars.reward_elapsed >= ManorBinoculars.REWARD_HOLD_AT
	if coin_ready or binoculars_ready:
		key_event(KEY_SPACE, true)
		key_event(KEY_SPACE, false)

func mouse_button(pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = main.play_gate.primary.get_global_rect().get_center() if main.play_gate.visible else get_viewport().get_visible_rect().size / 2.0
	Input.parse_input_event(event)

func hover_button(button: Button, label: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var event := InputEventMouseMotion.new()
	event.position = button.get_global_rect().get_center()
	event.global_position = event.position
	Input.parse_input_event(event)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(button.is_hovered(), "%s responds to pointer hover" % label)
	await shot(label)
	event = InputEventMouseMotion.new()
	event.position = Vector2(4, 4)
	event.global_position = event.position
	Input.parse_input_event(event)
	await get_tree().process_frame
	_check(not button.is_hovered(), "%s clears hover when pointer leaves" % label)

func mouse_motion(delta: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.relative = delta
	event.screen_relative = delta
	Input.parse_input_event(event)

func check_pointer_input() -> void:
	main.player.automated = false
	if main.play_gate.visible:
		_check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "gesture gate starts with pointer visible")
		mouse_button(true)
		mouse_button(false)
		await get_tree().process_frame
		while main.play_gate.starting:
			await get_tree().process_frame
	_check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "play starts with pointer captured")
	var yaw := main.player.rotation.y
	var pitch := main.player.camera.rotation.x
	mouse_motion(Vector2(12, 0))
	await get_tree().process_frame
	_check(not is_equal_approx(yaw, main.player.rotation.y), "real mouse motion changes yaw")
	key_event(KEY_ESCAPE, true)
	key_event(KEY_ESCAPE, false)
	await get_tree().process_frame
	_check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and main.play_gate.visible, "Escape releases pointer and shows play icon")
	main.player.aim_at(main.rooms[main.rules.player].lever.global_position + Vector3.UP * 0.8)
	key_event(KEY_E, true)
	key_event(KEY_E, false)
	await get_tree().process_frame
	_check(not main.player.held, "interact cannot bypass play gate")
	mouse_button(true)
	mouse_button(false)
	await get_tree().process_frame
	_check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not main.play_gate.visible, "play gesture recaptures pointer")
	main.player.rotation.y = yaw
	main.player.camera.rotation.x = pitch
	main.player.automated = true

func hold_lever_input(direction: int, keyboard: bool) -> void:
	main.player.automated = false
	if keyboard:
		key_event(KEY_E, true)
	else:
		mouse_button(true)
	await get_tree().process_frame
	_check(main.player.held, "real interact press holds lever")
	var local_direction: Vector3 = main.player.global_basis.inverse() * ManorGeometry.DIRECTIONS[direction]
	var delta := Vector2(local_direction.x, local_direction.z)
	if keyboard:
		var key: Key = KEY_D if delta.x > 0 else KEY_A
		if absf(delta.y) > absf(delta.x):
			key = KEY_S if delta.y > 0 else KEY_W
		key_event(key, true)
		await get_tree().physics_frame
		await get_tree().physics_frame
		key_event(key, false)
	else:
		mouse_motion(delta * 60.0)
		await get_tree().process_frame
	_check(main.player.selected_direction == direction, "camera-relative input selects correct world direction")

func release_lever_input(keyboard: bool) -> void:
	if keyboard:
		key_event(KEY_E, false)
	else:
		mouse_button(false)
	main.player.automated = true

func objective_views() -> void:
	if OS.get_cmdline_user_args().has("--ending-only"):
		# Visual fixture for ending framing; the full capture separately proves both solves.
		main.rules.board = PackedInt32Array(ManorRules.HOME)
		main.rules.player = 7
		for id in main.rooms:
			main.rooms[id].position = ManorGeometry.center(id)
		main.gap_floor.position = ManorGeometry.center(4) + Vector3.DOWN * 0.02
		main.player.position = ManorGeometry.center(7) + Vector3(0, 0.02, 1.5)
		main.refresh_progress()
		while not main.coins.pending.is_empty():
			main.coins.receive_next()
		main.run_stats.shifts = 31
		main.run_stats.sleeps = 3
		main.run_stats.falls = 1
		main.run_stats.elapsed_seconds = 1542.0
		main.resume_play()
		await get_tree().create_timer(0.6).timeout
		await collect_red_key()
		for direction in walk_route(7):
			await walk_direction(direction)
		await walk_to(main.rooms[7].position + Vector3(0, 0, 1.5))
		await capture_exit()
		return
	await check_pointer_input()
	main.player.aim_at(main.rooms[7].global_position + Vector3(0, 1.7, 3.0))
	await shot("00_front_locked")
	if OS.get_cmdline_user_args().has("--detail-only"):
		return
	await complete_opening_slide()
	main.player.aim_at(main.rooms[8].global_position + Vector3.UP * 2.25)
	await shot("03_home_room")
	var solver := ManorSolver.new()
	solver.build()
	var search_state := ManorRules.new(main.rules.board, main.rules.player)
	var path := solver.solution(search_state, true)
	print("Assembly: %d actions; t=%.2fs" % [path.size(), elapsed()])
	for action in path:
		await objective_action(action)
	_check(main.won, "the solver's route assembles the house")
	await collect_red_key()
	for direction in walk_route(7):
		await walk_direction(direction)
	main.player.aim_at(main.rooms[7].global_position + Vector3.UP * 2.4)
	await shot("05_chandelier")
	await walk_to(main.rooms[7].global_position + Vector3(0, 0, 1.5))
	await capture_exit()

func capture_exit() -> void:
	await unlock_red_door()
	main.player.aim_at(Vector3(0, 1.7, 18))
	await shot("06_bonus_door")
	main.player.bot_drive = Vector3.BACK
	while not main.in_finale:
		await get_tree().physics_frame
	main.player.bot_drive = Vector3.ZERO
	await get_tree().create_timer(4.5).timeout
	_check(main.ending.total_spawned > 5, "flowers keep sprouting near player during exit")
	await shot("07_flowers")
	await get_tree().create_timer(ManorEnding.WALK_SECONDS - 7.5).timeout
	await shot("07_belvedere")
	await get_tree().create_timer(5.0).timeout
	await shot("07_credit")
	main.player.automated = false
	key_event(KEY_ESCAPE, true)
	await get_tree().process_frame
	key_event(KEY_ESCAPE, false)
	main.player.automated = true
	_check(main.play_gate.visible and main.play_gate.mode == "pause", "Escape pauses the ending")
	var paused_alpha := main.ending.credit.modulate.a
	var paused_flowers := main.ending.total_spawned
	await get_tree().create_timer(0.3).timeout
	_check(main.ending.credit.modulate.a == paused_alpha and main.ending.total_spawned == paused_flowers, "paused ending freezes credits and flower spawns")
	await shot("07_credits_paused")
	mouse_button(true)
	mouse_button(false)
	await get_tree().process_frame
	_check(not main.play_gate.visible, "Resume continues the ending")
	await get_tree().create_timer(10.0).timeout
	await shot("07_thanks")
	while not main.run_summary.ready_to_continue:
		await get_tree().process_frame
	await shot("07_results")
	var content_size := get_window().content_scale_size
	var window_size := get_window().size
	get_window().content_scale_size = Vector2i(360, 640)
	get_window().size = Vector2i(360, 640)
	await get_tree().process_frame
	await shot("07_results_portrait")
	get_window().content_scale_size = content_size
	get_window().size = window_size
	await get_tree().process_frame
	_check(not main.at_title, "outdoor ending waits for a fresh key")
	key_event(KEY_SPACE, true)
	key_event(KEY_SPACE, false)
	while not main.at_title:
		await get_tree().process_frame
	_check(main.play_gate.visible and main.play_gate.mode == "title", "outdoor ending returns to title")
	await shot("08_title")

func complete_opening_slide() -> void:
	if main.rules.board != ManorRules.opening_start().board:
		return
	# From the opening rooms, sliding the Laundry home is the only legal shift.
	for direction in walk_route(8):
		await objective_action(Vector2i(ManorRules.WALK, direction))
	await objective_action(Vector2i(ManorRules.SLIDE, ManorRules.E))
	while main.first_home_guide.active or rewards_waiting():
		press_if_reward_ready()
		await get_tree().process_frame

func objective_action(action: Vector2i, stop_for_guide: bool = false) -> void:
	action_number += 1
	print("Action %d %s %s | t=%.2fs room=%d" % [action_number, "walk" if action.x == ManorRules.WALK else "slide", ["N", "E", "S", "W"][action.y], elapsed(), main.rules.player])
	var expected := main.rules.copy()
	_check(expected.apply(action.x, action.y), "objective action is legal")
	if action.x == ManorRules.WALK:
		await walk_direction(action.y, stop_for_guide)
	else:
		await approach_lever(main.rooms[main.rules.player])
		main.player.aim_at(main.rooms[main.rules.player].lever.global_position + Vector3.UP * 0.8)
		await get_tree().physics_frame
		if DisplayServer.get_name() == "headless":
			# The headless display cannot capture the pointer for native input events.
			_check(main.player.begin_interact(), "interaction ray reaches objective lever")
			main.player.select_pull(action.y)
			main.player.release_interact()
		else:
			var keyboard := main.slides % 2 == 0
			await hold_lever_input(action.y, keyboard)
			release_lever_input(keyboard)
		_check(main.sliding, "input starts objective slide")
		while main.sliding:
			await get_tree().process_frame
	_check(main.rules.key() == expected.key(), "physical action matches pure rules")

func collect_room_coin(id: int, capture: bool = false, reward_shot: String = "") -> void:
	var drawer := main.coin_drawers[id]
	if main.coins.collected.has(id):
		return
	while main.first_home_guide.active:
		await get_tree().process_frame
	await walk_to(main.rooms[id].position + Vector3(0, 0, 1.2))
	var approach := drawer.to_global(Vector3(0, 0, drawer.travel + 0.85))
	approach.y = 0.02
	await walk_to(approach)
	if not drawer.opened:
		main.player.aim_at(drawer.front_hit.global_position)
		await get_tree().physics_frame
		_check(main.player.begin_interact() and drawer.opened, "room %d drawer opens when tried at home" % id)
	while drawer.opening < ManorCoinDrawer.OPEN_TIME:
		await get_tree().process_frame
	main.player.aim_at(drawer.coin.global_position)
	await get_tree().physics_frame
	if capture:
		await shot("drawer_%d_open" % id)
	_check(main.player.begin_interact(), "room %d drawer coin is physically reachable" % id)
	_check(main.coins.pending == [id], "drawer pickup starts one coin presentation")
	if capture or not reward_shot.is_empty():
		await get_tree().create_timer(0.5).timeout
		await shot("coin_presented" if reward_shot.is_empty() else reward_shot)
	await accept_rewards()
	if capture:
		await shot("drawer_%d_empty" % id)
	await walk_to(main.rooms[id].position + Vector3(0, 0, 1.2))

func collect_red_key(capture: bool = false) -> void:
	await accept_rewards()
	var c := main.conservatory
	if c.key_owned:
		return
	if c.revealing():
		var room := main.rooms[main.rules.player]
		var inward := -room.position.normalized()
		await walk_to(room.position + inward * 1.85)
		main.player.aim_at(Vector3(0, 1.4, 0))
		while c.phase == ManorConservatory.Phase.WAITING:
			await get_tree().process_frame
		if capture:
			while c.elapsed < ManorConservatory.CLOSE_TIME + 0.4:
				await get_tree().process_frame
			await check_motion_audio(c)
			await shot("conservatory_retracting")
		while c.phase == ManorConservatory.Phase.RETRACTING:
			await get_tree().process_frame
		if capture:
			main.player.aim_at(Vector3(0, -2.5, 0))
			await shot("conservatory_shaft")
			main.player.aim_at(Vector3(0, 1.4, 0))
			await check_motion_audio(c)
		await get_tree().create_timer(3.4).timeout
		if capture:
			await shot("conservatory_rising")
		while not c.accessible():
			await get_tree().process_frame
		await get_tree().create_timer(0.55).timeout
		if capture:
			await shot("conservatory_docked")
	# Enter from whichever of the four adjacent rooms performed the final slide.
	var from := main.rules.slot()
	var inward := -ManorGeometry.center(from).normalized()
	await walk_to(ManorGeometry.center(from) + inward * 2.0)
	await walk_to(-inward * 2.45)
	# The central tree and pedestal leave a generous aisle around the east side.
	if from == 1:
		await walk_to(Vector3(0.85, 0, -2.45))
		await walk_to(Vector3(0.85, 0, 2.35))
	elif from in [3, 5]:
		await walk_to(Vector3(-2.45 if from == 3 else 2.45, 0, 0.4))
		await walk_to(Vector3(0.85, 0, 0.4))
		await walk_to(Vector3(0.85, 0, 2.35))
	await walk_to(Vector3(0, 0, 2.35))
	main.player.aim_at(Vector3(0, 1.75, -0.4))
	if capture:
		await shot("conservatory_interior")
		main.player.aim_at(Vector3(0, 4.0, -0.7))
		await shot("conservatory_roof")
	main.player.aim_at(c.room.key.global_position)
	await get_tree().physics_frame
	if capture:
		await shot("red_key_pedestal")
	_check(main.player.begin_interact(), "interaction ray picks up pedestal key")
	while c.collecting and c.pickup_elapsed < ManorConservatory.REWARD_HOLD_AT:
		await get_tree().process_frame
	if capture:
		await shot("red_key_reward")
	key_event(KEY_SPACE, true)
	key_event(KEY_SPACE, false)
	while c.collecting:
		await get_tree().process_frame
	_check(c.key_owned, "red key reaches inventory")
	if capture:
		await shot("red_key_inventory")
		await walk_to(Vector3(-0.95, 0, 2.35))
		main.player.aim_at(Vector3(1.8, 0.65, 1.8))
		await shot("conservatory_seating")
		await walk_to(Vector3(-1.35, 0, 0.35))
		main.player.aim_at(Vector3(-1.8, 0.9, -2.65))
		await shot("conservatory_planting")
		await walk_to(Vector3(-0.95, 0, 2.35))
		await walk_to(Vector3(0, 0, 2.35))
	await walk_to(Vector3(0, 0, 4.8))

func check_motion_audio(c: ManorConservatory) -> void:
	var voice := c.motion_sound
	_check(is_instance_valid(voice) and voice.playing and is_equal_approx(voice.pitch_scale, 1.0), "reveal audio plays at the motion's exact timing")
	if not is_instance_valid(voice):
		return
	main.release_pointer()
	await get_tree().process_frame
	await get_tree().process_frame
	var elapsed_before := c.elapsed
	await get_tree().create_timer(0.15).timeout
	_check(voice.stream_paused and c.elapsed == elapsed_before, "pause holds both reveal sound and movement")
	main.resume_play()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(not voice.stream_paused, "reveal audio resumes with movement")

func unlock_red_door(capture: bool = false) -> void:
	var front: ManorDoor
	for door in main.rooms[7].doors:
		if door.is_front:
			front = door
	await walk_to(main.rooms[7].position + Vector3(0, 0, 1.75))
	main.player.aim_at(front.gate.global_position)
	await get_tree().physics_frame
	if capture:
		await shot("red_door_keyhole")
	_check(main.player.begin_interact(), "key unlocks red door through normal interaction")
	if capture:
		while main.conservatory.unlock_elapsed < 0.7:
			await get_tree().process_frame
		await shot("red_key_unlocking")
	while front.gate.collision_layer != 0:
		await get_tree().process_frame
