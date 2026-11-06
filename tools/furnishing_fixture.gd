extends RefCounted

static func place(main: Manor, id: int) -> void:
	# Each gallery/test fixture puts its room west of the gap, ready for the same slide.
	var board: Array[int] = [6, 2, 5, 0, -1, 3, 7, 1, 8]
	var previous := board.find(id)
	board[previous] = board[3]
	board[3] = id
	main.rules = ManorRules.new(board, id)
	main.rules.lawn_access = true
	main.won = false
	main.objectives = null
	for room_id in main.rooms:
		main.rooms[room_id].position = ManorGeometry.center(board.find(room_id))
	main.gap_floors.clear()
	main.gap_floors[4] = main.gap_floor
	main.gap_floor.position = ManorGeometry.center(4) + Vector3.DOWN * 0.02
	main.player.position = main.rooms[id].position + Vector3(0, 0.02, 1.2)
	main.player.velocity = Vector3.ZERO
	main.player.bot_drive = Vector3.ZERO
	main.refresh_doors(true)
