extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var main: Manor = load("res://scenes/manor.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	main.stopwatch.solver.build()
	preload("res://tools/stopwatch_fixture.gd").place(main, true)
	DisplayServer.window_move_to_foreground()
	root.grab_focus()
