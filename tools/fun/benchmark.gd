extends SceneTree

const LocalAgent := preload("res://tools/fun/local_agent.gd")
const InformedAgent := preload("res://tools/fun/informed_agent.gd")
const CAP := 5000
const SAMPLE_SEED := 20261102
var solver := ManorSolver.new()

func _initialize() -> void:
	var started := Time.get_ticks_msec()
	solver.build()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/accepted_14_20.json"))
	var entries: Array = data.states
	var samples: Array[Dictionary] = []
	for name_value in ["A", "B", "C"]:
		samples.append({"name": name_value, "state": ManorRules.from_seed(name_value)})
	var rng := RandomNumberGenerator.new()
	rng.seed = SAMPLE_SEED
	var indices: Array[int] = []
	for i in entries.size():
		indices.append(i)
	for i in range(indices.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temp := indices[i]
		indices[i] = indices[j]
		indices[j] = temp
	for index in indices.slice(0, 200):
		var entry: Dictionary = entries[index]
		samples.append({"name": str(index), "state": ManorRules.new(PackedInt32Array(entry.board), int(entry.player))})
	var results: Array[Dictionary] = []
	for i in samples.size():
		var sample := samples[i]
		for bot in ["random", "greedy", "planner", "optimal"]:
			var result := trial(sample.state, bot, SAMPLE_SEED + i * 31)
			result["seed"] = sample.name
			result["bot"] = bot
			result["optimum"] = solver.distance[sample.state.key()]
			results.append(result)
		if (i + 1) % 25 == 0:
			print("Benchmarked %d / %d seeds" % [i + 1, samples.size()])
	var output := {"sample_seed": SAMPLE_SEED, "cap": CAP, "table_size": entries.size(), "results": results, "runtime_seconds": (Time.get_ticks_msec() - started) / 1000.0}
	DirAccess.make_dir_recursive_absolute("res://build/fun")
	var file := FileAccess.open("res://build/fun/benchmark.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(output, "\t"))
	print("Bot benchmark complete in %.2fs" % output.runtime_seconds)
	quit()

func trial(start: ManorRules, bot: String, random_seed: int) -> Dictionary:
	var state := start.copy()
	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed
	var agent: RefCounted = InformedAgent.new(random_seed) if bot == "planner" else LocalAgent.new(random_seed)
	var path: Array[Vector2i] = []
	if bot == "optimal":
		path = solver.solution(start)
	var slides := 0
	var walks := 0
	while not state.solved() and slides + walks < CAP:
		var action: Vector2i
		if bot == "optimal":
			action = path[slides + walks]
		elif bot == "random":
			var actions := state.moves()
			action = actions[rng.randi_range(0, actions.size() - 1)]
		else:
			# The only information crossing the sensor boundary is this local snapshot.
			var sides := PackedInt32Array()
			for d in 4:
				var q := ManorRules.neighbor(state.slot(), d)
				sides.append(LocalAgent.OUTSIDE if q < 0 else state.board[q])
			agent.observe(state.player, sides)
			action = agent.choose()
		if not state.apply(action.x, action.y):
			push_error("Bot proposed an illegal action")
			quit(1)
			return {}
		if bot in ["greedy", "planner"]:
			agent.moved(action)
		if action.x == ManorRules.SLIDE:
			slides += 1
		else:
			walks += 1
	if bot == "planner":
		assert(agent.maximum_depth <= InformedAgent.HORIZON and agent.maximum_nodes <= InformedAgent.NODE_LIMIT, "Planner exceeded its search budget")
	return {"search_depth": agent.maximum_depth if bot == "planner" else 0, "search_nodes": agent.maximum_nodes if bot == "planner" else 0, "solved": state.solved(), "slides": slides, "walks": walks, "motion_seconds": 1.4 * slides + 3.0 * walks, "human_seconds": 6.4 * slides + 3.0 * walks}
