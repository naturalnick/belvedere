extends Node

var main: Manor
var shots_dir := ""
var checks := 0
var failures := 0
var shot_count := 0
var started := 0
var action_number := 0
var mode := "solve"

func run(game: Manor) -> void:
	main = game
	shots_dir = ProjectSettings.globalize_path("res://screenshots/stage1")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			shots_dir = arg.trim_prefix("--shots=")
		if arg.begins_with("--mode="):
			mode = arg.trim_prefix("--mode=")
	if mode not in ["solve", "review", "courtyard"]:
		printerr("Capture mode must be solve, review or courtyard")
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute(shots_dir)
	started = Time.get_ticks_msec()
	# Remove this mode's outputs so stale success frames cannot survive a failed run.
	var shot_names := ["01_spawn", "02_window", "03_lever_held", "04_mid_slide", "05_solved", "06_front_door_open"]
	if mode == "courtyard":
		shot_names = ["01_spawn", "02_courtyards", "03_outside", "04_lever_held", "05_mid_slide", "06_multiple_directions", "07_shifted"]
	for name_value in shot_names:
		DirAccess.remove_absolute(shots_dir.path_join(name_value + ".png"))
	DisplayServer.window_move_to_foreground()
	get_window().grab_focus()
	get_tree().create_timer(175).timeout.connect(func() -> void:
		printerr("FAIL: capture timed out at action %d, position %s, sliding %s" % [action_number, main.player.global_position, main.sliding])
		get_tree().quit(1))
	await get_tree().create_timer(0.6).timeout
	if main.play_gate.visible:
		await shot("00_play_gate")
		await check_pointer_input()
	await shot("01_spawn")
	if mode == "courtyard":
		await courtyard_views()
		print("Courtyard capture: %d screenshots; %d checks, %d failures; %.2fs" % [shot_count, checks, failures, elapsed()])
		get_tree().quit(1 if failures else 0)
		return
	print("Spawn room %d slot %d, gap slot %d, yaw %.1f°" % [main.rules.player, main.rules.slot(), main.rules.board.find(-1), rad_to_deg(main.player.rotation.y)])
	if mode == "review":
		await review_views()
		get_tree().quit(1 if failures else 0)
		return
	await check_pointer_input()
	var room: ManorRoom = main.rooms[main.rules.player]
	var solver := ManorSolver.new()
	solver.build()
	var path := solver.solution(main.rules, true)
	var expected := solver.distance[main.rules.key()]
	print("Capture seed %s: %d actions, %d optimal slides" % [main.seed_name, path.size(), expected])
	var first_slide := true
	var window_captured := false
	for action in path:
		action_number += 1
		var action_started := Time.get_ticks_msec()
		print("Action %d/%d %s %s | t=%.2fs room=%d slot=%d" % [action_number, path.size(), "walk" if action.x == ManorRules.WALK else "slide", ["N", "E", "S", "W"][action.y], elapsed(), main.rules.player, main.rules.slot()])
		var expected_state := main.rules.copy()
		_check(expected_state.apply(action.x, action.y), "solver action is legal before physical execution")
		if action.x == ManorRules.WALK:
			await walk_direction(action.y)
		else:
			room = main.rooms[main.rules.player]
			await approach_lever(room)
			main.player.aim_at(room.lever.global_position + Vector3.UP * 0.8)
			await get_tree().physics_frame
			await hold_lever_input(action.y, main.slides % 2 == 0)
			await get_tree().create_timer(0.18).timeout
			if first_slide:
				await shot("03_lever_held")
			var rider_local := room.to_local(main.player.global_position)
			release_lever_input(main.slides % 2 == 0)
			_check(main.sliding, "lever release starts slide")
			_check(not main.request_slide(action.y), "input is locked during slide")
			if first_slide:
				main.player.aim_at(room.global_position + ManorGeometry.DIRECTIONS[action.y] * 4.0 + Vector3.UP * 1.3)
				await get_tree().create_timer(0.7).timeout
				_check(room.to_local(main.player.global_position).distance_to(rider_local) < 0.001, "player rides room at mid-slide")
				await shot("04_mid_slide")
				if OS.get_cmdline_user_args().has("--stall-mid-slide"):
					await get_tree().create_timer(1.0).timeout
					_check(not main.sliding, "forced late screenshot wait outlives slide signal")
			# A screenshot or slow frame can outlive the tween and its one-shot signal.
			while main.sliding:
				await get_tree().process_frame
			_check(room.to_local(main.player.global_position).distance_to(rider_local) < 0.001, "player stays in room on landing")
			await get_tree().create_timer(0.45).timeout
			first_slide = false
		_check(main.rules.key() == expected_state.key(), "physical action matches solver state")
		print("  complete in %.2fs, slides=%d" % [(Time.get_ticks_msec() - action_started) / 1000.0, main.slides])
		if not window_captured and main.rules.player >= 0:
			window_captured = await capture_window()
	_check(main.won and main.rules.solved(), "physical solve reaches home")
	_check(main.slides == expected, "capture used optimal slide count")
	main.player.aim_at(ManorGeometry.center(4) + Vector3.UP * 1.4)
	await shot("05_solved")
	# Finish by physically walking to the Foyer, then onto the lawn.
	var route := walk_route(7)
	for direction in route:
		await walk_direction(direction)
	var foyer: ManorRoom = main.rooms[7]
	for door in foyer.doors:
		if door.is_front:
			_check(door.opened and door.gate.collision_layer == 0, "front door unlocks after solve")
	await walk_to(foyer.global_position + Vector3(0, 0, 1.5))
	main.player.aim_at(Vector3(0, 1.4, 22))
	await shot("06_front_door_open")
	await walk_to(Vector3(0, 0, 11))
	_check(main.player.global_position.z > 9.5, "unlocked front door can be walked through")
	print("Capture: %d screenshots; %d checks, %d failures; %d slides; %.2fs" % [shot_count, checks, failures, main.slides, elapsed()])
	get_tree().quit(1 if failures else 0)

func courtyard_views() -> void:
	_check(main.rules.courtyards and main.rooms.size() == 6 and main.gap_floors.size() == 3, "six-room courtyard scene")
	await check_pointer_input()
	await walk_direction(ManorRules.E)
	await walk_direction(ManorRules.E)
	_check(main.rules.player == -1 and main.rules.slot() == 8, "walk across two distinct gaps")
	main.player.aim_at(Vector3(-3, 1.4, 0))
	await shot("02_courtyards")
	await walk_to(Vector3(6.25, 0, 11))
	_check(main.rules.player == ManorRules.OUTSIDE, "walk from edge gap onto lawn")
	_check(not main.request_slide(ManorRules.N), "cannot slide from lawn")
	await walk_to(Vector3(11, 0, 11))
	main.player.aim_at(Vector3(0, 1.4, 0))
	await shot("03_outside")
	await walk_to(Vector3(6.25, 0, 11))
	await walk_to(ManorGeometry.center(8))
	_check(main.rules.player == -1 and main.rules.slot() == 8, "return from lawn onto courtyard floor")
	await walk_direction(ManorRules.W)
	await walk_direction(ManorRules.W)
	_check(main.rules.player == 7, "return through doorway to Foyer")
	await approach_lever(main.rooms[7])
	main.player.aim_at(main.rooms[7].lever.global_position + Vector3.UP * 0.8)
	await hold_lever_input(ManorRules.E, true)
	await shot("04_lever_held")
	var local := main.rooms[7].to_local(main.player.global_position)
	release_lever_input(true)
	await get_tree().create_timer(0.7).timeout
	_check(main.sliding, "input starts courtyard slide")
	_check(main.rooms[7].to_local(main.player.global_position).distance_to(local) < 0.001, "rider stays on moving room")
	await shot("05_mid_slide")
	while main.sliding:
		await get_tree().process_frame
	_check(main.rules.slot() == 7 and main.gap_floors.has(6) and not main.gap_floors.has(7), "selected gap is filled and old slot becomes a gap")
	await get_tree().create_timer(0.5).timeout
	main.player.aim_at(main.rooms[7].lever.global_position + Vector3.UP * 0.8)
	await hold_lever_input(ManorRules.E, false)
	_check(main.rules.can_slide(ManorRules.E) and main.rules.can_slide(ManorRules.W), "two lever choices available")
	await shot("06_multiple_directions")
	release_lever_input(false)
	while main.sliding:
		await get_tree().process_frame
	_check(main.rules.slot() == 8 and main.rules.board[8] == 7, "second slide chooses east, not first gap in board")
	_check(not main.won and not main.carpet.visible, "prototype has no solve reward")
	for door in main.rooms[7].doors:
		if door.is_front or ManorRules.neighbor(8, door.direction) < 0:
			_check(not door.opened and door.gate.collision_layer == 1, "exterior doors stay closed")
	main.player.aim_at(Vector3(0, 1.4, 0))
	await shot("07_shifted")


func capture_window() -> bool:
	var room: ManorRoom = main.rooms[main.rules.player]
	for d in 4:
		if ManorRules.side(room.room_id, d) != ManorRules.WINDOW:
			continue
		var side: Vector3 = ManorGeometry.DIRECTIONS[d]
		var tangent: Vector3 = ManorGeometry.DIRECTIONS[(d + 1) % 4] * 1.6
		await walk_to(room.global_position + tangent + side * 1.9)
		main.player.aim_at(room.global_position + tangent + side * 3.125 + Vector3.UP * 1.65)
		await shot("02_window")
		return true
	return false

func approach_lever(room: ManorRoom) -> void:
	var offset := main.player.global_position - room.global_position
	offset.y = 0
	if offset.length() < 0.2:
		offset = Vector3.BACK
	await walk_to(room.global_position + offset.normalized() * 1.25)

func walk_direction(direction: int) -> void:
	var p := main.rules.slot()
	var q := ManorRules.neighbor(p, direction)
	_check(main.rules.can_walk(direction), "doorway is legal")
	var from := ManorGeometry.center(p)
	var toward: Vector3 = ManorGeometry.DIRECTIONS[direction]
	# Approach the door on its centerline without cutting through the lever.
	await walk_to(from + toward * 1.35)
	await walk_to(ManorGeometry.center(q) - toward * 1.35)

func walk_to(target: Vector3) -> void:
	var started := Time.get_ticks_msec()
	while true:
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
	await RenderingServer.frame_post_draw
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

func mouse_button(pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = get_viewport().get_visible_rect().size / 2.0
	Input.parse_input_event(event)

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

func review_views() -> void:
	main.rules = ManorRules.new()
	main.won = true
	for id in main.rooms:
		main.rooms[id].position = ManorGeometry.center(id)
	main.gap_floor.position = ManorGeometry.center(4) + Vector3.DOWN * 0.02
	main.refresh_doors(true)
	main.carpet.visible = true
	main.player.position = ManorGeometry.center(7) + Vector3(0, 0, 1.5)
	main.player.aim_at(Vector3(0, 1.4, 22))
	await get_tree().create_timer(0.4).timeout
	await shot("06_front_door_open")
	main.rules.player = 0
	main.player.position = ManorGeometry.center(0) + Vector3(1.6, 0, 0)
	await capture_window()
