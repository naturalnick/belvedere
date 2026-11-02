class_name ManorSolver
extends RefCounted
## Reverse multi-source 0-1 BFS: all nine solved player positions are goals.

var distance: Dictionary[int, int] = {}
var toward_goal: Dictionary[int, Vector2i] = {}

func build() -> void:
	distance.clear()
	toward_goal.clear()
	# Integer-indexed deque avoids O(n) array shifts during exhaustive traversal.
	var deque: Dictionary[int, int] = {}
	var head := 0
	var tail := 0
	for occupant in ManorRules.HOME:
		var state := ManorRules.new(PackedInt32Array(ManorRules.HOME), occupant)
		var k := state.key()
		distance[k] = 0
		deque[tail] = k
		tail += 1
	while head < tail:
		var key: int = deque[head]
		deque.erase(head)
		head += 1
		var state := ManorRules.from_key(key)
		for action in state.moves():
			var next := state.copy()
			next.apply(action.x, action.y)
			var nk := next.key()
			var cost := distance[key] + action.x
			if cost >= distance.get(nk, 1000000):
				continue
			distance[nk] = cost
			toward_goal[nk] = Vector2i(action.x, ManorRules.opposite(action.y))
			if action.x == ManorRules.WALK:
				head -= 1
				deque[head] = nk
			else:
				deque[tail] = nk
				tail += 1

func solution(start: ManorRules, minimize_walks: bool = false) -> Array[Vector2i]:
	if minimize_walks:
		return _shortest_optimal_route(start)
	var result: Array[Vector2i] = []
	var state := start.copy()
	var seen: Dictionary[int, bool] = {}
	while not state.solved():
		var k := state.key()
		if not toward_goal.has(k) or seen.has(k):
			push_error("State is unreachable or solver policy contains a cycle")
			return []
		seen[k] = true
		var action: Vector2i = toward_goal[k]
		result.append(action)
		state.apply(action.x, action.y)
	return result

func _shortest_optimal_route(start: ManorRules) -> Array[Vector2i]:
	# BFS on distance-preserving edges breaks slide-optimal ties by walk count.
	var queue: Array[int] = [start.key()]
	var previous: Dictionary[int, int] = {start.key(): start.key()}
	var actions: Dictionary[int, Vector2i] = {}
	var cursor := 0
	while cursor < queue.size():
		var key := queue[cursor]
		cursor += 1
		var state := ManorRules.from_key(key)
		if state.solved():
			var path: Array[Vector2i] = []
			while key != start.key():
				path.append(actions[key])
				key = previous[key]
			path.reverse()
			return path
		for action in state.moves():
			var next := state.copy()
			next.apply(action.x, action.y)
			var nk := next.key()
			if previous.has(nk) or distance.get(nk, -1) != distance[key] - action.x:
				continue
			previous[nk] = key
			actions[nk] = action
			queue.append(nk)
	push_error("No optimal route from requested state")
	return []
