extends Control

var manor: Manor

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	resized.connect(queue_redraw)

func _draw() -> void:
	var center := size / 2.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.10, 0.075, 0.06, 0.82))
	for row in 3:
		for col in 3:
			if row == 1 and col == 1:
				continue
			draw_rect(Rect2(center + Vector2((col - 1) * 18 - 7, (row - 1) * 18 - 80), Vector2(14, 14)), Color("C9A04A"))
	draw_circle(center + Vector2(0, 20), 35, Color("EFE4D2"), false, 2, true)
	draw_colored_polygon(PackedVector2Array([center + Vector2(-9, 5), center + Vector2(-9, 35), center + Vector2(16, 20)]), Color("EFE4D2"))

func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		# Browser pointer lock must be requested synchronously inside the gesture.
		manor.resume_play()
		accept_event()
