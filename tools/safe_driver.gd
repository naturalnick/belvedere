extends Node

func run(driver: Node) -> void:
	var main: Manor = driver.main
	main.first_home_guide.seen = true
	var viewpoints: Array[Vector3] = [Vector3(-4.05, 0.02, 1.55), Vector3(-0.35, 0.02, 4.40), Vector3(3.65, 0.02, 1.60), Vector3(-3.65, 0.02, 1.2)]
	for clue in main.fruit_clues:
		var slot: int = [3, 7, 5, 3][clue.kind]
		var board: Array[int] = [0, 1, 2, 3, -1, 5, 6, 7, 8]
		var previous := board.find(clue.room.room_id)
		board[previous] = board[slot]
		board[slot] = clue.room.room_id
		main.rules = ManorRules.new(board, ManorRules.OUTSIDE)
		main.rules.lawn_access = true
		for id in main.rooms:
			main.rooms[id].position = ManorGeometry.center(board.find(id))
		main.gap_floor.position = Vector3(0, -0.02, 0)
		main.refresh_doors(true)
		var target := Vector3.ZERO
		for fruit in clue.fruits:
			target += fruit.global_position
		target /= clue.fruits.size()
		target.y += 0.12
		main.player.position = clue.room.position + viewpoints[clue.kind]
		main.player.velocity = Vector3.ZERO
		main.player.aim_at(target)
		await get_tree().physics_frame
		await get_tree().process_frame
		await driver.shot("fruit_%d_window" % clue.kind)
		var visible_image := get_viewport().get_texture().get_image()
		clue.hide()
		await driver.shot("fruit_%d_window_empty" % clue.kind)
		var empty_image := get_viewport().get_texture().get_image()
		var changed := _changed_pixels(visible_image, empty_image)
		driver._check(changed > 100, "fruit %d is rendered through its window (%d pixels)" % [clue.kind, changed])
		var silhouettes := _fruit_silhouettes(visible_image, empty_image)
		driver._check(silhouettes == ManorFruitClue.COUNTS[clue.kind], "fruit %d has %d separate countable silhouettes" % [clue.kind, silhouettes])
		clue.show()
		# Compare actual pixels through a closed pane, an open doorway, and from inside.
		for view in ["inside", "closed_door", "open_door"]:
			main.player.position = clue.room.position + Vector3(0, 0.02, 1.2)
			if view != "inside":
				var direction := ManorRules.N
				while ManorRules.side(clue.room.room_id, direction) != ManorRules.DOOR:
					direction += 1
				for other in main.rooms.values():
					for door in other.doors:
						door.set_open(other != clue.room or view == "open_door", true)
				main.player.position = clue.room.position + ManorGeometry.DIRECTIONS[direction] * 3.5 + Vector3.UP * 0.02
			main.player.aim_at(target)
			await driver.shot("fruit_%d_%s" % [clue.kind, view])
			visible_image = get_viewport().get_texture().get_image()
			clue.hide()
			await get_tree().process_frame
			RenderingServer.force_draw(false)
			empty_image = get_viewport().get_texture().get_image()
			changed = _changed_pixels(visible_image, empty_image)
			driver._check(changed > 10 if view == "closed_door" else changed == 0, "fruit %d visibility from %s (%d changed pixels)" % [clue.kind, view, changed])
			clue.show()
	var safe := main.study_safe
	main.rules.player = 2
	main.player.position = safe.to_global(Vector3(0, 0.02, 1.6))
	main.player.aim_at(safe.to_global(Vector3(0, 0.50, 0.25)))
	await get_tree().physics_frame
	await driver.shot("safe_closed")
	# Native input, alternating mouse and E, verifies the same targets used in play.
	for index in [2, 0, 3, 2, 1, 0, 2, 1, 0, 2]:
		main.player.aim_at(safe.buttons[index].global_position)
		await get_tree().physics_frame
		main.player.automated = false
		if index % 2 == 0:
			driver.mouse_button(true)
		else:
			driver.key_event(KEY_E, true)
		await get_tree().process_frame
		var counts_after_press := safe.counts.duplicate()
		if index % 2 != 0:
			var repeat := InputEventKey.new()
			repeat.physical_keycode = KEY_E
			repeat.keycode = KEY_E
			repeat.pressed = true
			repeat.echo = true
			Input.parse_input_event(repeat)
			await get_tree().process_frame
			driver._check(safe.counts == counts_after_press, "held E does not add taps")
		if index % 2 == 0:
			driver.mouse_button(false)
		else:
			driver.key_event(KEY_E, false)
		main.player.automated = true
		await get_tree().process_frame
	driver._check(safe.counts == [3, 2, 4, 1], "native presses enter the fruit counts in any order")
	main.player.aim_at(safe.to_global(Vector3(0, 0.50, 0.25)))
	await driver.shot("safe_entered")
	main.player.aim_at(safe.handle.global_position)
	main.player.automated = false
	driver.key_event(KEY_E, true)
	await get_tree().process_frame
	driver.key_event(KEY_E, false)
	main.player.automated = true
	await get_tree().create_timer(1.2).timeout
	driver._check(safe.unlocked and not safe.busy, "native handle interaction opens safe")
	await driver.accept_rewards()
	main.player.aim_at(safe.to_global(Vector3(0, 0.48, 0)))
	await driver.shot("safe_open")
	main.player.position = main.rooms[2].position + Vector3(-0.6, 0.02, 1.1)
	main.player.aim_at(safe.global_position + Vector3.UP * 0.75)
	await driver.shot("safe_room")

func _changed_pixels(a: Image, b: Image) -> int:
	var changed := 0
	for y in a.get_height():
		for x in a.get_width():
			var first := a.get_pixel(x, y)
			var second := b.get_pixel(x, y)
			if absf(first.r - second.r) + absf(first.g - second.g) + absf(first.b - second.b) > 0.035:
				changed += 1
	return changed

func _fruit_silhouettes(a: Image, b: Image) -> int:
	var width := a.get_width()
	var height := a.get_height()
	var mask := PackedByteArray()
	mask.resize(width * height)
	for y in height:
		for x in width:
			var first := a.get_pixel(x, y)
			var second := b.get_pixel(x, y)
			if absf(first.r - second.r) + absf(first.g - second.g) + absf(first.b - second.b) > 0.035:
				mask[y * width + x] = 1
	var count := 0
	for start in mask.size():
		if mask[start] == 0:
			continue
		var pending: Array[int] = [start]
		mask[start] = 0
		var area := 0
		while not pending.is_empty():
			var pixel: int = pending.pop_back()
			area += 1
			for next: int in [pixel - width, pixel + width, pixel - 1 if pixel % width > 0 else -1, pixel + 1 if pixel % width < width - 1 else -1]:
				if next >= 0 and next < mask.size() and mask[next] == 1:
					mask[next] = 0
					pending.append(next)
		# Stems and edge antialiasing may make tiny islands; count the fruit bodies.
		if area > 100:
			count += 1
	return count
