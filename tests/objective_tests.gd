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
	for seed_name in ["A", "B", "C"]:
		var state := ManorRules.from_seed(seed_name)
		var progress := ManorObjectives.new()
		progress.advance(state)
		var total_slides := 0
		var total_walks := 0
		var stages := 0
		while not progress.main_won and stages < 7:
			check(progress.active != 7 and progress.active >= 0, "Foyer is never an objective")
			var active := progress.active
			var result := ManorObjectives.nearest_goal(state, [active])
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
		check(progress.main_won and progress.completed.size() == 7, "seven objectives finish the main game")
		print("Objectives seed %s: %d slides, %d walks, bonus=%s" % [seed_name, total_slides, total_walks, progress.bonus_won])
	var progress := ManorObjectives.new()
	progress.completed.assign([0, 1, 2, 3, 5, 6])
	progress.active = 8
	progress.advance(ManorRules.from_seed("A"))
	check(progress.main_won and not progress.bonus_won, "main win does not require assembled house")
	progress.advance(ManorRules.from_seed("B"))
	check(progress.main_won and progress.completed.size() == 7, "main win persists after moving completed rooms away")
	var early := ManorObjectives.new()
	early.advance(ManorRules.new())
	check(early.main_won and early.bonus_won and early.completed.size() == 7, "early full solve awards both wins")
	check(early.active == -1, "no further target after winning")
	print("Objectives: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
