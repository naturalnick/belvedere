extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var main: Manor = load("res://scenes/manor.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	preload("res://tools/conservatory_fixture.gd").prepare(main)
	main.start_play()
	main.player.aim_at(Vector3(0, 0.8, 0))
	DisplayServer.window_move_to_foreground()
	root.grab_focus()
