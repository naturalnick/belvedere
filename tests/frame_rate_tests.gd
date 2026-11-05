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

func press(key: Key, echo := false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = true
	event.echo = echo
	root.push_input(event)

func run() -> void:
	create_timer(30).timeout.connect(func() -> void:
		printerr("FAIL: frame rate tests timed out")
		quit(1))
	var main: Manor = load("res://scenes/manor.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var readout := main.frame_rate
	check(not readout.visible and not readout.is_processing(), "the readout starts off and idle")
	check(readout.get_index() == main.get_child_count() - 1, "the readout sees keys before the any-key handlers")

	press(KEY_PERIOD)
	check(readout.visible and readout.is_processing(), "period shows the readout at the title")
	check(readout.label.text.ends_with(" FPS"), "it reads as a frame rate")
	check(readout.label.position.x < 100 and readout.label.position.y < 100, "it sits in the top left corner")
	press(KEY_PERIOD, true)
	check(readout.visible, "a held key does not flicker it")
	press(KEY_PERIOD)
	check(not readout.visible and not readout.is_processing(), "period hides it again")

	main.start_play()
	press(KEY_PERIOD)
	check(readout.visible, "period works during play")
	main.release_pointer()
	press(KEY_PERIOD)
	check(not readout.visible, "period works in the pause menu")
	main.resume_play()

	var binoculars := main.binoculars
	binoculars.presenting = true
	binoculars.reward_elapsed = ManorBinoculars.REWARD_HOLD_AT
	press(KEY_PERIOD)
	check(not binoculars.reward_accepted, "period does not accept a reward")
	press(KEY_X)
	check(binoculars.reward_accepted, "other keys still accept a reward")
	binoculars.presenting = false

	var summary := main.run_summary
	main.in_finale = true
	summary.revealed = true
	summary.ready_to_continue = true
	summary.show()
	press(KEY_PERIOD)
	check(not summary.exiting and summary.ready_to_continue, "period does not dismiss the ending")
	summary.ready_to_continue = false
	main.in_finale = false
	summary.revealed = false

	press(KEY_PERIOD)
	check(readout.visible, "the readout is on before the reload")
	main.free()
	await process_frame
	var again: Manor = load("res://scenes/manor.tscn").instantiate()
	root.add_child(again)
	await process_frame
	check(again.frame_rate.visible, "it stays on across the Play reload")
	await process_frame
	print("Frame rate: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
