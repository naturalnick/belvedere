extends Control

var manor: Manor
var mode := "pause"
var primary: Button
var secondary: Button

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	primary = _icon_button()
	secondary = _icon_button()
	primary.pressed.connect(_activate_primary)
	secondary.pressed.connect(manor.return_to_title)
	resized.connect(_layout)
	_layout()

func show_mode(value: String) -> void:
	mode = value
	show()
	_layout()
	primary.grab_focus()

func _draw() -> void:
	var center := size / 2.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.10, 0.075, 0.06, 0.97 if mode == "title" else 0.9))
	var brass := Color("C9A04A")
	var ivory := Color("EFE4D2")
	if mode == "victory":
		for i in 7:
			var angle := i * TAU / 7.0 - PI / 2
			draw_circle(center + Vector2(cos(angle), sin(angle)) * 66 + Vector2(0, -45), 10, Color("FFE3A1"))
		draw_polyline(PackedVector2Array([center + Vector2(-22, -45), center + Vector2(-5, -28), center + Vector2(26, -67)]), brass, 6, true)
		_play_icon(center + Vector2(-62, 75), ivory)
		var home := center + Vector2(62, 75)
		draw_circle(home, 35, ivory, false, 2, true)
		draw_polyline(PackedVector2Array([home + Vector2(-16, -2), home + Vector2(0, -16), home + Vector2(16, -2)]), ivory, 3, true)
		draw_rect(Rect2(home + Vector2(-10, -2), Vector2(20, 17)), ivory, false, 3)
	else:
		for row in 3:
			for col in 3:
				if row == 1 and col == 1:
					continue
				draw_rect(Rect2(center + Vector2((col - 1) * 18 - 7, (row - 1) * 18 - 80), Vector2(14, 14)), brass)
		_play_icon(center + Vector2(0, 20), ivory)

func _play_icon(center: Vector2, color: Color) -> void:
	draw_circle(center, 35, color, false, 2, true)
	draw_colored_polygon(PackedVector2Array([center + Vector2(-9, -15), center + Vector2(-9, 15), center + Vector2(16, 0)]), color)

func _icon_button() -> Button:
	var button := Button.new()
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.size = Vector2(76, 76)
	for style in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(style, StyleBoxEmpty.new())
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("C9A04A")
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(38)
	button.add_theme_stylebox_override("focus", focus)
	add_child(button)
	return button

func _layout() -> void:
	primary.position = size / 2.0 + (Vector2(-62, 75) if mode == "victory" else Vector2(0, 20)) - primary.size / 2.0
	secondary.position = size / 2.0 + Vector2(62, 75) - secondary.size / 2.0
	secondary.visible = mode == "victory"
	primary.accessibility_name = "Continue" if mode == "victory" else ("Play" if mode == "title" else "Resume")
	secondary.accessibility_name = "Return to title"
	queue_redraw()

func _activate_primary() -> void:
	if mode == "title":
		# Keep the browser pointer-lock request inside the user gesture across reload.
		Manor.gesture_start = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_tree().reload_current_scene()
	else:
		manor.resume_play()
