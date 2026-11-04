extends Node

func run(driver: Node) -> void:
	var main: Manor = driver.main
	preload("res://tools/stopwatch_fixture.gd").place(main)
	main.fall_recovery._wake()
	main.binoculars.owned = true
	main.binoculars.reward_claimed = true
	main.stopwatch.owned = true
	main.stopwatch.claimed = true
	main.stopwatch.model.reparent(main.stopwatch, true)
	main.foundation_hatch.emptied = true
	while not main.stopwatch.solver.ready:
		await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	await driver.shot("sleep_bed")
	var board := main.rules.board.duplicate()
	var tokens := main.coins.available
	main.player.automated = false
	driver.key_event(KEY_E, true)
	driver.key_event(KEY_E, false)
	driver._check(main.play_gate.visible and main.play_gate.mode == "sleep", "real E on bed opens sleep confirmation")
	await driver.shot("sleep_prompt")
	var content_size := get_window().content_scale_size
	var window_size := get_window().size
	get_window().content_scale_size = Vector2i(360, 640)
	get_window().size = Vector2i(360, 640)
	await get_tree().process_frame
	await driver.shot("sleep_prompt_portrait")
	get_window().content_scale_size = content_size
	get_window().size = window_size
	await get_tree().process_frame
	await click(main.play_gate.secondary)
	driver._check(not main.play_gate.visible and main.rules.board == board, "real Cancel click preserves the room layout")
	driver.key_event(KEY_E, true)
	driver.key_event(KEY_E, false)
	await click(main.play_gate.primary)
	driver._check(main.bed_sleep.sleeping and main.recovering, "real Sleep click starts transition")
	await get_tree().create_timer(0.3).timeout
	await driver.shot("sleep_fade")
	while main.bed_sleep.sleeping:
		await get_tree().process_frame
	driver._check(main.rules.board == main.bed_sleep.opening_rules.board and main.slides == 0 and main.rules.player == 0, "wake returns the opening arrangement and Bedroom occupancy")
	driver._check(main.coins.available == tokens and main.binoculars.owned and main.stopwatch.owned, "tokens and both inventory items survive sleep")
	await driver.shot("sleep_wake")
	driver.key_event(KEY_T, true)
	driver.key_event(KEY_T, false)
	await get_tree().create_timer(0.5).timeout
	driver._check(main.stopwatch.phase == ManorStopwatch.Phase.VIEWING and main.stopwatch.remaining == 18, "retained watch reads the opening assembly distance")
	await driver.shot("sleep_watch")
	driver.key_event(KEY_W, true)
	await get_tree().create_timer(0.4).timeout
	driver.key_event(KEY_W, false)
	driver._check(main.stopwatch.phase == ManorStopwatch.Phase.IDLE, "walking works after sleep and stows the retained watch")
	main.player.automated = true

func click(button: Button) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = button.global_position + button.size / 2
	Input.parse_input_event(event)
	await get_tree().process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await get_tree().process_frame
