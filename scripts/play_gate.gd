extends Control

var manor: Manor
var mode := "pause"
var primary: Button
var secondary: Button
var sound_button: Button
var title_label: Label
var settings_button: Button
var settings_panel: ManorSettingsPanel
var previous_mode := "pause"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	title_label = Label.new()
	title_label.text = "Shifting Manor"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", Color("EFE4D2"))
	add_child(title_label)
	primary = _icon_button()
	secondary = _icon_button()
	sound_button = _icon_button()
	sound_button.size = Vector2(52, 52)
	sound_button.pressed.connect(_toggle_audio)
	settings_button = _icon_button()
	settings_button.size = Vector2(52, 52)
	settings_button.accessibility_name = "Settings"
	settings_button.pressed.connect(_open_settings)
	settings_panel = ManorSettingsPanel.new()
	settings_panel.preferences = manor.preferences
	add_child(settings_panel)
	settings_panel.closed.connect(_close_settings)
	manor.preferences.changed.connect(func() -> void:
		_update_sound_accessibility()
		queue_redraw())
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
	if mode == "settings":
		return
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
		_play_icon(center + Vector2(0, 70 if mode == "title" else 20), ivory)
	if mode != "victory":
		_sound_icon(sound_button.position + sound_button.size / 2.0, ivory)
		ManorMenuIcons.draw(self, "settings", settings_button.position + settings_button.size / 2.0, ivory)

func _play_icon(center: Vector2, color: Color) -> void:
	draw_circle(center, 35, color, false, 2, true)
	draw_colored_polygon(PackedVector2Array([center + Vector2(-9, -15), center + Vector2(-9, 15), center + Vector2(16, 0)]), color)

func _sound_icon(center: Vector2, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([center + Vector2(-16, -5), center + Vector2(-10, -5), center + Vector2(-2, -12), center + Vector2(-2, 12), center + Vector2(-10, 5), center + Vector2(-16, 5)]), color)
	if AudioServer.is_bus_mute(0):
		draw_line(center + Vector2(5, -7), center + Vector2(16, 7), color, 2, true)
		draw_line(center + Vector2(5, 7), center + Vector2(16, -7), color, 2, true)
	else:
		for radius in [10, 17]:
			draw_arc(center + Vector2(-2, 0), radius, -PI / 3, PI / 3, 16, color, 2, true)

func _toggle_audio() -> void:
	manor.preferences.update("muted", not manor.preferences.muted)

func _update_sound_accessibility() -> void:
	sound_button.accessibility_name = "Turn sound on" if AudioServer.is_bus_mute(0) else "Mute sound"

func _icon_button() -> Button:
	var button := ManorMenuIcons.button(76)
	add_child(button)
	return button

func _open_settings() -> void:
	previous_mode = mode
	mode = "settings"
	_layout()
	settings_panel.open()

func _close_settings() -> void:
	show_mode(previous_mode)
	settings_button.grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and mode == "settings" and event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		_close_settings()
		get_viewport().set_input_as_handled()

func _layout() -> void:
	settings_panel.visible = mode == "settings"
	settings_panel.size = size
	primary.visible = mode != "settings"
	settings_button.visible = mode in ["title", "pause"]
	settings_button.position = Vector2(maxf(8, size.x - 136), maxf(8, size.y - 72))
	primary.position = size / 2.0 + (Vector2(-62, 75) if mode == "victory" else Vector2(0, 70 if mode == "title" else 20)) - primary.size / 2.0
	secondary.position = size / 2.0 + Vector2(62, 75) - secondary.size / 2.0
	secondary.visible = mode == "victory"
	sound_button.visible = mode in ["title", "pause"]
	sound_button.position = Vector2(maxf(8, size.x - 72), maxf(8, size.y - 72))
	title_label.visible = mode == "title"
	title_label.position = Vector2(16, size.y / 2.0 - 36)
	title_label.size = Vector2(maxf(0, size.x - 32), 48)
	title_label.add_theme_font_size_override("font_size", mini(40, maxi(20, int((size.x - 32) / 9.0))))
	_update_sound_accessibility()
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
