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

func run() -> void:
	# Run with --web-entry; headless has no real pointer lock, so the test supplies it.
	var main: Manor = load("res://scenes/manor.tscn").instantiate()
	root.add_child(main)
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
	main.player.automated = true
	await wait(1.3)
	check(not main.play_gate.visible, "automated runs are left alone")
	main.queue_free()
	await process_frame
	print("Pointer watch: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
