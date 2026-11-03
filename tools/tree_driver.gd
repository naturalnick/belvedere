extends Node

func run(driver: Node) -> void:
	var main: Manor = driver.main
	# Fixed camera locations make this art trial reproducible without a long lawn walk.
	main.player.set_physics_process(false)
	main.player.position = Vector3(0, -0.02, 15)
	main.player.aim_at(Vector3(55, 2.2, 25))
	await driver.shot("02_meadow")
	var nearest: ManorTree
	for tree in main.find_children("*", "ManorTree", true, false):
		if tree.position.x > 24 and tree.position.z > 0:
			if nearest == null or tree.global_position.distance_to(main.player.position) < nearest.global_position.distance_to(main.player.position):
				nearest = tree
	driver._check(nearest != null, "a tree frames the east lawn")
	if nearest == null:
		return
	var toward_house := -nearest.global_position.normalized()
	main.player.position = nearest.global_position + toward_house * 8
	main.player.position.y = -0.02
	main.player.aim_at(nearest.global_position + Vector3.UP * 2.4)
	await driver.shot("03_tree_detail")
	main.player.position = nearest.global_position - toward_house * 6 + Vector3(2, 0, 0)
	main.player.position.y = -0.02
	main.player.aim_at(Vector3(0, 1.5, 0))
	await driver.shot("04_house_and_trees")
	var laundry: ManorRoom = main.rooms[8]
	main.player.position = laundry.position + Vector3(1.0, 0.02, 1.6)
	main.player.aim_at(laundry.position + Vector3(10, 2, 1.6))
	await driver.shot("05_window_view")
