extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)
func run() -> void:
	var door := ManorDoor.new()
	root.add_child(door)
	door.build("3F6B4F")
	door.set_open(false, true)
	check(door.motion == null, "instant initialization needs no tween")
	await create_timer(0.1).timeout
	door.rattle()
	await create_timer(0.04).timeout
	check(absf(door.leaves[0].rotation.y) > 0.005, "left leaf rattles")
	check(is_equal_approx(door.leaves[0].rotation.y, -door.leaves[1].rotation.y), "both leaves rattle together in mirrored directions")
	check(door.gate.collision_layer == 1, "rattle keeps gate locked")
	await create_timer(0.3).timeout
	check(is_zero_approx(door.leaves[0].rotation.y) and is_zero_approx(door.leaves[1].rotation.y), "both leaves return exactly shut")
	var finished_motion := door.motion
	door.set_open(false)
	check(door.motion == finished_motion, "unchanged closed state creates no tween")
	door.rattle()
	await create_timer(0.04).timeout
	door.set_open(true)
	await create_timer(0.5).timeout
	check(is_equal_approx(door.leaves[0].rotation.y, deg_to_rad(-100)) and is_equal_approx(door.leaves[1].rotation.y, deg_to_rad(100)), "unlock interrupts rattle and opens both leaves")
	door.queue_free()
	await process_frame
	print("Door motion: 7 checks, %d failures" % failures)
	quit(1 if failures else 0)
