extends RefCounted

static func prepare(main: Manor, last_room: int = 7) -> void:
	# One real outward shift completes the house and exposes the center square.
	var board := PackedInt32Array(ManorRules.HOME)
	board[4] = last_room
	board[last_room] = -1
	main.rules = ManorRules.new(board, last_room)
	main.rules.courtyards = true
	for id in main.rooms:
		main.rooms[id].position = ManorGeometry.center(board.find(id))
	main.gap_floors.clear()
	main.gap_floors[last_room] = main.gap_floor
	main.gap_floor.position = ManorGeometry.center(last_room) + Vector3.DOWN * 0.02
	main.player.position = ManorGeometry.center(last_room).normalized() * 1.25 + Vector3.UP * 0.02
	main.player.velocity = Vector3.ZERO
	main.player.bot_drive = Vector3.ZERO
	if main.objectives != null:
		main.first_coin_guide.seen = true
		main.objectives.completed.assign(ManorObjectives.ROOMS)
		main.objectives.active = -1
	main.refresh_doors(true)

# Ending/statistics tests exercise the old finale independently of the reveal's real-time tests.
static func finish_reveal(main: Manor) -> void:
	main.gap_floors.clear()
	main.gap_floors[4] = main.gap_floor
	main.gap_floor.position = Vector3(0, -0.02, 0)
	var c := main.conservatory
	c._start_reveal()
	c._process(ManorConservatory.CLOSE_TIME + ManorConservatory.RETRACT_TIME + 0.4)
	c._process(ManorConservatory.RISE_TIME + ManorConservatory.SETTLE_TIME)
	c.take_key()
	c._process(ManorConservatory.REWARD_HOLD_AT)
	c.accept_reward()
	c._process(ManorConservatory.PICKUP_TIME)
