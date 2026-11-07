extends Node

const FIXTURE = preload("res://tools/furnishing_fixture.gd")
const CONSERVATORY = preload("res://tools/conservatory_fixture.gd")
# Whichever slot leaves the room's accent wall facing the central gap.
const SLOT_FOR_WALL: Array[int] = [7, 3, 1, 5]

# Walks a player from the fixture's start to a comfortable spot in front of a room's bell.
static func walk_to_bell(driver: Node, main: Manor, id: int) -> void:
	var bell: ManorBell = main.bell_mounts[id]
	await driver.walk_to(main.rooms[id].position + Vector3(0, 0, 1.2))
	if id == 6:
		# Dining's table fills the straight line; its north aisle reaches the bell.
		await driver.walk_to(main.rooms[id].position + Vector3(0.8, 0, -2.0))
	# The Foyer's bell hangs above the bench, which keeps the player further from the wall.
	var stand := bell.global_position + bell.global_transform.basis.z * (1.35 if id == 7 else 1.0)
	stand.y = 0.02
	await driver.walk_to(stand)

func run(driver: Node) -> void:
	var main: Manor = driver.main
	for id: int in main.bell_mounts:
		FIXTURE.place(main, id)
		await get_tree().physics_frame
		var bell: ManorBell = main.bell_mounts[id]
		await walk_to_bell(driver, main, id)
		main.player.aim_at(bell.global_position)
		await driver.shot("bell_%d" % id)
	var camera := Camera3D.new()
	camera.fov = 70
	main.add_child(camera)
	for id: int in ManorBells.LETTERS:
		var wall: int = (main.rooms[id].first_window() + 2) % 4
		_place(main, id, SLOT_FOR_WALL[wall])
		var letter := main.rooms[id].find_child("WallLetter", true, false) as MeshInstance3D
		var outward: Vector3 = ManorGeometry.DIRECTIONS[wall]
		camera.look_at_from_position(letter.global_position + outward * 4.6 + Vector3(0, 0.1, 0), letter.global_position)
		camera.make_current()
		await driver.shot("letter_%d" % id)
	main.player.camera.make_current()
	# Finish the bells away from the Foyer's case, then walk up to it.
	_place(main, 7, 7)
	main.player.global_position = main.rooms[7].to_global(Vector3(1.5, 0.02, 1.6))
	main.player.velocity = Vector3.ZERO
	await get_tree().physics_frame
	main.player.aim_at(main.trophy_case.global_position + Vector3.UP * 1.4)
	await driver.shot("trophy_waiting")
	for letter in ManorBells.WORD:
		main.bells.ring(ManorBells.LETTERS.find_key(letter))
	var case := main.trophy_case
	driver._check(main.bells.complete and not case.opened, "the ninth ring leaves the case shut")
	while not case.opened:
		await get_tree().process_frame
	main.player.aim_at(case.global_position + Vector3.UP * 1.4)
	await driver.shot("case_open")
	await driver.walk_to(case.to_global(Vector3(0, 0, 1.5)))
	main.player.aim_at(case.to_global(Vector3(0, 1.4, 0)))
	await get_tree().physics_frame
	driver._check(main.player.begin_interact(), "the open display takes the trophy")
	main.player.release_interact()
	while case.reward_elapsed < ManorTrophyCase.HOLD_AT:
		await get_tree().process_frame
	await driver.shot("trophy_presented")
	var accept := InputEventKey.new()
	accept.physical_keycode = KEY_SPACE
	accept.pressed = true
	case._input(accept)
	while not case.owned:
		await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	driver._check(not main.controls_locked(), "the trophy hands control back once it is in the inventory")
	await driver.shot("trophy_inventory")
	# The letters that face the centre stay readable through the conservatory's glass.
	var home := PackedInt32Array(ManorRules.HOME)
	main.rules = ManorRules.new(home, 7)
	main.rules.lawn_access = true
	for room_id in main.rooms:
		main.rooms[room_id].position = ManorGeometry.center(room_id)
	main.gap_floor.position = Vector3(0, -0.02, 0)
	main.first_home_guide.seen = true
	main.refresh_progress()
	CONSERVATORY.finish_reveal(main)
	await get_tree().create_timer(0.3).timeout
	for id in [3, 5, 7]:
		var letter := main.rooms[id].find_child("WallLetter", true, false) as MeshInstance3D
		var inward := -letter.global_position
		inward.y = 0
		camera.look_at_from_position(Vector3(letter.global_position.x, 1.65, letter.global_position.z) + inward.normalized() * 2.4, letter.global_position)
		camera.make_current()
		await driver.shot("letter_conservatory_%d" % id)
	main.player.camera.make_current()
	camera.queue_free()

func _place(main: Manor, id: int, slot: int) -> void:
	var board: Array[int] = [6, 2, 5, 0, -1, 3, 7, 1, 8]
	var previous := board.find(id)
	board[previous] = board[slot]
	board[slot] = id
	main.rules = ManorRules.new(board, id)
	main.rules.lawn_access = true
	for room_id in main.rooms:
		main.rooms[room_id].position = ManorGeometry.center(board.find(room_id))
	main.gap_floor.position = ManorGeometry.center(4) + Vector3.DOWN * 0.02
	main.refresh_doors(true)
