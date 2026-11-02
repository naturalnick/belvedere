extends "res://tools/fun/local_agent.gd"
## Receding horizon: at most five future slides, solely on a completed memory map.

const HORIZON := 5
const NODE_LIMIT := 1200
var planner_visits: Dictionary[String, int] = {}
var maximum_depth := 0
var maximum_nodes := 0

func _plan() -> void:
	if not _complete():
		super._plan()
		return
	var board := PackedInt32Array()
	for row in 3:
		for col in 3:
			board.append(memory[Vector2i(west + col, north + row)])
	var start := ManorRules.new(board, memory[at])
	var initial := _search_key(start)
	planner_visits[initial] = planner_visits.get(initial, 0) + 1
	var queue: Array[Dictionary] = [{"state": start, "depth": 0, "first": []}]
	var seen: Dictionary[String, bool] = {initial: true}
	var cursor := 0
	var best := INF
	while cursor < queue.size() and cursor < NODE_LIMIT:
		var node := queue[cursor]
		cursor += 1
		var state: ManorRules = node.state
		var depth: int = node.depth
		maximum_depth = maxi(maximum_depth, depth)
		if depth > 0:
			var score: float = _board_score(state.board) + 1.5 * planner_visits.get(_search_key(state), 0) + depth * 0.12
			if state.solved():
				plan.assign(node.first)
				maximum_nodes = maxi(maximum_nodes, cursor)
				return
			if score < best:
				best = score
				plan.assign(node.first)
		if depth == HORIZON:
			continue
		var routes := _walk_routes(state)
		for occupant in routes:
			if occupant < 0:
				continue
			var next := ManorRules.new(state.board, occupant)
			for d in 4:
				if not next.can_slide(d):
					continue
				var child := next.copy()
				child.apply(ManorRules.SLIDE, d)
				var key := _search_key(child)
				if seen.has(key):
					continue
				seen[key] = true
				var first: Array = node.first
				if depth == 0:
					first = routes[occupant] + [Vector2i(ManorRules.SLIDE, d)]
				queue.append({"state": child, "depth": depth + 1, "first": first})
	maximum_nodes = maxi(maximum_nodes, cursor)
	assert(not plan.is_empty())

func _complete() -> bool:
	if not anchored_north or not anchored_west:
		return false
	for row in 3:
		for col in 3:
			if memory.get(Vector2i(west + col, north + row), UNKNOWN) < -1:
				return false
	return true

func _walk_routes(state: ManorRules) -> Dictionary[int, Array]:
	var routes: Dictionary[int, Array] = {state.player: []}
	var queue: Array[int] = [state.player]
	var cursor := 0
	while cursor < queue.size():
		var occupant := queue[cursor]
		cursor += 1
		var current := ManorRules.new(state.board, occupant)
		for d in 4:
			if current.can_walk(d):
				var other := current.board[ManorRules.neighbor(current.slot(), d)]
				if not routes.has(other):
					routes[other] = routes[occupant] + [Vector2i(ManorRules.WALK, d)]
					queue.append(other)
	return routes

func _search_key(state: ManorRules) -> String:
	var occupants: Array = _walk_routes(state).keys()
	occupants.sort()
	return str(state.board) + ":" + str(occupants[0])

func _board_score(board: PackedInt32Array) -> float:
	var score := 0.0
	for slot in 9:
		var room := board[slot]
		if room < 0:
			continue
		score += absi(slot % 3 - room % 3) + absi(slot / 3 - room / 3)
		if slot != room:
			score += 1.0
	return score
