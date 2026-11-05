extends Node

# Fixed views of the seed A house exterior, plus one interior wall to confirm siding stays outside.
const VIEWS := [
	["01_south_facade", Vector3(2, -0.02, 24), Vector3(0, 1.5, 6)],
	["02_southwest_corner", Vector3(-15, -0.02, 16), Vector3(-9.375, 1.4, 9.375)],
	["03_wall_close", Vector3(7.5, -0.02, 13.2), Vector3(6.25, 1.3, 9.375)],
	["04_gap", Vector3(0, 0.02, 8.6), Vector3(0, 1.4, 2.5)],
	["05_north_facade", Vector3(-4, -0.02, -22), Vector3(0, 1.5, 0)],
	["06_east_facade", Vector3(24, -0.02, -3), Vector3(0, 1.5, 0)],
]

func run(driver: Node) -> void:
	var main: Manor = driver.main
	main.player.set_physics_process(false)
	for view in VIEWS:
		main.player.position = view[1]
		main.player.aim_at(view[2])
		await driver.shot(view[0])
	var laundry: ManorRoom = main.rooms[8]
	main.player.position = laundry.position + Vector3(1.0, 0.02, 1.6)
	main.player.aim_at(laundry.position + Vector3(10, 2, 1.6))
	await driver.shot("07_interior_window")
	# Seed A puts Bathroom's north window against Study's door wall, which should stay plain through the glass.
	var bathroom: ManorRoom = main.rooms[1]
	main.player.position = bathroom.position + Vector3(1.2, 0.02, -1.2)
	main.player.aim_at(bathroom.position + Vector3(1.6, 1.6, -3.1))
	await driver.shot("08_window_onto_neighbour")
	for door in main.rooms[7].doors:
		if not door.is_front:
			continue
		for face in [1, -1]:
			main.player.global_position = door.to_global(Vector3(0, 0.02, face * 1.8))
			main.player.aim_at(door.to_global(Vector3(0, 1.4, 0)))
			await driver.shot("09_red_door_inside" if face == 1 else "10_red_door_outside")
