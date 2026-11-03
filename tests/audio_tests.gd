extends SceneTree

var checks := 0
var failures := 0
var cues: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func count(group: String) -> int:
	return cues.count(group)

func run() -> void:
	create_timer(30).timeout.connect(func() -> void:
		printerr("FAIL: audio tests timed out")
		quit(1))
	var main: Manor = load("res://scenes/manor.tscn").instantiate()
	root.add_child(main)
	main.player.automated = true
	await physics_frame
	await physics_frame
	var audio := main.audio
	audio.cued.connect(func(group: String) -> void: cues.append(group))

	var expected := {"step_wood": 5, "step_tile": 6, "step_grass": 5, "step_carpet": 3, "lever_grab": 3, "lever_blocked": 3,
		"door_rattle": 3, "door_open": 2, "door_close": 2, "slide": 3, "birds": 4, "wake": 1}
	for group in expected:
		check(audio.streams[group].size() == expected[group], "%s has %d variants" % [group, expected[group]])
	check(audio.music.stream.loop and audio.music.bus == "Music", "music loops on the Music bus")
	check(audio.voices.all(func(voice: AudioStreamPlayer) -> bool: return voice.bus == "Effects") and audio.birds.bus == "Effects", "effects use the Effects bus")
	check(AudioServer.get_bus_index("Effects") > 0 and AudioServer.get_bus_index("Music") > 0, "volume buses exist")

	# Surfaces, sampled synchronously so physics cannot reassign occupancy in between.
	var foyer: ManorRoom = main.rooms[7]
	var spawn := main.player.global_position
	check(audio.surface() == "step_tile", "Foyer tiles use hard steps")
	main.rules.player = 0
	main.player.global_position = main.rooms[0].to_global(Vector3(1.5, 0.02, 1.5))
	check(audio.surface() == "step_wood", "Bedroom boards use wood steps")
	main.player.global_position = main.rooms[0].to_global(Vector3(-1.75, 0.02, -1.45))
	check(audio.surface() == "step_carpet", "Bedroom rug muffles steps")
	main.rules.player = -1
	main.player.global_position = ManorGeometry.center(7)
	check(audio.surface() == "step_tile", "gap slab uses hard steps")
	main.rules.player = ManorRules.OUTSIDE
	main.player.global_position = Vector3(0, 0, 30)
	check(audio.surface() == "step_grass", "lawn uses grass steps")
	main.rules.player = 7
	main.player.global_position = spawn

	main.player.bot_drive = Vector3.BACK
	await create_timer(0.8).timeout
	main.player.bot_drive = Vector3.ZERO
	var steps := cues.filter(func(group: String) -> bool: return group.begins_with("step_"))
	check(steps.size() >= 1 and steps.size() <= 3, "walking ~2.4 m gives a step every ~1 m (%d)" % steps.size())
	check(steps.all(func(group: String) -> bool: return group == "step_tile"), "Foyer steps stay on tile")
	cues.clear()
	await create_timer(0.3).timeout
	check(cues.is_empty(), "standing still is silent")

	var driver: Node = load("res://tools/demo_driver.gd").new()
	root.add_child(driver)
	driver.main = main
	driver.started = Time.get_ticks_msec()
	await driver.approach_lever(foyer)
	cues.clear()
	main.player.aim_at(foyer.lever.global_position + Vector3.UP * 0.8)
	check(main.player.begin_interact() and count("lever_grab") == 1, "grabbing the lever clicks")
	main.player.select_pull(ManorRules.N)
	main.player.release_interact()
	check(count("lever_blocked") == 1 and not main.sliding, "a blocked pull clunks")
	main.player.begin_interact()
	main.player.release_interact()
	check(count("lever_grab") == 3 and count("lever_blocked") == 1, "releasing without a pull returns quietly")

	var swings := {true: 0, false: 0}
	for id in main.rooms:
		for door in main.rooms[id].doors:
			door.swung.connect(func(opening: bool) -> void: swings[opening] += 1)
	cues.clear()
	main.player.begin_interact()
	main.player.select_pull(ManorRules.E)
	main.player.release_interact()
	check(main.sliding and count("slide") == 1, "a slide plays the room movement")
	await create_timer(0.5).timeout
	check(audio.music.volume_db < -3.0, "music ducks under the slide")
	check(swings[false] >= 1 and count("door_close") == 1, "closing doors voice one latch (%d swung)" % swings[false])
	while main.sliding:
		await process_frame
	await process_frame
	check(swings[true] > 1 and count("door_open") == 1, "reopening doors voice only the nearest (%d swung)" % swings[true])
	await create_timer(1.6).timeout
	check(absf(audio.music.volume_db) < 0.1, "music recovers after the slide")

	for door in foyer.doors:
		if door.is_front:
			door.rattle()
	check(count("door_rattle") == 1, "locked front door rattles")

	main.rules.player = ManorRules.OUTSIDE
	main.player.global_position = Vector3(0, 0, 30)
	audio.bird_wait = 0.05
	await create_timer(0.3).timeout
	check(count("birds") == 1, "birds call outside")
	main.rules.player = 7
	main.player.global_position = foyer.global_position + Vector3(1.5, 0.02, 1.5)
	await process_frame
	var calls := count("birds")
	audio.bird_wait = 0.0
	await create_timer(0.5).timeout
	check(count("birds") == calls and audio.bird_wait >= 1.0, "no birds indoors")

	main.fall_recovery._wake()
	check(count("wake") == 1, "waking beside the bed rustles the bedding")

	main.queue_free()
	await process_frame
	print("Audio: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
