extends "res://tests/manor_test.gd"

var cues: Array[String] = []

func count(group: String) -> int:
	return cues.count(group)

class PauseProbe extends Node:
	var sends := 0
	var stream_paused := false:
		set(value):
			sends += 1
			stream_paused = value

func run() -> void:
	create_timer(30).timeout.connect(func() -> void:
		printerr("FAIL: audio tests timed out")
		quit(1))
	var probe := PauseProbe.new()
	for paused in [false, false, true, true, false]:
		ManorAudio.hold(probe, paused)
	check(probe.sends == 2 and not probe.stream_paused, "only pause changes reach a player, since each web unpause restarts its sound")
	probe.free()
	var main := load_manor()
	main.start_play()
	preload("res://tools/furnishing_fixture.gd").place(main, 7)
	main.player.automated = true
	await physics_frame
	await physics_frame
	var audio := main.audio
	audio.cued.connect(func(group: String) -> void: cues.append(group))

	var expected := {"step_tile": 6, "step_grass": 5, "lever_grab": 3, "lever_blocked": 3,
		"door_rattle": 3, "door_open": 2, "door_close": 2, "slide": 3, "gap_retract": 1, "conservatory_rise": 1, "wake": 1, "coin_insert": 2, "coin_acquired": 1, "drawer_unlock": 1, "ui_click": 3, "ui_tap": 3, "bell_clear": 1, "bell_off": 1}
	for group in expected:
		check(audio.streams[group].size() == expected[group], "%s has %d variants" % [group, expected[group]])
	check(absf(audio.streams["gap_retract"][0].get_length() - (ManorConservatory.RETRACT_TIME + 0.2)) < 0.01, "slab sound covers its travel and soft tail")
	check(absf(audio.streams["conservatory_rise"][0].get_length() - (ManorConservatory.RISE_TIME + 0.2)) < 0.01, "lift sound covers the full rise and soft landing")
	check(audio.music.stream.loop and audio.music.bus == "Music", "music loops on the Music bus")
	check(not audio.streams["piano_song"].is_empty() and audio.streams["piano_song"].all(func(song: AudioStream) -> bool: return song.get_length() > 30.0 and song.get_length() < 61.0 and not song.loop), "piano songs run 30-60 s and end instead of looping")
	check(audio.streams["bell_clear"][0].get_length() > 3.0 and audio.streams["bell_off"][0].get_length() > 3.0, "both bell tones keep the recording's natural ring")
	check(audio.song_voice.bus == "Music" and audio.song_voice.get_parent() == main.player_piano, "songs come from the piano on the Music bus")
	check(audio.birds.stream.loop, "forest birds loop")
	check(audio.voices.all(func(voice: AudioStreamPlayer) -> bool: return voice.bus == "Effects") and audio.birds.bus == "Effects", "effects use the Effects bus")
	var layout: AudioBusLayout = load(ProjectSettings.get_setting("audio/buses/default_bus_layout"))
	check(layout != null and layout.get("bus/1/name") == &"Effects" and layout.get("bus/2/name") == &"Music", "volume buses come from the startup layout (runtime buses are silent on the web)")
	check(AudioServer.get_bus_index("Effects") > 0 and AudioServer.get_bus_index("Music") > 0, "volume buses exist")

	var menu_button := ManorInkButton.new()
	root.add_child(menu_button)
	menu_button.pressed.emit()
	check(count(ManorAudio.MENU_CLICK) == 0, "menu click waits until after the press handlers run")
	await process_frame
	check(count(ManorAudio.MENU_CLICK) == 1, "menu buttons click once when pressed")
	menu_button.mouse_entered.emit()
	await process_frame
	check(count(ManorAudio.MENU_CLICK) == 1, "hovering a menu button is silent")
	menu_button.queue_free()
	cues.clear()

	check(audio.music_intro == 0.0 and audio.music.volume_db < -59.0, "music starts silent during its delay")
	main.coins.collect(0)
	check(count("coin_acquired") == 0, "queued coin is silent until received")
	main.coins.receive_next()
	check(count("coin_acquired") == 1, "coin arrival sounds once")
	main.coins.receive_next()
	main.coins.insert_one()
	check(count("coin_acquired") == 1, "empty queue and spending cannot repeat acquisition sound")
	# Surfaces, sampled synchronously so physics cannot reassign occupancy in between.
	var foyer: ManorRoom = main.rooms[7]
	var spawn := main.player.global_position
	check(audio.surface() == "step_tile", "Foyer tiles use hard steps")
	for id: int in main.rooms:
		main.rules.player = id
		main.player.global_position = main.rooms[id].to_global(Vector3(1.5, 0.02, 1.5))
		check(audio.surface() == "step_tile", "every room uses the same indoor steps (room %d)" % id)
	main.rules.player = 0
	for rug_point in [Vector3(-1.75, 0.02, -1.45), Vector3(-1.75, 0.02, 2.2)]:
		main.player.global_position = main.rooms[0].to_global(rug_point)
		check(audio.surface() == "step_tile", "Bedroom rug and boards share the indoor steps")
	main.rules.player = 5
	for z in [-1.4, -0.5, 1.0, 2.5]:
		main.player.global_position = main.rooms[5].to_global(Vector3(-1.86, 0.02, z))
		check(audio.surface() == "step_tile", "Living rug and boards share the indoor steps (z %.1f)" % z)
	main.carpet.visible = true
	main.rules.player = ManorRules.OUTSIDE
	main.player.global_position = Vector3(0, 0, 15)
	check(audio.surface() == "step_tile", "finale carpet uses the same indoor step")
	main.carpet.visible = false
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

	var driver := add_driver(main)
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
	check(absf(audio.music_duck_db) < 0.1, "music duck recovers after the slide")
	check(audio.music_intro > 0 and audio.music_intro < 1, "music fades in slowly despite the early slide")
	await create_timer(ManorAudio.MUSIC_DELAY + ManorAudio.MUSIC_FADE_IN).timeout
	check(absf(audio.music.volume_db) < 0.1, "music reaches its normal level after startup")

	for door in foyer.doors:
		if door.is_front:
			door.rattle()
	check(count("door_rattle") == 1, "locked front door rattles")

	check(not audio.birds_on and count("birds") == 0, "no birds indoors")
	main.rules.player = ManorRules.OUTSIDE
	main.player.global_position = Vector3(0, 0, 30)
	await create_timer(0.3).timeout
	check(audio.birds_on and count("birds") == 1, "birds start outside")
	await create_timer(0.3).timeout
	check(count("birds") == 1, "the birdsong is one continuous bed, not repeated starts")
	main.rules.player = 7
	main.player.global_position = foyer.global_position + Vector3(1.5, 0.02, 1.5)
	await process_frame
	await process_frame
	check(not audio.birds_on, "entering a room silences the birds")

	main.fall_recovery._wake()
	check(count("wake") == 1, "waking beside the bed rustles the bedding")

	main.queue_free()
	await process_frame
	finish("Audio")
