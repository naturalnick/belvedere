extends "res://tests/manor_test.gd"
const FIXTURE = preload("res://tools/conservatory_fixture.gd")

func run() -> void:
	var main := start_manor()
	var c := main.conservatory
	var cues: Array[String] = []
	main.audio.cued.connect(func(group: String) -> void: cues.append(group))
	check(c.room == null and not c.is_processing(), "unsolved game has no conservatory geometry or per-frame work")
	FIXTURE.prepare(main)
	main.player.aim_at(Vector3(0, 1.4, 10))
	await physics_frame
	check(main.request_slide(ManorRules.S), "actual final room shift starts")
	while main.sliding:
		await process_frame
	c.set_process(false)
	check(main.won and c.phase == ManorConservatory.Phase.WAITING, "assembly waits for player to see the center")
	check(main.coins.collected.is_empty() and main.coins.pending.is_empty(), "direct assembly starts the conservatory without awarding coins")
	check(not main.controls_locked(true), "waiting for reveal leaves walking and looking available")
	main.binoculars.owned = true
	main.stopwatch.owned = true
	check(not main.binoculars.toggle() and not main.stopwatch.toggle(), "item views cannot obscure the reveal")
	check(not main.carpet.visible and not main.ending.active, "assembly does not start the outdoor ending")
	var front: ManorDoor
	for room in main.rooms.values():
		for door in room.doors:
			check(not door.opened and door.gate.collision_layer == 1, "doors stay closed after the last slide")
			if door.is_front:
				front = door
	c._process(20)
	check(c.room == null, "reveal cannot run behind the player's back")
	var before := main.player.position
	main.player.bot_drive = Vector3.RIGHT
	await create_timer(0.25).timeout
	main.player.bot_drive = Vector3.ZERO
	check(main.player.position.x > before.x + 0.3, "player can physically walk around while doors are closed")
	main.player.position = Vector3(0, 0.02, 7.5)
	main.player.aim_at(Vector3(0, 1.4, 0))
	main.coins.collect(0)
	c._process(20)
	check(c.room == null, "queued reward prevents an obscured reveal")
	main.coins.receive_next()
	await physics_frame
	c._process(0.01)
	check(c.phase == ManorConservatory.Phase.RETRACTING and c.room != null, "looking through the center-facing glass starts the reveal")
	if c.room == null:
		quit(1)
		return
	check(cues.count("gap_retract") == 0, "slab stays silent during the door-closing delay")
	c._process(ManorConservatory.CLOSE_TIME + 0.8)
	check(cues.count("gap_retract") == 1 and cues.count("conservatory_rise") == 0, "retraction uses its own muffled cue once motion starts")
	check(c.slab.position.x > 0 and c.slab.position.x < ManorGeometry.PITCH and is_equal_approx(c.room.position.y, ManorConservatory.START_DEPTH), "slab retracts first while room stays underground")
	main.release_pointer()
	var paused := c.slab.position
	c._process(10)
	check(c.slab.position == paused, "pause freezes slab retraction")
	main.resume_play()
	c._process(3)
	check(cues.count("gap_retract") == 1 and cues.count("conservatory_rise") == 1 and cues.count("slide") == 1, "lift uses one creak-free cue while the final room shift keeps its own sound")
	check(c.phase == ManorConservatory.Phase.RISING and not c.slab.visible, "slab clears the opening before room rises")
	await physics_frame
	var ray := PhysicsRayQueryParameters3D.create(Vector3(2.7, 0.1, 1.9), Vector3(2.7, -8, 1.9))
	var below := main.get_world_3d().direct_space_state.intersect_ray(ray)
	check(not below.is_empty() and below.position.y < -5.9, "open shaft has no ground collider above the lowered room floor")
	check(not main.meadow.center_ground.visible and main.meadow.center_collision.collision_layer == 0, "terrain opening removes both grass and its walking collision")
	c._process(2.5)
	check(c.room.position.y > ManorConservatory.START_DEPTH and c.room.position.y < 0 and c.room.key_hit.collision_layer == 0, "rising room and key stay inaccessible")
	check(not c.take_key() and not c.unlock_exit(front), "key and red door reject premature use")
	main.player.position = Vector3(0, 0.02, 4.1)
	main.player.bot_drive = Vector3.FORWARD
	await create_timer(0.7).timeout
	main.player.bot_drive = Vector3.ZERO
	check(main.player.position.z > 3.3 and main.rules.player == 7, "closed glass physically blocks entry into the moving room")
	main.release_pointer()
	var height := c.room.position.y
	c._process(10)
	check(c.room.position.y == height, "pause freezes the rising room")
	main.resume_play()
	c._process(10)
	check(c.accessible() and c.room.position.y == 0 and c.shaft.visible, "room docks flush before access is enabled")
	check(not front.opened and not c.exit_unlocked, "red door still needs the key after the reveal")
	var driver := add_driver(main)
	await driver.walk_to(Vector3(0, 0, 2.35))
	check(main.rules.player == -1 and main.rules.slot() == 4 and main.player.is_on_floor(), "player walks onto the conservatory floor without changing puzzle state")
	main.player.aim_at(c.room.key.global_position)
	await physics_frame
	var hit := main.player.focus()
	check(not hit.is_empty() and hit.collider.has_meta("red_key"), "normal interaction ray reaches the pedestal key")
	check(main.player.begin_interact(), "interact picks up the key")
	c._process(0.3)
	c.accept_reward()
	check(c.collecting and main.controls_locked() and not c.reward_accepted, "pickup locks controls and ignores acceptance before arrival")
	main.release_pointer()
	var key_at := c.room.key.global_position
	c._process(1)
	check(c.room.key.global_position == key_at and not c.room.key.visible, "pause freezes key pickup and hides it behind the menu")
	main.resume_play()
	c._process(1)
	c._process(10)
	check(c.collecting and not c.key_owned and c.pickup_elapsed == ManorConservatory.REWARD_HOLD_AT, "key reveal waits indefinitely for a fresh press")
	check(c.hud.reward_title.visible and c.hud.reward_title.text == "Red Key" and c.hud.reward_hint.text == "To your success", "key shows its reward caption")
	var accept := InputEventKey.new()
	accept.physical_keycode = KEY_SPACE
	accept.pressed = true
	accept.echo = true
	c._input(accept)
	check(not c.reward_accepted, "held key repeats cannot dismiss the reward")
	accept.echo = false
	c._input(accept)
	c._process(1)
	check(c.key_owned and not c.collecting and not c.room.key.visible and not c.take_key(), "inventory receives one red key and pedestal stays empty")
	check(not c.hud.reward_title.visible and not c.hud.reward_hint.visible, "reward captions disappear after collection")
	check(not main.audio.surface() == "step_grass", "conservatory footsteps use the hard floor")
	main.audio._process(0)
	check(not main.audio.birds_on, "conservatory is indoors despite occupying the old gap")
	await driver.walk_to(Vector3(0, 0, 4.8))
	await driver.walk_to(Vector3(1.0, 0, 5.3))
	await driver.walk_to(Vector3(1.0, 0, 7.9))
	await driver.walk_to(Vector3(0, 0, 8.0))
	main.player.aim_at(front.gate.global_position)
	await physics_frame
	check(main.player.begin_interact(), "normal red-door interaction uses the inventory key")
	check(c.unlocking and not c.exit_unlocked and not front.opened and front.keyhole != null and main.controls_locked(), "key turns in the visible lock before the door can open")
	c._process(0.6)
	main.release_pointer()
	var unlock_at := c.room.key.global_transform
	c._process(2)
	check(c.unlock_elapsed == 0.6 and c.room.key.global_transform == unlock_at and not c.room.key.visible, "pause freezes the unlocking animation")
	main.resume_play()
	c._process(ManorConservatory.UNLOCK_TIME)
	check(c.exit_unlocked and front.opened and front.gate.collision_layer == 1, "unlock starts the existing slow door opening")
	check(c.key_owned and not c.unlocking and not c.room.key.visible, "used key stays in inventory after unlocking")
	main.begin_finale()
	check(not main.in_finale, "finale cannot start through the still-opening door")
	check(not c.unlock_exit(front), "repeated interaction cannot restart the unlock")
	await create_timer(ManorDoor.EXIT_OPEN_SECONDS + 0.1).timeout
	main.player.bot_drive = Vector3.BACK
	var timeout := 0.0
	while not main.in_finale and timeout < 2.0:
		await physics_frame
		timeout += 1.0 / Engine.physics_ticks_per_second
	check(main.in_finale and main.ending.active and main.carpet.visible, "walking through the unlocked door starts the finale")
	main.queue_free()
	driver.queue_free()
	await process_frame
	for last_room in [1, 3, 5]:
		await check_other_entrance(last_room)
	finish("Conservatory")

func check_other_entrance(last_room: int) -> void:
	var main := start_manor()
	FIXTURE.prepare(main, last_room)
	main.player.aim_at(ManorGeometry.center(last_room) * 3 + Vector3.UP * 1.4)
	await physics_frame
	var direction := ManorRules.N if last_room == 1 else (ManorRules.W if last_room == 3 else ManorRules.E)
	check(main.request_slide(direction), "room %d completes assembly from center" % last_room)
	while main.sliding:
		await process_frame
	var c := main.conservatory
	c.set_process(false)
	main.player.aim_at(Vector3(0, 1.4, 0))
	await physics_frame
	c._process(0.01)
	check(c.phase == ManorConservatory.Phase.RETRACTING, "room %d has a clear glass view of the reveal" % last_room)
	if c.room == null:
		main.queue_free()
		return
	c._process(4)
	c._process(7)
	# Let the pickup run normally while the driver exercises the real route around the garden.
	c.set_process(true)
	var driver := add_driver(main)
	await driver.collect_red_key()
	check(c.key_owned and main.rules.player == 7, "room %d entrance reaches the key and returns to Foyer" % last_room)
	main.queue_free()
	driver.queue_free()
	await process_frame
