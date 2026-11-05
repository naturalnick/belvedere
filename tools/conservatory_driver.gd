extends Node
const FIXTURE = preload("res://tools/conservatory_fixture.gd")

func run(driver: Node) -> void:
	var main: Manor = driver.main
	FIXTURE.prepare(main)
	await get_tree().physics_frame
	main.player.aim_at(main.rooms[7].lever.global_position + Vector3.UP * 0.8)
	await driver.hold_lever_input(ManorRules.S, true)
	driver.release_lever_input(true)
	main.player.aim_at(Vector3(0, 1.4, 12))
	while main.sliding:
		await get_tree().process_frame
	driver._check(main.won, "real last shift assembles the house")
	await driver.collect_red_key(true)
	var content_size := get_window().content_scale_size
	var window_size := get_window().size
	main.binoculars.owned = true
	main.stopwatch.owned = true
	get_window().content_scale_size = Vector2i(360, 640)
	get_window().size = Vector2i(360, 640)
	await get_tree().process_frame
	await driver.shot("red_key_inventory_portrait")
	get_window().content_scale_size = content_size
	get_window().size = window_size
	await driver.walk_to(Vector3(0, 0, 4.8))
	await driver.walk_to(Vector3(1.0, 0, 5.3))
	await driver.walk_to(Vector3(1.0, 0, 7.9))
	await driver.unlock_red_door(true)
	await driver.shot("red_door_unlocked")
