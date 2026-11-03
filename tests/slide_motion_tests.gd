extends SceneTree
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func run() -> void:
	check(is_equal_approx(ManorSlideMotion.DURATION, 1.6), "settling pass adds only 0.2 seconds to the slide")
	check(ManorSlideMotion.travel_progress(0) == 0 and ManorSlideMotion.travel_progress(1) == 1, "slide has exact endpoints")
	var previous := 0.0
	for i in range(1, 201):
		var progress := ManorSlideMotion.travel_progress(i / 200.0)
		check(progress >= previous and progress <= 1.0, "room never reverses or overshoots")
		previous = progress
	check(ManorSlideMotion.travel_progress(0.001) < 0.00001, "travel starts without a velocity jump")
	check(1.0 - ManorSlideMotion.travel_progress(0.999) < 0.00001, "travel lands without a velocity jump")
	var last_tenth := 6.25 * (1.0 - ManorSlideMotion.travel_progress(1.0 - 0.1 / ManorSlideMotion.TRAVEL))
	check(last_tenth < 0.025, "last tenth of a second settles less than 2.5 cm")
	var main: Manor = load("res://scenes/manor.tscn").instantiate()
	root.add_child(main)
	main.start_play()
	main.rules.player = 7
	main.place_player_at_spawn()
	main.player.automated = true
	await physics_frame
	var room: ManorRoom = main.rooms[7]
	var origin := room.global_position
	var rider := room.to_local(main.player.global_position)
	var key := main.rules.key()
	check(main.request_slide(ManorRules.E), "seed A slide starts")
	check(main.controls_locked(), "take-up immediately locks input")
	check(main.player.get_parent() == room, "rider is attached before travel")
	check(not main.request_slide(ManorRules.E), "second slide rejected during take-up")
	await create_timer(0.04).timeout
	check(room.global_position.is_equal_approx(origin), "take-up keeps the room still")
	check(main.rules.key() == key, "take-up does not advance puzzle state")
	await create_timer(0.66).timeout
	check(room.global_position.x > origin.x and room.global_position.x < origin.x + 6.25, "room travels between its slots")
	check(room.to_local(main.player.global_position).distance_to(rider) < 0.001, "rider stays fixed during travel")
	var saw_dock := false
	while main.sliding:
		if not saw_dock and room.global_position.is_equal_approx(origin + Vector3.RIGHT * 6.25):
			saw_dock = true
			check(main.controls_locked() and main.rules.key() == key, "docking holds input and puzzle state until completion")
			check(main.player.get_parent() == room, "rider stays attached through docking")
		await process_frame
	check(saw_dock, "docking phase occurs after travel")
	check(room.global_position.is_equal_approx(origin + Vector3.RIGHT * 6.25), "room docks exactly one pitch away")
	check(room.to_local(main.player.global_position).distance_to(rider) < 0.001, "rider position survives docking")
	check(main.player.get_parent() == main and main.rules.valid() and main.slides == 1, "docking commits state once and detaches rider")
	check(main.player.camera.position.is_equal_approx(Vector3(0, 1.65, 0)), "pass adds no camera displacement")
	main.queue_free()
	await process_frame
	print("Slide motion: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
