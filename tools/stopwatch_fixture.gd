extends RefCounted

# A legal ten-slide route to the first walkable northwest gap. Encode walks N/E/S/W
# as 0..3 and slides as 4..7, retaining the actual objective progress along the route.
const ROUTE := [2, 1, 5, 3, 0, 6, 1, 0, 7, 1, 0, 6, 3, 0, 5, 3, 3, 5, 1, 2, 2, 3, 3, 0, 4, 2, 2, 1, 1, 0, 3, 7, 2, 1, 1, 0, 0, 3, 6, 1, 2, 3, 3, 0, 0, 5, 2, 1, 2, 3, 3, 0, 0]

static func place(main: Manor, on_lawn: bool = false) -> void:
	main.rules = ManorRules.opening_start()
	main.objectives = ManorObjectives.new()
	main.objectives.start(main.rules)
	main.slides = 0
	for code in ROUTE:
		var applied := main.rules.apply(code / 4, code % 4)
		assert(applied)
		main.slides += code / 4
		main.objectives.advance(main.rules)
	assert(main.slides == 10 and main.rules.board[0] == -1 and main.rules.player == -1)
	main.rules.courtyards = true
	main.rules.gap_slot = 0
	main.first_coin_guide.seen = true
	main.coins.awarded.assign(main.objectives.completed)
	main.coins.collected.assign(main.objectives.completed)
	main.coins.pending.clear()
	main.coins.available = main.objectives.completed.size()
	main.coins.changed.emit()
	for id in main.rooms:
		main.rooms[id].position = ManorGeometry.center(main.rules.board.find(id))
	main.gap_floors.clear()
	main.gap_floors[0] = main.gap_floor
	main.gap_floor.position = ManorGeometry.center(0) + Vector3.DOWN * 0.02
	main.player.position = main.foundation_hatch.position + Vector3(0, 0.02, 1.0)
	if on_lawn:
		main.player.position = Vector3(-10.5, 0.02, -5.75)
		main.rules.player = ManorRules.OUTSIDE
		main.rules.gap_slot = -1
	main.player.velocity = Vector3.ZERO
	main.player.bot_drive = Vector3.ZERO
	main.player.aim_at(main.foundation_hatch.handle.global_position)
	main.start_play()
	main.refresh_progress()
	main.refresh_doors(true)
	main.foundation_hatch.refresh()
	main.stopwatch.refresh_count()
