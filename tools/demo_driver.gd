extends Node

var main: Manor
var shots_dir := ""
var checks := 0
var failures := 0
var shot_count := 0

func run(game: Manor) -> void:
	main = game
	shots_dir = ProjectSettings.globalize_path("res://screenshots/stage1")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			shots_dir = arg.trim_prefix("--shots=")
		if arg.begins_with("--mode=") and arg != "--mode=solve":
			printerr("Only Stage 1 capture mode 'solve' is available")
			get_tree().quit(1)
			return
	DirAccess.make_dir_recursive_absolute(shots_dir)
	DisplayServer.window_move_to_foreground()
	get_window().grab_focus()
	get_tree().create_timer(420).timeout.connect(func() -> void:
		printerr("FAIL: solve capture timed out")
		get_tree().quit(1))
	await get_tree().create_timer(0.6).timeout
	await shot("01_spawn")
	var room: ManorRoom = main.rooms[main.rules.player]
	var solver := ManorSolver.new()
	solver.build()
	var path := solver.solution(main.rules)
	var expected := solver.distance[main.rules.key()]
	print("Capture seed %s: %d actions, %d optimal slides" % [main.seed_name, path.size(), expected])
	var first_slide := true
	var window_captured := false
	for action in path:
		var expected_state := main.rules.copy()
		_check(expected_state.apply(action.x, action.y), "solver action is legal before physical execution")
		if action.x == ManorRules.WALK:
			await walk_direction(action.y)
		else:
			room = main.rooms[main.rules.player]
			await approach_lever(room)
			main.player.aim_at(room.lever.global_position + Vector3.UP * 0.8)
			await get_tree().physics_frame
			_check(main.player.begin_interact(), "raycast reaches the room lever")
			main.player.select_pull(action.y)
			await get_tree().create_timer(0.18).timeout
			if first_slide:
				await shot("03_lever_held")
			var rider_local := room.to_local(main.player.global_position)
			main.player.release_interact()
			_check(main.sliding, "lever release starts slide")
			_check(not main.request_slide(action.y), "input is locked during slide")
			if first_slide:
				main.player.aim_at(room.global_position + ManorGeometry.DIRECTIONS[action.y] * 4.0 + Vector3.UP * 1.3)
				await get_tree().create_timer(0.7).timeout
				_check(room.to_local(main.player.global_position).distance_to(rider_local) < 0.001, "player rides room at mid-slide")
				await shot("04_mid_slide")
			await main.slide_finished
			_check(room.to_local(main.player.global_position).distance_to(rider_local) < 0.001, "player stays in room on landing")
			await get_tree().create_timer(0.5).timeout
			first_slide = false
		_check(main.rules.key() == expected_state.key(), "physical action matches solver state")
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
	print("Capture: %d screenshots; %d checks, %d failures; %d slides" % [shot_count, checks, failures, main.slides])
	get_tree().quit(1 if failures else 0)


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
		if offset.length() < 0.07:
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
		main.player.bot_drive = drive.normalized() * minf(1.0, drive.length() * 4.0)
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
		printerr("FAIL: ", message)
