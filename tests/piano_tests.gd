extends "res://tests/manor_test.gd"

const FIXTURE = preload("res://tools/furnishing_fixture.gd")

func run() -> void:
	create_timer(40).timeout.connect(func() -> void:
		printerr("FAIL: piano tests timed out")
		quit(1))
	var main := start_manor()
	var cues: Array[String] = []
	main.audio.cued.connect(func(group: String) -> void: cues.append(group))
	var piano := main.player_piano
	var audio := main.audio
	var driver := add_driver(main)
	FIXTURE.place(main, 5)
	await physics_frame
	var furniture := main.rooms[5].get_node("Furnishings")
	check(piano.get_parent() == main.rooms[5] and not furniture.is_ancestor_of(piano), "the piano belongs to the Living room, outside its static furniture")
	check(is_equal_approx(piano.to_global(Vector3(0, 0, -ManorPianoArt.DEPTH / 2)).z, main.rooms[5].to_global(Vector3(0, 0, -3.0)).z), "the piano's back meets the north wall")
	await driver.walk_to(main.rooms[5].position + Vector3(1.85, 0, -1.4))
	main.player.aim_at(piano.to_global(ManorPianoArt.SLOT_POSITION))
	await physics_frame
	var hit := main.player.focus()
	check(not hit.is_empty() and hit.collider.has_meta("piano"), "the coin slot is reachable through the interaction ray")
	var start_music_db := audio.song_duck_db
	check(main.player.begin_interact() and cues.has("lever_blocked") and not audio.song_playing(), "with no coin and nothing paid for, the mechanism just catches")
	main.player.release_interact()
	cues.clear()
	main.coins.collect(0)
	receive_coin(main)
	main.coins.collect(1)
	receive_coin(main)
	check(main.coins.available == 2, "fixture holds two coins")
	check(main.player.begin_interact() and piano.busy and main.coins.inserted == 1 and main.coins.available == 1, "one press spends exactly one coin")
	check(not main.player.begin_interact(), "a second press cannot overlap an insertion")
	main.player.release_interact()
	for piece in piano.token.find_children("*", "MeshInstance3D", true, false):
		check(piece.material_override is ShaderMaterial, "the slot coin compiles no shader of its own on first insert")
	main.release_pointer()
	await create_timer(1.0).timeout
	check(piano.busy and cues.count("coin_insert") == 0 and not audio.song_playing(), "pausing an insertion suspends its clink and song")
	main.resume_play()
	await create_timer(1.0).timeout
	check(cues.count("coin_insert") == 1 and not piano.busy and audio.song_playing() and cues.count("piano_song") == 1, "the insertion clinks once and then the song starts")
	check(piano.art.playing, "the keys move while the song plays")
	await create_timer(2.4).timeout
	check(audio.song_duck_db < -40.0 and audio.music.volume_db < -40.0, "the main theme fades out under a song")
	main.release_pointer()
	await process_frame
	await process_frame
	check(not piano.art.playing, "the keys stop while paused")
	main.resume_play()
	await process_frame
	await process_frame
	check(piano.art.playing, "the keys resume with play")
	# Riding a shift keeps the song with the room.
	var at := piano.global_position
	check(main.request_slide(ManorRules.E), "the Living room shifts while a song plays")
	while main.sliding:
		await process_frame
	check(piano.global_position.is_equal_approx(at + Vector3.RIGHT * ManorGeometry.PITCH) and audio.song_playing() and audio.song_voice.global_position.is_equal_approx(piano.to_global(Vector3.UP)), "the song rides along with the piano")
	cues.clear()
	audio.music.finished.emit()
	audio.music_rest.custom_step(ManorAudio.MUSIC_REST + 0.1)
	check(not cues.has("theme"), "a theme due during a song waits for it")
	audio.end_song()
	check(not audio.song_playing(), "a finished song ends")
	check(cues.count("theme") == 1, "the waiting theme starts once the song ends")
	await create_timer(3.2).timeout
	check(absf(audio.song_duck_db) < 0.1, "the main theme returns after a song")
	await process_frame
	check(not piano.art.playing, "the keys rest once the song ends")
	# A second coin plays the next song even if one is already going.
	await driver.walk_to(piano.global_position + piano.global_basis.z * 1.3 + Vector3.UP * 0.02)
	main.player.aim_at(piano.to_global(ManorPianoArt.SLOT_POSITION))
	await physics_frame
	cues.clear()
	check(main.player.begin_interact() and main.coins.inserted == 2 and main.coins.available == 0, "the second coin goes in")
	main.player.release_interact()
	while piano.busy:
		await process_frame
	check(audio.song_playing() and cues.count("piano_song") == 1, "the second coin plays its song")
	check(not main.player.begin_interact() and cues.count("piano_song") == 1, "with no coins left, pressing during a song changes nothing")
	main.player.release_interact()
	audio.end_song()
	# Spent coins pay for free replays, cycling through what has been unlocked.
	var replays: Array[int] = [piano.next_replay]
	check(main.player.begin_interact() and audio.song_playing() and main.coins.inserted == 2, "with no coins in hand, pressing replays an unlocked song for free")
	main.player.release_interact()
	replays.append(piano.next_replay)
	check(replays == [0, 1], "replays move on to the next unlocked song")
	main.fall_recovery._wake()
	check(audio.song_playing(), "falling back to the Bedroom doesn't stop a song")
	main.ending.reset()
	audio.end_song()
	main.queue_free()
	driver.queue_free()
	await process_frame
	finish("Piano")
