class_name ManorSolver
extends RefCounted
## Reverse multi-source 0-1 BFS: all nine solved player positions are goals.

var distance: Dictionary[int, int] = {}
var toward_goal: Dictionary[int, Vector2i] = {}

var _deque: Dictionary[int, int] = {}
var _head := 0
var _tail := 0
var ready := false

func build() -> void:
	begin_build()
	while not build_step(4096):
		pass

func begin_build() -> void:
	distance.clear()
	toward_goal.clear()
	# Integer-indexed deque avoids O(n) array shifts during exhaustive traversal.
	_deque.clear()
	_head = 0
	_tail = 0
	ready = false
	for occupant in ManorRules.HOME:
		var state := ManorRules.new(PackedInt32Array(ManorRules.HOME), occupant)
		var k := state.key()
		distance[k] = 0
		_deque[_tail] = k
		_tail += 1

# The live hint builds in bounded slices, including on single-threaded Web exports.
func build_step(max_states: int = 128) -> bool:
	var processed := 0
	while _head < _tail and processed < max_states:
		processed += 1
		var key: int = _deque[_head]
		_deque.erase(_head)
		_head += 1
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
				_head -= 1
				_deque[_head] = nk
			else:
				_deque[_tail] = nk
				_tail += 1

	ready = _head >= _tail
	return ready

func assembly_distance(state: ManorRules) -> int:
	if not ready:
		return -1
	# With one gap the lawn reconnects only to that gap; walking outside is free.
	var classic := ManorRules.new(state.board, -1 if state.player == ManorRules.OUTSIDE else state.player)
	return distance.get(classic.key(), -1)

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
