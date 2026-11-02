extends RefCounted
## Receives only the current room identity and four observed sides, never ManorRules.

const UNKNOWN := -2
const OUTSIDE := -3
const STEPS := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
var memory: Dictionary[Vector2i, int] = {}
var at := Vector2i.ZERO
var north := UNKNOWN
var west := UNKNOWN
var anchored_north := false
var anchored_west := false
var learned: Dictionary[String, float] = {}
var visits: Dictionary[String, int] = {}
var plan: Array[Vector2i] = []
var rng := RandomNumberGenerator.new()

func _init(random_seed: int) -> void:
	rng.seed = random_seed

func observe(room: int, sides: PackedInt32Array) -> void:
	memory[at] = room
	for d in 4:
		memory[at + STEPS[d]] = sides[d]
		if sides[d] == OUTSIDE:
			match d:
				0:
					north = at.y
					anchored_north = true
				1:
					west = at.x - 2
					anchored_west = true
				2:
					north = at.y - 2
					anchored_north = true
				3:
					west = at.x
					anchored_west = true

func choose() -> Vector2i:
	if plan.is_empty():
		_plan()
	assert(not plan.is_empty(), "Observed legal actions must exist")
	return plan.pop_front()

func moved(action: Vector2i) -> void:
	var destination: Vector2i = at + STEPS[action.y]
	if action.x == ManorRules.SLIDE:
		memory[destination] = memory[at]
		memory[at] = -1
	at = destination

func _plan() -> void:
	# Walk reachability uses only remembered identities and their known doorway sides.
	var paths: Dictionary[Vector2i, Array] = {at: []}
	var queue: Array[Vector2i] = [at]
	var cursor := 0
	while cursor < queue.size():
		var p := queue[cursor]
		cursor += 1
		for d in 4:
			var q: Vector2i = p + STEPS[d]
			var other: int = memory.get(q, UNKNOWN)
			if other < -1 or paths.has(q):
				continue
			if _walkable(memory[p], other, d):
				paths[q] = paths[p] + [Vector2i(ManorRules.WALK, d)]
				queue.append(q)
	# Explore remembered frontiers before judging an incompletely observed board.
	var frontier: Array[Vector2i] = []
	var frontier_length := 1000
	for p in paths:
		for step: Vector2i in STEPS:
			if not memory.has(p + step) and paths[p].size() < frontier_length:
				frontier.assign(paths[p])
				frontier_length = frontier.size()
	if not frontier.is_empty():
		plan = frontier
		return
	var current_key := _key(memory, queue)
	visits[current_key] = visits.get(current_key, 0) + 1
	var best := INF
	var backup := INF
	for p in paths:
		if memory[p] < 0:
			continue
		for d in 4:
			var q: Vector2i = p + STEPS[d]
			if memory.get(q, UNKNOWN) != -1:
				continue
			var believed: Dictionary[Vector2i, int] = memory.duplicate()
			believed[q] = memory[p]
			believed[p] = -1
			var next_key := _key(believed, _component(believed, q))
			var heuristic := maxf(_heuristic(believed), learned.get(next_key, 0.0))
			backup = minf(backup, 1.0 + heuristic)
			# Learning raises local minima; revisit and walk costs only break near-ties.
			var score: float = heuristic + 0.05 * paths[p].size() + 0.1 * visits.get(next_key, 0) + rng.randf() * 0.001
			if score < best:
				best = score
				plan.assign(paths[p] + [Vector2i(ManorRules.SLIDE, d)])
	learned[current_key] = maxf(learned.get(current_key, 0.0), backup)

func _component(board: Dictionary[Vector2i, int], start: Vector2i) -> Array[Vector2i]:
	var seen: Array[Vector2i] = [start]
	var cursor := 0
	while cursor < seen.size():
		var p := seen[cursor]
		cursor += 1
		for d in 4:
			var q: Vector2i = p + STEPS[d]
			var other: int = board.get(q, UNKNOWN)
			if other >= -1 and not seen.has(q) and _walkable(board[p], other, d):
				seen.append(q)
	return seen

func _heuristic(board: Dictionary[Vector2i, int]) -> float:
	var result := 0.0
	for p in board:
		var room: int = board[p]
		if room < 0:
			continue
		var dx := absi(p.x - west - room % 3) if anchored_west else 0
		var dy := absi(p.y - north - room / 3) if anchored_north else 0
		result += dx + dy
		if dx + dy > 0:
			result += 1.0
	return result

func _key(board: Dictionary[Vector2i, int], component: Array[Vector2i]) -> String:
	var cells: Array[Vector2i] = []
	cells.assign(board.keys())
	cells.sort()
	component.sort()
	var result := str(component[0]) + ":"
	for cell in cells:
		if board[cell] != OUTSIDE:
			result += "%s=%d;" % [cell, board[cell]]
	return result

func _walkable(room: int, other: int, d: int) -> bool:
	return (room == -1 or ManorRules.doorway(room, d)) and (other == -1 or ManorRules.doorway(other, ManorRules.opposite(d)))
