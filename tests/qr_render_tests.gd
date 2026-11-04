extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(640, 360)
	var world := Node3D.new()
	root.add_child(world)
	var environment := WorldEnvironment.new()
	var sky := Environment.new()
	sky.background_mode = Environment.BG_COLOR
	sky.background_color = Color("6688AA")
	environment.environment = sky
	world.add_child(environment)
	var island := ManorIsland.new()
	world.add_child(island)
	island.build(-0.04)
	var camera := Camera3D.new()
	camera.near = 0.05
	camera.fov = 75
	world.add_child(camera)
	camera.make_current()
	var failures := 0
	var worst := -1.0
	DirAccess.make_dir_recursive_absolute("res://review/qr-flicker")
	for depth in [180.0, 400.0, 800.0, 1400.0]:
		for offset in [0.0, 0.3]:
			camera.position = Vector3(offset, -depth, 125 + offset)
			camera.look_at(Vector3(0, -ManorIsland.DEPTH, 0), Vector3.UP)
			island.layers = 1
			await process_frame
			RenderingServer.force_draw(false)
			var actual := root.get_texture().get_image()
			# Hide only the casing, preserving the exact QR projection as the reference.
			island.layers = 0
			await process_frame
			RenderingServer.force_draw(false)
			var reference := root.get_texture().get_image()
			var white := 0
			var missing := 0
			for y in reference.get_height():
				for x in reference.get_width():
					var expected := reference.get_pixel(x, y)
					if expected.r > 0.7 and expected.g > 0.7:
						white += 1
						if actual.get_pixel(x, y).r < 0.4:
							missing += 1
			var loss := float(missing) / maxi(white, 1)
			print("QR at %.1f m, offset %.1f: %d/%d white pixels obscured (%.2f%%)" % [depth, offset, missing, white, loss * 100])
			if loss > worst:
				worst = loss
				actual.save_png("res://review/qr-flicker/actual.png")
				reference.save_png("res://review/qr-flicker/reference.png")
			if white == 0 or loss > 0.005:
				failures += 1
	print("QR rendering: %d failures; worst obscured area %.2f%%" % [failures, worst * 100])
	world.queue_free()
	await process_frame
	quit(1 if failures else 0)
