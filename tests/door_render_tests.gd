extends SceneTree
var output := "res://screenshots/door-fix"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			output = arg.trim_prefix("--shots=")
	output = ProjectSettings.globalize_path(output)
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(960, 540)
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("CCD6D5")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.8
	world.add_child(env)
	var door := ManorDoor.new()
	world.add_child(door)
	door.build("3F6B4F")
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.fov = 75
	camera.near = 0.01
	camera.make_current()
	var failures := 0
	for side in [1, -1]:
		camera.position = Vector3(-0.3, 1.65, side * 0.35)
		camera.look_at(Vector3(-0.3, 1.65, 0))
		await create_timer(0.15).timeout
		await RenderingServer.frame_post_draw
		var picture := root.get_texture().get_image()
		if picture.get_size() != Vector2i(960, 540):
			printerr("FAIL: pixel regression requires a 960 x 540 render")
			quit(1)
			return
		var path := output.path_join("01_front.png" if side == 1 else "02_back.png")
		if picture.save_png(path) != OK:
			failures += 1
		var ink := detached_ink(picture)
		print("Door %s: %d detached rail pixels" % ["front" if side == 1 else "back", ink])
		if ink > 8:
			failures += 1
			printerr("FAIL: expanded outlines float above/below the rail")
	camera.position = Vector3(-0.17, 1.65, 0.35)
	camera.look_at(Vector3(-0.3, 1.65, 0))
	await create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(output.path_join("03_angled.png")) != OK:
		failures += 1
	world.queue_free()
	await process_frame
	print("Door render: %d failures" % failures)
	quit(1 if failures else 0)

func detached_ink(picture: Image) -> int:
	var ink := 0
	# Fixed eye-level camera: these glass bands are beyond the rail's projected bounds.
	for band in [Vector2i(232, 243), Vector2i(324, 338)]:
		for y in range(band.x, band.y):
			for x in range(570, 665):
				var color := picture.get_pixel(x, y)
				if color.r < 0.30 and color.g < 0.23 and color.b < 0.20:
					ink += 1
	return ink
