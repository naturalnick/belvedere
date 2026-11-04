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
	create_timer(35).timeout.connect(func() -> void: quit(1))
	var main: Manor = load("res://scenes/manor.tscn").instantiate()
	root.add_child(main)
	main.start_play()
	main.player.automated = true
	var safe := main.study_safe
	check(safe.contents.get_child_count() == 1 and not safe.unlocked, "safe starts locked with binoculars inside")
	check(safe.position.x > 2.0 and absf(safe.position.z) < 0.1, "safe is on Study east window wall, between globe and chair")
	main.rules.player = 2
	main.player.global_position = safe.to_global(Vector3(0, 0.02, 1.6))
	await physics_frame
	await physics_frame
	for i in 4:
		main.player.aim_at(safe.buttons[i].global_position)
		var hit := main.player.focus()
		check(not hit.is_empty() and hit.collider.get_meta("safe_button", -2) == i, "button %d is individually reachable by interaction ray" % i)
		check(main.player.begin_interact(), "button accepts focused press")
		main.player.release_interact()
	check(safe.counts == [1, 1, 1, 1], "each button owns an independent tally")
	main.release_pointer()
	check(not safe.interact(0) and safe.counts == [1, 1, 1, 1], "pause prevents presses")
	main.resume_play()
	main.player.aim_at(safe.handle.global_position)
	check(main.player.begin_interact(), "handle is reachable through the interaction ray")
	check(not safe.unlocked and not safe.interact(0), "wrong code stays locked and rejects input during handle feedback")
	main.player.release_interact()
	await create_timer(0.5).timeout
	check(safe.counts == [0, 0, 0, 0] and not safe.busy, "wrong attempt resets every count")
	for press in 6:
		safe.interact(0)
	check(safe.counts == [6, 0, 0, 0], "extra taps never wrap into a valid code")
	safe.interact(-1)
	await create_timer(0.5).timeout
	check(safe.counts == [0, 0, 0, 0], "handle clears an over-entered attempt")
	safe.interact(1)
	# Interleave colors deliberately: the puzzle compares counts, never a sequence.
	for index in [2, 0, 3, 2, 1, 0, 2, 0, 2]:
		safe.interact(index)
	check(safe.counts == [3, 2, 4, 1] and not safe.unlocked, "complete counts wait for the handle")
	preload("res://tools/furnishing_fixture.gd").place(main, 2)
	var room_before := main.rooms[2].position
	check(main.request_slide(ManorRules.E), "Study can slide with a pending safe attempt")
	check(not safe.interact(0), "sliding blocks safe input")
	while main.sliding:
		await process_frame
	check(safe.global_position.is_equal_approx(room_before + Vector3.RIGHT * 6.25 + safe.position) and safe.counts == [3, 2, 4, 1], "safe and entered code ride Study")
	safe.interact(-1)
	main.release_pointer()
	await process_frame
	var angle := safe.door.rotation.y
	await create_timer(0.2).timeout
	check(is_equal_approx(angle, safe.door.rotation.y) and safe.busy, "pause freezes the opening animation")
	main.resume_play()
	await create_timer(1.2).timeout
	check(safe.unlocked and not safe.busy and is_equal_approx(safe.door.rotation.y, deg_to_rad(-105)), "correct counts open the safe")
	check(not safe.interact(0) and not safe.interact(-1), "opened safe cannot accept another attempt")
	var cavity_ray := PhysicsRayQueryParameters3D.create(safe.to_global(Vector3(0, 0.45, 1.0)), safe.to_global(Vector3(0, 0.45, -0.4)))
	cavity_ray.exclude = [main.player.get_rid()]
	var cavity_hit := main.get_world_3d().direct_space_state.intersect_ray(cavity_ray)
	check(not cavity_hit.is_empty() and safe.to_local(cavity_hit.position).z < 0, "open compartment has no invisible collision plane across its mouth")
	main.fall_recovery._wake()
	check(safe.unlocked and safe.counts == [3, 2, 4, 1], "fall recovery preserves the solved safe")
	for clue in main.fruit_clues:
		check(clue.fruits.size() == ManorFruitClue.COUNTS[clue.kind], "authored fruit count matches its button")
		for a in clue.fruits.size():
			for b in range(a + 1, clue.fruits.size()):
				var distance := clue.fruits[a].position.distance_to(clue.fruits[b].position)
				check(distance > (0.60 if clue.kind == 1 else 0.28), "whole fruits have distinct spacing")
		for mesh: MeshInstance3D in clue.find_children("*", "MeshInstance3D", true, false):
			check(mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and mesh.material_override.next_pass == null, "hidden clues cannot leak shadows or outlines")
		var door: ManorDoor = clue.room.doors[0]
		door.set_open(false, true)
		clue._sync_doors()
		check(clue.last_closed_doors[door.direction] == 1, "closed glass door permits clues")
		door.set_open(true)
		clue._sync_doors()
		check(clue.last_closed_doors[door.direction] == 0, "clues hide as soon as door starts opening")
		await create_timer(0.5).timeout
		door.set_open(false)
		clue._sync_doors()
		check(clue.last_closed_doors[door.direction] == 0, "clues remain hidden while door closes")
		await create_timer(0.5).timeout
		clue._sync_doors()
		check(clue.last_closed_doors[door.direction] == 1, "clues return once leaves are shut")
		clue.room.position += Vector3.FORWARD * 6.25
		await process_frame
		await process_frame
		for mat in clue.clue_materials.values():
			check(mat.get_shader_parameter("clue_room_origin") == clue.room.global_position, "window visibility follows room movement")
	main.queue_free()
	await process_frame
	print("Safe: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
