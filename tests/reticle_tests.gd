extends "res://tests/manor_test.gd"
class CountingPlayer extends ManorPlayer:
	var queries := 0
	func focus() -> Dictionary:
		queries += 1
		return super.focus()

func run() -> void:
	var main := load_manor()
	main.start_play()
	var player := CountingPlayer.new()
	player.manor = main
	player.automated = true
	main.add_child(player)
	player.set_physics_process(false)
	player.global_transform = main.player.global_transform
	var reticle: Control = load("res://scripts/manor_reticle.gd").new()
	reticle.player = player
	root.add_child(reticle)
	await process_frame
	await process_frame
	var before := player.queries
	for i in 30:
		await process_frame
	check(player.queries == before and before == 1, "stationary reticle reuses focus without repeated physics rays")
	player.rotation.y += 0.2
	await process_frame
	await process_frame
	check(player.queries == before + 1, "camera movement refreshes interaction focus")
	main.sliding = true
	await process_frame
	await process_frame
	check(reticle.last_locked, "reticle hides when slide locks controls")
	main.sliding = false
	await process_frame
	await process_frame
	check(player.queries == before + 2 and not reticle.last_locked, "unlock refreshes focus even with unchanged camera")
	reticle.queue_free()
	main.queue_free()
	await process_frame
	finish("Reticle")
