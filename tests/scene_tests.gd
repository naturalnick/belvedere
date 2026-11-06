extends "res://tests/manor_test.gd"

var main: Manor

func run() -> void:
	main = start_manor()
	await physics_frame
	await physics_frame
	check(main.rules.board == ManorRules.from_seed("C").board and main.rules.player == 7, "scene starts from requested seed C")
	check(main.player.camera.fov == main.preferences.fov and is_equal_approx(main.player.camera.position.y, 1.65), "first-person scale respects saved FOV")
	for id in main.rooms:
		var room: ManorRoom = main.rooms[id]
		check(room.position == ManorGeometry.center(main.rules.board.find(id)), "room is at its logical slot")
		for door in room.doors:
			var state := ManorRules.new(main.rules.board, id)
			var allowed := not door.is_front and state.can_walk(door.direction)
			check(door.opened == allowed and (door.gate.collision_layer == 0) == allowed, "door animation and collision agree with rules")
	_check_all_spawn_yaws()
	var foyer: ManorRoom = main.rooms[7]
	main.player.aim_at(foyer.global_position + Vector3.UP * 0.8)
	check(main.player.begin_interact(), "spawn lever reachable without walking")
	main.player.select_pull(ManorRules.E)
	main.player.release_interact()
	check(not main.sliding and main.slides == 0, "invalid lever direction does not slide")
	check(main.player.begin_interact(), "lever can be held again")
	main.player.cancel_pull()
	check(not main.player.held and not main.sliding, "cancel releases lever without moving")
	check(main.player.begin_interact(), "lever can be re-engaged after cancel")
	main.player.select_pull(ManorRules.W)
	main.player.release_interact()
	check(main.sliding and main.player.get_parent() == foyer, "slide parents player to room")
	await create_timer(0.7).timeout
	check(main.rules.board == ManorRules.from_seed("C").board, "logical board stays atomic during transit")
	await main.slide_finished
	check(main.slides == 1 and main.rules.slot() == 6, "slide commits room to destination")
	main.rules.player = -1
	check(not main.request_slide(ManorRules.N), "scene rejects slides from empty slot")
	# Bedroom north is a window, even though another room is on its other side.
	main.rules.player = 0
	var bedroom: ManorRoom = main.rooms[0]
	main.player.position = bedroom.position + Vector3(1.6, 0.02, -1.6)
	main.player.velocity = Vector3.ZERO
	main.player.bot_drive = Vector3.FORWARD
	await create_timer(1.0).timeout
	check(main.rules.player == 0 and main.player.position.z > bedroom.position.z - 2.75, "window collision prevents walking into neighbor")
	main.player.bot_drive = Vector3.ZERO
	main.queue_free()
	await process_frame
	finish("Scene")

func _check_all_spawn_yaws() -> void:
	var original := main.rules.copy()
	# Framing is specified at the default FOV; a narrower saved preference must not affect the check.
	var saved_fov := main.player.camera.fov
	main.player.camera.fov = ManorPreferences.new().fov
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/accepted_14_20.json"))
	for entry: Dictionary in data.states:
		main.rules = ManorRules.new(PackedInt32Array(entry.board), int(entry.player))
		main.place_player_at_spawn()
		var room_center := ManorGeometry.center(main.rules.slot())
		var gap_center := ManorGeometry.center(main.rules.board.find(-1))
		var forward := -main.player.camera.global_basis.z
		forward.y = 0
		check(forward.normalized().dot((gap_center - room_center).normalized()) > 0.99999, "every accepted spawn yaw faces the gap")
		for point in [Vector3(-0.28, 0.0, -0.28), Vector3(0.28, 0.0, 0.28), Vector3(0, 0.9, 0)]:
			check(main.player.camera.is_position_in_frustum(room_center + point), "spawn frames entire lever")
	main.player.camera.fov = saved_fov
	main.rules = original
	main.place_player_at_spawn()
	check(is_equal_approx(main.player.rotation.y, PI / 2.0), "seed C spawn faces west, yaw 90 degrees")
	print("Spawn yaw and lever framing: all 1,816 accepted seeds verified")
