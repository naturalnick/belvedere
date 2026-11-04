extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func run() -> void:
	var opening := ManorRules.opening_start()
	var reachable: Array[ManorRules] = [opening]
	var visited: Array[int] = [opening.player]
	var first_slides: Array[Vector2i] = []
	while not reachable.is_empty():
		var state: ManorRules = reachable.pop_front()
		for direction in 4:
			if state.can_slide(direction):
				first_slides.append(Vector2i(state.player, direction))
			if state.can_walk(direction):
				var next := state.copy()
				next.apply(ManorRules.WALK, direction)
				if not visited.has(next.player):
					visited.append(next.player)
					reachable.append(next)
	check(first_slides == [Vector2i(8, ManorRules.E)], "Laundry east is the only slide reachable from the Bedroom opening")
	var first := ManorObjectives.nearest_goal(opening, ManorObjectives.ROOMS, true)
	check(first.room == 8 and first.slides == 1, "Laundry is the first objective, exactly one slide from home")
	for seed_name in ["opening", "A", "B", "C"]:
		var state := ManorRules.opening_start() if seed_name == "opening" else ManorRules.from_seed(seed_name)
		var progress := ManorObjectives.new()
		progress.start(state)
		check(progress.completed.is_empty(), "starting a game awards no coins")
		var total_slides := 0
		var total_walks := 0
		var stages := 0
		while not progress.all_completed and stages < 7:
			check(progress.active != 7 and progress.active >= 0, "Foyer is never an objective")
			var active := progress.active
			var result := ManorObjectives.nearest_goal(state, [active], true)
			var path: Array = result.path
			var slides := 0
			for action: Vector2i in path:
				check(state.apply(action.x, action.y), "objective path obeys door and slide rules")
				if action.x == ManorRules.SLIDE:
					slides += 1
				else:
					total_walks += 1
			check(state.board[active] == active and slides == result.slides, "objective distance and destination agree")
			var previous := progress.completed.duplicate()
			progress.advance(state)
			for room in previous:
				check(progress.completed.has(room), "completed rooms remain earned")
			check(progress.completed.has(active), "active room earns completion")
			total_slides += slides
			stages += 1
		check(progress.all_completed and progress.completed.size() == 7, "seven objectives earn all coin rewards")
		print("Objectives seed %s: %d slides, %d walks, bonus=%s" % [seed_name, total_slides, total_walks, progress.bonus_won])
	var progress := ManorObjectives.new()
	progress.completed.assign([0, 1, 2, 3, 5, 6])
	progress.active = 8
	var last_room := ManorRules.from_seed("A")
	last_room.player = 8
	progress.advance(last_room)
	check(progress.all_completed and not progress.bonus_won, "all room rewards do not require assembled house")
	progress.advance(ManorRules.from_seed("B"))
	check(progress.all_completed and progress.completed.size() == 7, "earned room rewards persist after moving rooms away")
	var early := ManorObjectives.new()
	early.advance(ManorRules.new())
	check(early.all_completed and early.bonus_won and early.completed.size() == 7, "early full solve earns all room rewards and the door ending")
	check(early.active == -1, "no further target after winning")
	print("Objectives: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
