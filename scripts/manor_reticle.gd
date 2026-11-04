extends Control

var player: ManorPlayer
var last_camera := Transform3D()
var last_locked := true
var last_held := false
var initialized := false
var highlighted := false
var last_size := Vector2.ZERO

func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	var locked: bool = player.manor.controls_locked()
	var camera_transform := player.camera.global_transform
	var viewport_size := get_viewport_rect().size
	if initialized and camera_transform == last_camera and locked == last_locked and player.held == last_held and viewport_size == last_size:
		return
	var next_highlight := false
	if not locked:
		if player.held:
			next_highlight = true
		else:
			var hit := player.focus()
			next_highlight = not hit.is_empty() and (hit.collider.has_meta("lever_room") or hit.collider.has_meta("door") or hit.collider.has_meta("coin_device") or hit.collider.has_meta("safe") or hit.collider.has_meta("foundation_hatch"))
	if not initialized or locked != last_locked or next_highlight != highlighted or viewport_size != last_size:
		queue_redraw()
	last_camera = camera_transform
	last_locked = locked
	last_held = player.held
	last_size = viewport_size
	highlighted = next_highlight
	initialized = true

func _draw() -> void:
	if not initialized or last_locked:
		return
	var center := get_viewport_rect().size / 2.0
	draw_circle(center, 2.0, Color("F6EEE1"))
	if highlighted:
		draw_arc(center, 9.0, 0, TAU, 32, Color("C9A04A"), 1.5, true)
