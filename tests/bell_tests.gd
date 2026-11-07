extends "res://tests/manor_test.gd"

const FIXTURE = preload("res://tools/furnishing_fixture.gd")

func room_for(letter: String) -> int:
	return ManorBells.LETTERS.find_key(letter)

func ring_word(bells: ManorBells, word: String) -> Array[bool]:
	var results: Array[bool] = []
	for letter in word:
		results.append(bells.ring(room_for(letter)))
	return results

func run() -> void:
	create_timer(90).timeout.connect(func() -> void:
		printerr("FAIL: bell tests timed out")
		quit(1))
	var sequence := ManorBells.new()
	var finished := [0]
	sequence.completed.connect(func() -> void: finished[0] += 1)
	check(ManorBells.LETTERS.size() == 6 and not ManorBells.LETTERS.has(1) and not ManorBells.LETTERS.has(8), "six bells, none in the Bathroom or Laundry")
	check(ManorBells.LETTERS[6] == "E" and ManorBells.LETTERS.values().count("E") == 1, "one E bell, in Dining")
	check(sequence.ring(room_for("E")) == false and sequence.progress == 0, "the word cannot start on E")
	check(ring_word(sequence, "BELV") == [true, true, true, true] and sequence.progress == 4, "correct rings count")
	check(not sequence.ring(room_for("R")) and sequence.progress == 0, "a wrong ring clears progress")
	ring_word(sequence, "BEL")
	check(sequence.ring(room_for("B")) and sequence.progress == 1, "a mistaken B counts as a fresh start")
	check(ring_word(sequence, "ELVEDERE").all(func(counted: bool) -> bool: return counted) and sequence.complete and finished[0] == 1, "nine rings spell the word")
	check(sequence.ring(room_for("R")) and finished[0] == 1 and sequence.complete, "later rings are harmless and never complete twice")

	var main := start_manor()
	var cues: Array[String] = []
	main.audio.cued.connect(func(group: String) -> void: cues.append(group))
	var driver := add_driver(main)
	Engine.time_scale = 4.0
	check(main.bell_mounts.size() == 6, "every lettered room has a bell")
	# Reach every bell through the real interaction ray, standing where a player would.
	for id: int in main.bell_mounts:
		FIXTURE.place(main, id)
		await physics_frame
		var bell: ManorBell = main.bell_mounts[id]
		var room := main.rooms[id]
		await preload("res://tools/bell_driver.gd").walk_to_bell(driver, main, id)
		check(main.rules.player == id, "room %d bell is approached inside its own room" % id)
		main.player.aim_at(bell.to_global(ManorBellArt.HIT_CENTER))
		await physics_frame
		var hit := main.player.focus()
		check(not hit.is_empty() and hit.collider.has_meta("bell") and hit.collider.get_meta("bell") == bell, "room %d bell is reachable through the interaction ray" % id)
		var furniture := room.get_node("BedroomFurnishings" if id == 0 else "Furnishings")
		check(bell.get_parent() == room and not furniture.is_ancestor_of(bell), "room %d bell stays out of the static furniture batch" % id)
		var rung := cues.size()
		check(main.player.begin_interact(), "room %d bell rings on interact" % id)
		main.player.release_interact()
		check(cues.size() == rung + 1 and cues[rung] in ["bell_clear", "bell_off"], "room %d bell plays one tone" % id)
		var before := bell.global_position
		var rider := room.position
		room.position += Vector3.RIGHT
		check(bell.global_position.is_equal_approx(before + Vector3.RIGHT), "room %d bell rides its room" % id)
		room.position = rider
	# Letters: on the outside of each accent wall, beside the door.
	for id: int in ManorBells.LETTERS:
		var room := main.rooms[id]
		var letter := room.find_child("WallLetter", true, false) as MeshInstance3D
		check(letter != null and letter.mesh.text == ManorBells.LETTERS[id], "room %d has its own letter" % id)
		var outward: Vector3 = ManorGeometry.DIRECTIONS[(room.first_window() + 2) % 4]
		check(ManorRules.side(id, (room.first_window() + 2) % 4) == ManorRules.DOOR, "room %d letter is on a connecting wall" % id)
		var offset := letter.global_position - room.global_position
		check(is_equal_approx(offset.dot(outward), 3.129), "room %d letter sits just proud of the outer face" % id)
		check(letter.global_basis.z.dot(outward) > 0.99, "room %d letter faces outward" % id)
	check(main.rooms[1].find_child("WallLetter", true, false) == null and main.rooms[8].find_child("WallLetter", true, false) == null, "Bathroom and Laundry carry no letter")
	# The bells replay the word, the case door swings open, and the trophy waits for the player.
	var case := main.trophy_case
	var cues_before := cues.count("bell_clear")
	var peal_cues := func() -> int: return cues.count("bell_clear") - cues_before
	FIXTURE.place(main, 7)
	main.bells.progress = 0
	main.bells.complete = false
	for letter in ManorBells.WORD:
		main.bells.ring(room_for(letter))
	check(main.bells.complete and not case.opened and not case.presenting, "the ninth ring leaves the case shut")
	main.player.global_position = main.rooms[7].to_global(Vector3(2.0, 0.02, 2.0))
	await create_timer(ManorTrophyCase.PEAL_DELAY + 0.3).timeout
	check(peal_cues.call() == 1 and main.bell_mounts[room_for("B")].art.motion != null, "the B bell rings first")
	main.release_pointer()
	await create_timer(ManorTrophyCase.PEAL_INTERVAL * 2 + 0.3).timeout
	check(peal_cues.call() == 1, "the peal waits while paused")
	main.resume_play()
	await create_timer(ManorTrophyCase.PEAL_INTERVAL * 8 + 0.3).timeout
	check(peal_cues.call() == ManorBells.WORD.length() and case.peal.is_empty(), "the bells ring the word once through, nine strikes")
	check(not case.opened and not main.controls_locked(), "the peal neither takes control nor opens the case early")
	check(not case.take() and not case.display_hit.has_meta("trophy"), "the trophy cannot be taken through the shut door")
	await create_timer(ManorTrophyCase.DOOR_AFTER_PEAL + ManorTrophyCase.DOOR_TIME + 0.3).timeout
	check(case.opened and is_equal_approx(case.door.rotation.y, -ManorTrophyCase.DOOR_ANGLE) and not case.presenting, "the case door swings open on its own, away from the player")
	var free_edge := case.to_local(case.door.to_global(Vector3(0.865, 0, 0)))
	check(free_edge.z > 0.6 and free_edge.x < -0.4, "the open door stands out to the left, clear of the case front")
	main.player.global_position = case.to_global(Vector3(0, 0.02, 1.6))
	main.player.aim_at(case.to_global(Vector3(0, 1.4, 0)))
	await create_timer(0.5).timeout
	check(not case.presenting, "standing in front of the open case takes nothing by itself")
	var hit := main.player.focus()
	check(not hit.is_empty() and hit.collider.get_meta("trophy", null) == case, "the open display is reachable through the interaction ray")
	check(main.player.begin_interact(), "interacting takes the trophy")
	main.player.release_interact()
	check(case.presenting and main.controls_locked(), "taking the trophy starts its presentation")
	var accept := InputEventKey.new()
	accept.physical_keycode = KEY_SPACE
	accept.pressed = true
	case._input(accept)
	check(not case.accepted, "a press while the trophy arrives is swallowed")
	await create_timer(ManorTrophyCase.HOLD_AT + 1.0).timeout
	check(case.presenting and case.reward_elapsed == ManorTrophyCase.HOLD_AT, "the trophy waits in view for a fresh press")
	check(case.hud.title.visible and case.hud.title.text == "Bell Trophy" and case.hud.hint.text == "For whom the bell tolls", "the trophy shows its caption")
	check(is_equal_approx(case.holder.global_basis.orthonormalized().y.dot(main.player.camera.global_basis.y), cos(0.22)), "the trophy is presented upright, never turned over")
	main.release_pointer()
	await process_frame
	case._input(accept)
	check(not case.accepted, "pause holds the presentation")
	main.resume_play()
	await process_frame
	case._input(accept)
	await create_timer(ManorTrophyCase.REWARD_TIME).timeout
	check(case.owned and not case.presenting and not case.holder.visible and not main.controls_locked(), "the trophy goes into the inventory and the case is left empty")
	check(not case.hud.title.visible, "the caption clears after collection")
	check(not case.display_hit.has_meta("trophy") and not case.take(), "there is only one trophy to take")
	check(not main.won and not main.conservatory.key_owned, "the trophy has no effect on the finale")
	main.queue_free()
	driver.queue_free()
	await process_frame
	finish("Bells")
