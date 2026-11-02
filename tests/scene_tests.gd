extends SceneTree

var checks := 0
var failures := 0
var main: Manor

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	main = load("res://scenes/manor.tscn").instantiate()
	root.add_child(main)
	main.player.automated = true
	await physics_frame
	await physics_frame
	_check(main.rules.key() == ManorRules.from_seed("A").key(), "scene starts from requested seed A")
	_check(main.player.camera.fov == 75 and is_equal_approx(main.player.camera.position.y, 1.65), "first-person scale")
	for id in main.rooms:
		var room: ManorRoom = main.rooms[id]
		_check(room.position == ManorGeometry.center(main.rules.board.find(id)), "room is at its logical slot")
		for door in room.doors:
			var state := ManorRules.new(main.rules.board, id)
			var allowed := not door.is_front and state.can_walk(door.direction)
			_check(door.opened == allowed and (door.gate.collision_layer == 0) == allowed, "door animation and collision agree with rules")
	_check_all_spawn_yaws()
	var foyer: ManorRoom = main.rooms[7]
	main.player.aim_at(foyer.global_position + Vector3.UP * 0.8)
	_check(main.player.begin_interact(), "spawn lever reachable without walking")
	main.player.select_pull(ManorRules.W)
	main.player.release_interact()
	_check(not main.sliding and main.slides == 0, "invalid lever direction does not slide")
	_check(main.player.begin_interact(), "lever can be held again")
	main.player.cancel_pull()
	_check(not main.player.held and not main.sliding, "cancel releases lever without moving")
	_check(main.player.begin_interact(), "lever can be re-engaged after cancel")
	main.player.select_pull(ManorRules.E)
	var local := foyer.to_local(main.player.global_position)
	main.player.release_interact()
	_check(main.sliding and main.player.get_parent() == foyer, "slide parents player to room")
	_check(not main.request_slide(ManorRules.E), "second slide blocked in transit")
	await create_timer(0.7).timeout
	_check(foyer.to_local(main.player.global_position).distance_to(local) < 0.001, "mid-slide rider position preserved")
	_check(main.rules.board == ManorRules.from_seed("A").board, "logical board stays atomic during transit")
	await main.slide_finished
	_check(main.slides == 1 and main.rules.slot() == 7, "slide commits room to destination")
	_check(foyer.to_local(main.player.global_position).distance_to(local) < 0.001, "landing preserves rider position")
	# Deliberately place the test actor in the edge gap to probe the unsolved boundary.
	main.rules.player = -1
	main.player.position = ManorGeometry.center(main.rules.slot()) + Vector3(0, 0.02, 1.5)
	main.player.bot_drive = Vector3.BACK
	await create_timer(1.2).timeout
	_check(main.player.position.z < 9.1 and main.rules.player == -1, "edge gap cannot bypass the house on the lawn")
	_check(not main.request_slide(ManorRules.N), "scene rejects slides from empty slot")
	main.player.bot_drive = Vector3.ZERO
	# Bedroom north is a window, even though another room is on its other side.
	main.rules.player = 0
	var bedroom: ManorRoom = main.rooms[0]
	main.player.position = bedroom.position + Vector3(1.6, 0.02, -1.6)
	main.player.velocity = Vector3.ZERO
	main.player.bot_drive = Vector3.FORWARD
	await create_timer(1.0).timeout
	_check(main.rules.player == 0 and main.player.position.z > bedroom.position.z - 2.75, "window collision prevents walking into neighbor")
	main.player.bot_drive = Vector3.ZERO
	print("Scene: %d checks, %d failures" % [checks, failures])
	main.queue_free()
	await process_frame
	quit(1 if failures else 0)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func _check_all_spawn_yaws() -> void:
	var original := main.rules.copy()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/accepted_14_20.json"))
	for entry: Dictionary in data.states:
		main.rules = ManorRules.new(PackedInt32Array(entry.board), int(entry.player))
		main.place_player_at_spawn()
		var room_center := ManorGeometry.center(main.rules.slot())
		var gap_center := ManorGeometry.center(main.rules.board.find(-1))
		var forward := -main.player.camera.global_basis.z
		forward.y = 0
		_check(forward.normalized().dot((gap_center - room_center).normalized()) > 0.99999, "every accepted spawn yaw faces the gap")
		for point in [Vector3(-0.28, 0.0, -0.28), Vector3(0.28, 0.0, 0.28), Vector3(0, 0.9, 0)]:
			_check(main.player.camera.is_position_in_frustum(room_center + point), "spawn frames entire lever")
	main.rules = original
	main.place_player_at_spawn()
	_check(is_equal_approx(main.player.rotation.y, -PI / 2.0), "seed A spawn faces east, yaw -90 degrees")
	print("Spawn yaw and lever framing: all 1,816 accepted seeds verified")
