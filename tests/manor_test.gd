extends SceneTree
## Shared setup for the headless test scripts. Each one overrides run() and ends with finish().

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	pass

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func finish(label: String) -> void:
	print("%s: %d checks, %d failures" % [label, checks, failures])
	quit(1 if failures else 0)

func load_manor() -> Manor:
	var main: Manor = load("res://scenes/manor.tscn").instantiate()
	root.add_child(main)
	return main

func start_manor() -> Manor:
	var main := load_manor()
	main.start_play()
	main.player.automated = true
	return main

func add_driver(main: Manor) -> Node:
	var driver: Node = load("res://tools/demo_driver.gd").new()
	root.add_child(driver)
	driver.main = main
	driver.started = Time.get_ticks_msec()
	return driver

func key_press(key: Key = KEY_SPACE, echo := false) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = true
	event.echo = echo
	return event

func receive_coin(main: Manor) -> void:
	main.coin_hud._process(ManorCoinHUD.HOLD_AT)
	main.coin_hud._input(key_press())
	main.coin_hud._process(ManorCoinHUD.PRESENT_TIME)
