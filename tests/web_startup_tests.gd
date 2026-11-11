extends "res://tests/manor_test.gd"

func run() -> void:
	create_timer(30).timeout.connect(func() -> void:
		printerr("FAIL: web startup tests timed out")
		quit(1))
	var main := load_manor()
	check(not ManorShaderWarmup.needed(main), "native and headless runs skip the warm-up")
	await process_frame

	var theme := main.audio.music.stream
	var slide: AudioStream = main.audio.streams["slide"][0]
	var player_before := main.player.global_transform
	var occupant_before := main.rules.player
	var cameras_before := main.find_children("*", "Camera3D", true, false).size()

	await ManorShaderWarmup.run(main)
	check(ManorShaderWarmup.done and not ManorShaderWarmup.needed(main), "the warm-up runs once")
	await process_frame
	check(main.player.camera.is_current(), "the warm-up returns to the player's camera")
	check(main.find_children("*", "Camera3D", true, false).size() == cameras_before, "its temporary camera is gone")
	check(main.player.global_transform == player_before and main.rules.player == occupant_before, "the player is not moved")
	check(not main.binoculars.overhead, "the overview is off")
	for room in main.rooms.values():
		check(room.ceiling.visible and not room.overview_roof.visible and not room.overview_edges.visible, "room %d keeps its first-person view" % room.room_id)
	for clue in main.fruit_clues:
		check(clue.visible, "fruit clues return")
	var ending := main.ending
	check(not main.carpet.visible and not ending.rainbow.visible and not ending.active, "the finale stays hidden")
	for label in [ending.title, ending.credit, ending.music_credit, ending.thanks]:
		check(not label.visible and label.modulate.a == 0.0, "finale lettering waits for the ending")
	check(ending.flowers.multimesh.visible_instance_count == 0 and ending.spawned == 0, "no flower is left behind")

	# The Play reload builds a new scene; decoded web audio must not be thrown away with the old one.
	main.free()
	await process_frame
	var again := load_manor()
	check(again.audio.music.stream == theme and again.audio.streams["slide"][0] == slide, "audio streams survive a scene reload")
	await process_frame
	finish("Web startup")
