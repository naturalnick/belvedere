class_name ManorShaderWarmup
extends RefCounted
## The Compatibility renderer compiles a shader variant the first time it draws it, which stalls
## the browser's only thread and hitches native builds too. A variant depends on the lights and
## batching at that draw, so each kind of place has to be drawn for real: one frame of each behind
## the opaque opening fade.

const EYE_HEIGHT := 1.65

static var done := false

static func needed(manor: Manor) -> bool:
	return not done and (OS.has_feature("web") or OS.has_feature("windows")) and manor.binoculars != null and manor.ending != null

static func run(manor: Manor) -> void:
	var sketch := _add_hud_sketch(manor)
	# The trophy screen has its own lights, so its variants differ from anything in the house.
	manor.play_gate.trophy_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	# The title view first, while the player's camera is still current. A scene that starts the
	# game resumes from this wait before its first draw, so one frame could skip the view.
	await manor.get_tree().process_frame
	await manor.get_tree().process_frame
	# A separate camera leaves the player, whose position decides the room rules, untouched.
	var camera := Camera3D.new()
	camera.fov = manor.player.camera.fov
	camera.near = manor.player.camera.near
	manor.add_child(camera)
	camera.make_current()
	var foyer := manor.rooms[7].position
	await _draw_from(manor, camera, foyer + Vector3(2.2, EYE_HEIGHT, 2.2), foyer + Vector3(-2.5, 1.2, -2.5))
	await _draw_from(manor, camera, Vector3(0, EYE_HEIGHT, 15), Vector3(0, 1.5, 0))
	await _draw_from(manor, camera, Vector3(0, EYE_HEIGHT, 15), Vector3(55, 2.2, 25))
	manor.binoculars._set_overhead(true)
	await manor.get_tree().process_frame
	manor.binoculars._set_overhead(false)
	camera.make_current()
	_show_finale(manor)
	await _draw_from(manor, camera, Vector3(0, EYE_HEIGHT, 10), Vector3(0, 1.3, 36))
	_hide_finale(manor)
	manor.player.camera.make_current()
	camera.queue_free()
	sketch.queue_free()
	done = true

# The reticle and item icons use 2D drawing variants the menu doesn't. Drawn beneath the fade.
static func _add_hud_sketch(manor: Manor) -> Control:
	var sketch := Control.new()
	sketch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# A Control's drawing is culled to its own rectangle.
	sketch.size = Vector2(64, 64)
	sketch.draw.connect(func() -> void:
		var at := Vector2(40, 40)
		sketch.draw_circle(at, 4, Color.WHITE, true, -1, true)
		sketch.draw_circle(at, 4, Color.WHITE, false, 1.0, true)
		sketch.draw_arc(at, 9, 0, TAU, 16, Color.WHITE, 1.5, true)
		sketch.draw_line(at, at + Vector2.ONE * 9, Color.WHITE, 1.0, true)
		sketch.draw_line(at, at + Vector2.ONE * 9, Color.WHITE)
		sketch.draw_colored_polygon(PackedVector2Array([at, at + Vector2.RIGHT * 9, at + Vector2.ONE * 9]), Color.WHITE)
		sketch.draw_polyline(PackedVector2Array([at, at + Vector2.RIGHT * 9, at + Vector2.ONE * 9]), Color.WHITE, 1.2, true))
	var layer := manor.scene_fade.get_parent()
	layer.add_child(sketch)
	layer.move_child(sketch, 0)
	return sketch

static func _draw_from(manor: Manor, camera: Camera3D, at: Vector3, target: Vector3) -> void:
	camera.look_at_from_position(at, target)
	await manor.get_tree().process_frame

static func _show_finale(manor: Manor) -> void:
	var ending := manor.ending
	manor.carpet.show()
	ending.rainbow.show()
	for label in [ending.title, ending.credit, ending.thanks]:
		label.modulate.a = 1.0
		label.show()
	var flowers := ending.flowers.multimesh
	flowers.set_instance_transform(0, Transform3D(Basis.IDENTITY, Vector3(0, ending.ground_y, 26)))
	flowers.set_instance_color(0, Color.WHITE)
	flowers.visible_instance_count = 1

static func _hide_finale(manor: Manor) -> void:
	var ending := manor.ending
	manor.carpet.hide()
	ending.reset()
	for label in [ending.title, ending.credit, ending.thanks]:
		label.modulate.a = 0.0
