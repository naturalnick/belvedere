extends SceneTree
var checks := 0
var failures := 0
var lock := false

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func wait(seconds: float) -> void:
	await create_timer(seconds).timeout
	await process_frame

func key(code: Key, echo := false) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	event.echo = echo
	return event

func press(code: Key, echo := false) -> void:
	root.push_input(key(code, echo))
	await process_frame

func run() -> void:
	var main: Manor = load("res://scenes/manor.tscn").instantiate()
	root.add_child(main)
	if OS.get_cmdline_user_args().has("--web-entry"):
		await watch_pointer(main)
	else:
		check(main.pointer_watch == null, "desktop runs do not watch pointer lock")
		main.start_play()
	await pause_keys(main)
	main.queue_free()
	await process_frame
	print("Pointer and pause keys: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func pause_keys(main: Manor) -> void:
	var web := main.pointer_watch != null
	lock = true
	main.player.automated = false
	await press(KEY_P)
	check(main.play_gate.visible and main.play_gate.mode == "pause", "P pauses play")
	await press(KEY_P)
	check(not main.play_gate.visible, "P resumes from the pause menu")
	await press(KEY_ESCAPE)
	check(main.play_gate.visible and main.play_gate.mode == "pause", "Escape pauses play")
	await press(KEY_ESCAPE, true)
	check(main.play_gate.visible, "a held Escape does not resume")
	await press(KEY_ESCAPE)
	if web:
		check(main.play_gate.visible, "web Escape leaves the menu up, since browsers refuse pointer lock from it")
		await press(KEY_P)
	check(not main.play_gate.visible, "Escape resumes on desktop; P resumes on the web")
	await press(KEY_P)
	main.play_gate._open_settings()
	await press(KEY_P)
	check(main.play_gate.visible and main.play_gate.mode == "settings", "P does not leave settings")
	main.play_gate._close_settings()
	main.resume_play()
	check(not ManorCoinHUD.is_accept_press(key(KEY_P)) and ManorCoinHUD.is_accept_press(key(KEY_E)), "P pauses instead of accepting a presented reward")

# Headless has no real pointer lock, so the test supplies it.
func watch_pointer(main: Manor) -> void:
	var watch := main.pointer_watch
	check(watch != null, "web entry installs the pointer watch")
	watch.captured = func() -> bool: return lock
	await wait(1.3)
	check(main.at_title and main.play_gate.mode == "title", "the title never turns into the pause menu")
	main.start_play()
	await wait(0.4)
	check(not main.play_gate.visible, "a pending lock request does not pause play")
	lock = true
	await wait(0.1)
	lock = false
	await wait(0.1)
	check(main.play_gate.visible and main.play_gate.mode == "pause", "losing a granted lock shows the pause menu")
	main.resume_play()
	await wait(1.3)
	check(main.play_gate.visible and main.play_gate.mode == "pause", "a refused lock request returns to the pause menu")
	main.resume_play()
	lock = true
	await wait(0.1)
	main.sliding = true
	lock = false
	await wait(0.2)
	check(not main.play_gate.visible, "a slide finishes before the pause menu appears")
	main.sliding = false
	await wait(0.1)
	check(main.play_gate.visible and main.play_gate.mode == "pause", "the pause menu appears after the slide")
	main.resume_play()
	lock = true
	await wait(0.1)
	var item := main.binoculars
	item.owned = true
	check(item.toggle(), "web binoculars can open while the pointer is locked")
	await wait(1.1)
	lock = false
	await wait(0.9)
	check(item.phase == ManorBinoculars.Phase.IDLE and not main.play_gate.visible and watch.resume_on_click, "browser Escape lowers binoculars instead of opening pause")
	await wait(1.2)
	check(not main.play_gate.visible, "waiting for a recapture click does not open pause")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	watch._input(click)
	check(not watch.resume_on_click, "the next click requests pointer capture")
	lock = true
	await wait(0.1)
	var stopwatch := main.stopwatch
	stopwatch.owned = true
	stopwatch.claimed = true
	stopwatch.model.reparent(stopwatch, true)
	check(stopwatch.toggle(), "web stopwatch raises while pointer is locked")
	await wait(0.5)
	lock = false
	await wait(0.5)
	check(stopwatch.phase == ManorStopwatch.Phase.IDLE and not main.play_gate.visible and watch.resume_on_click, "browser Escape lowers stopwatch without pausing")
	watch._input(click)
	lock = true
	await wait(0.1)
	main.player.automated = true
	await wait(1.3)
	check(not main.play_gate.visible, "automated runs are left alone")
