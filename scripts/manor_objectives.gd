class_name ManorObjectives
extends RefCounted

const ROOMS: Array[int] = [0, 1, 2, 3, 5, 6, 8]
var completed: Array[int] = []
var active := -1
var all_completed := false
var bonus_won := false

func start(state: ManorRules) -> void:
	# Even a zero-slide target waits for a visit before earning its coin.
	active = nearest_goal(state, ROOMS).room

func advance(state: ManorRules) -> Array[int]:
	var earned: Array[int] = []
	if state.board == PackedInt32Array(ManorRules.HOME):
		bonus_won = true
	# Assembly unlocks the conservatory independently of the active coin objective.
	if active >= 0 and (state.board[active] != active or state.player != active):
		return earned
	if active >= 0:
		completed.append(active)
		earned.append(active)
	active = -1
	if completed.size() < ROOMS.size():
		var pending: Array[int] = []
		for room in ROOMS:
			if not completed.has(room):
				pending.append(room)
		active = nearest_goal(state, pending).room
	all_completed = completed.size() == ROOMS.size()
	return earned

static func nearest_goal(start: ManorRules, targets: Array[int], enter_room: bool = false) -> Dictionary:
	# Outside walking returns to the same sole gap, so the classic walk graph is equivalent.
	var origin := ManorRules.new(start.board, -1 if start.player == ManorRules.OUTSIDE else start.player)
	var deque: Dictionary[int, int] = {0: origin.key()}
	var distance: Dictionary[int, int] = {origin.key(): 0}
	var previous: Dictionary[int, int] = {}
	var actions: Dictionary[int, Vector2i] = {}
	var closed: Dictionary[int, bool] = {}
	var head := 0
	var tail := 1
	while head < tail:
		var key: int = deque[head]
		deque.erase(head)
		head += 1
		if closed.has(key):
			continue
		closed[key] = true
		var state := ManorRules.from_key(key)
		for room in targets:
			if state.board[room] == room and (not enter_room or state.player == room):
				var path: Array[Vector2i] = []
				var cursor := key
				while previous.has(cursor):
					path.append(actions[cursor])
					cursor = previous[cursor]
				path.reverse()
				return {"room": room, "slides": distance[key], "path": path}
		for action in state.moves():
			var next := state.copy()
			next.apply(action.x, action.y)
			var nk := next.key()
			var cost := distance[key] + action.x
			if cost >= distance.get(nk, 1000000):
				continue
			distance[nk] = cost
			previous[nk] = key
			actions[nk] = action
			if action.x == ManorRules.WALK:
				head -= 1
				deque[head] = nk
			else:
				deque[tail] = nk
				tail += 1
	push_error("No reachable room objective")
	return {"room": -1, "slides": -1, "path": []}
