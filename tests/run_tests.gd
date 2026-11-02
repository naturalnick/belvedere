extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	var started := Time.get_ticks_msec()
	_check(ManorRules.neighbor(2, ManorRules.E) == -1, "east edge cannot wrap")
	_check(ManorRules.neighbor(6, ManorRules.W) == -1, "west edge cannot wrap")
	_check(ManorRules.side(7, ManorRules.S) == ManorRules.FRONT, "foyer south is front door")
	var home := ManorRules.new()
	_check(home.solved() and home.valid(), "home is valid and solved")
	_check(not home.can_walk(ManorRules.S), "front door is not a puzzle walk")
	var gap := ManorRules.new(PackedInt32Array(ManorRules.HOME), -1)
	for d in 4:
		_check(gap.can_walk(d), "gap can exit through facing doors")
		_check(not gap.can_slide(d), "cannot slide from gap")
	var sealed := ManorRules.new(PackedInt32Array([6, 2, 5, 0, 1, 3, 7, -1, 8]), 1)
	_check(not sealed.can_walk(ManorRules.E), "door against window blocks walking")
	var window_slide := ManorRules.new(PackedInt32Array([0, -1, 2, 3, 1, 5, 6, 7, 8]), 1)
	_check(not window_slide.can_walk(ManorRules.N) and window_slide.can_slide(ManorRules.N), "window blocks walking but not room slide")
	var before := home.key()
	_check(not home.apply(ManorRules.SLIDE, ManorRules.S) and home.key() == before, "illegal action does not mutate")
	var solver := ManorSolver.new()
	solver.build()
	var boards: Dictionary[int, bool] = {}
	var edges := 0
	for k in solver.distance:
		var state := ManorRules.from_key(k)
		_check(state.key() == k and state.valid(), "state encoding round trip")
		boards[k & ((1 << 36) - 1)] = true
		var actions := state.moves()
		_check(not actions.is_empty(), "no dead states")
		for action in actions:
			var other := state.copy()
			_check(other.apply(action.x, action.y), "generated action is legal")
			_check(solver.distance.has(other.key()), "reachable graph is closed")
			_check(solver.distance[k] <= solver.distance[other.key()] + action.x, "optimal-distance triangle bound")
			_check(other.apply(action.x, ManorRules.opposite(action.y)) and other.key() == k, "every action is reversible")
			edges += 1
	_check(solver.distance.size() == 80303, "80,303 full states match Python simulator")
	_check(boards.size() == 12719, "12,719 boards match Python simulator")
	print("Reachable: %d boards, %d states; %d reversible directed edges" % [boards.size(), solver.distance.size(), edges])
	for seed_name in ["A", "B", "C"]:
		var state := ManorRules.from_seed(seed_name)
		var expected: int = {"A": 17, "B": 18, "C": 20}[seed_name]
		var slides := _replay(solver, state)
		_check(slides == expected, "curated seed optimum")
		print("Seed %s: %d optimal slides" % [seed_name, slides])
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/accepted_14_20.json"))
	var entries: Array = data.states
	_check(entries.size() == 1816, "accepted table has 1,816 states")
	for entry: Dictionary in entries:
		var state := ManorRules.new(PackedInt32Array(entry.board), int(entry.player))
		_check(state.valid(), "accepted board valid")
		_check(solver.distance.get(state.key(), -1) == int(entry.opt_slides), "accepted optimum matches table")
		var sees_gap := false
		for d in 4:
			if state.can_walk(d) and state.can_slide(d):
				sees_gap = true
		_check(sees_gap, "accepted spawn has an open doorway onto gap")
		_check(_replay(solver, state) == int(entry.opt_slides), "accepted solution reaches home optimally")
	print("Accepted seeds: %d verified and replayed" % entries.size())
	print("%d checks, %d failures (%.2fs)" % [checks, failures, (Time.get_ticks_msec() - started) / 1000.0])
	quit(1 if failures else 0)

func _replay(solver: ManorSolver, start: ManorRules) -> int:
	var state := start.copy()
	var slides := 0
	for action in solver.solution(start):
		_check(state.apply(action.x, action.y), "solution action legal")
		slides += action.x
	_check(state.solved(), "solution reaches solved board")
	return slides

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)
