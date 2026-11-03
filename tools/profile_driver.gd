extends SceneTree
var output := "res://build/profile.json"
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280, 720)
	Engine.max_fps = 60
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
	var main: Manor = load("res://scenes/manor.tscn").instantiate()
	root.add_child(main)
	main.player.automated = true
	main.player.set_physics_process(false)
	var samples: Array[Dictionary] = []
	for view in ["spawn", "lawn", "bedroom"]:
		if view == "lawn":
			main.player.position = Vector3(0, 0, 15)
			main.player.aim_at(Vector3(55, 2.2, 25))
		elif view == "bedroom":
			main.player.position = main.rooms[0].position + Vector3(0, 0, 2.2)
			main.player.aim_at(main.rooms[0].position + Vector3(0, 1, -1.8))
		await create_timer(2.0).timeout
		var process_ms: Array[float] = []
		var draws := 0
		for frame in 180:
			await process_frame
			var started := Time.get_ticks_usec()
			# Force a rendered frame even when the desktop occludes this test window.
			RenderingServer.force_draw(false)
			process_ms.append((Time.get_ticks_usec() - started) / 1000.0)
			draws += int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		process_ms.sort()
		var item := {"view": view, "median_render_submit_ms": process_ms[process_ms.size() / 2], "p95_render_submit_ms": process_ms[int(process_ms.size() * 0.95)], "draw_calls": draws / float(process_ms.size()), "nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))}
		samples.append(item)
		print(JSON.stringify(item))
	var path := ProjectSettings.globalize_path(output)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(samples, "\t"))
	quit()
