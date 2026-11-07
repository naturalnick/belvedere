extends Control

var manor: Manor
var mode := "pause"
var primary: Button
var secondary: Button
var sound_button: Button
var title_label: Label
var sleep_hint: Label
var settings_button: Button
var settings_panel: ManorSettingsPanel
var controls_button: Button
var controls_panel: ManorControlsPanel
var previous_mode := "pause"
var starting := false
const START_FADE_TIME := 0.55
# Wall-menu ink hover: darker than brass so it still reads on the plaster.
const WALL_ACTIVE := Color("85591C")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	title_label = Label.new()
	title_label.text = "Belvedere"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", Color("EFE4D2"))
	add_child(title_label)
	sleep_hint = Label.new()
	sleep_hint.text = "Sleep to reset the rooms.\nKeep your tokens and items."
	sleep_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sleep_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sleep_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sleep_hint.add_theme_color_override("font_color", Color("D2C5AF"))
	add_child(sleep_hint)
	primary = _icon_button()
	secondary = _icon_button()
	controls_button = _icon_button()
	controls_button.text = "Controls"
	controls_button.pressed.connect(_open_controls)
	controls_panel = ManorControlsPanel.new()
	add_child(controls_panel)
	controls_panel.closed.connect(_close_controls)
	sound_button = _icon_button()
	sound_button.size = Vector2(52, 52)
	sound_button.pressed.connect(_toggle_audio)
	settings_button = _icon_button()
	settings_button.size = Vector2(52, 52)
	settings_button.accessibility_name = "Settings"
	settings_button.text = "Settings"
	settings_button.pressed.connect(_open_settings)
	settings_panel = ManorSettingsPanel.new()
	settings_panel.preferences = manor.preferences
	add_child(settings_panel)
	settings_panel.closed.connect(_close_settings)
	manor.preferences.changed.connect(func() -> void:
		_update_sound_accessibility()
		queue_redraw())
	primary.pressed.connect(_activate_primary)
	secondary.pressed.connect(_activate_secondary)
	resized.connect(_layout)
	_layout()

func show_mode(value: String) -> void:
	mode = value
	show()
	_layout()
	ManorInkButton.focus_quietly(secondary if mode == "sleep" else primary)

func _draw() -> void:
	var center := size / 2.0
	var wall_menu := mode == "title" and manor.wall_title != null and manor.at_title
	if not wall_menu:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.10, 0.075, 0.06, 0.97 if mode == "title" else 0.9))
	if mode in ["settings", "controls"]:
		return
	if mode in ["title", "pause"] and manor.wall_title == null:
		for row in 3:
			for col in 3:
				if row == 1 and col == 1:
					continue
				draw_rect(Rect2(center + Vector2((col - 1) * 18 - 7, (row - 1) * 18 - 80), Vector2(14, 14)), Color("C9A04A"))

func _toggle_audio() -> void:
	manor.preferences.update("muted", not manor.preferences.muted)

func _update_sound_accessibility() -> void:
	sound_button.text = "Sound: Off" if AudioServer.is_bus_mute(0) else "Sound: On"
	sound_button.accessibility_name = "Turn sound on" if AudioServer.is_bus_mute(0) else "Mute sound"

func _icon_button() -> ManorInkButton:
	var button := ManorMenuIcons.button(76)
	add_child(button)
	return button

func _open_settings() -> void:
	if starting:
		return
	previous_mode = mode
	mode = "settings"
	_layout()
	settings_panel.open()

func _open_controls() -> void:
	if starting:
		return
	previous_mode = mode
	mode = "controls"
	controls_panel.set_owned(manor.binoculars != null and manor.binoculars.owned, manor.stopwatch != null and manor.stopwatch.owned)
	_layout()
	ManorInkButton.focus_quietly(controls_panel.back)

func _close_controls() -> void:
	show_mode(previous_mode)
	ManorInkButton.focus_quietly(controls_button)

func _close_settings() -> void:
	show_mode(previous_mode)
	ManorInkButton.focus_quietly(settings_button)

func _input(event: InputEvent) -> void:
	ManorInkButton.note_input(event, get_viewport())

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and mode in ["settings", "controls"] and event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		if mode == "controls":
			_close_controls()
		else:
			_close_settings()
		get_viewport().set_input_as_handled()
	elif visible and mode == "sleep" and ManorPlayer.is_pause_press(event):
		if resumes_from(event.physical_keycode):
			manor.resume_play()
		else:
			show_mode("pause")
		get_viewport().set_input_as_handled()
	elif visible and mode == "pause" and ManorPlayer.is_pause_press(event) and resumes_from(event.physical_keycode):
		manor.resume_play()
		get_viewport().set_input_as_handled()

# Browsers never grant pointer lock from Escape (it is not a user-activation key), so on the web
# Escape would hide the menu only for the failed lock to bring it back; P and Resume still work.
func resumes_from(key: Key) -> bool:
	return key != KEY_ESCAPE or not (OS.has_feature("web") or OS.get_cmdline_user_args().has("--web-entry"))

func _layout() -> void:
	controls_panel.visible = mode == "controls"
	controls_panel.size = size
	controls_button.visible = mode in ["title", "pause"]
	settings_panel.visible = mode == "settings"
	settings_panel.size = size
	primary.visible = mode not in ["settings", "controls"]
	settings_button.visible = mode in ["title", "pause"]
	var sleep_prompt := mode == "sleep"
	var wall_menu := mode == "title" and manor.wall_title != null and manor.at_title
	var footer_width := minf(140, (size.x - 48) / 3)
	# On the wall, ink lettering must clear the dark wardrobe edge at the right of the view.
	var footer_inset := maxf(16, size.x * 0.06) if wall_menu else 16.0
	for i in 3:
		var button: ManorInkButton = [controls_button, settings_button, sound_button][i]
		button.size = Vector2(footer_width, 48)
		button.position = Vector2(size.x - footer_inset - (3 - i) * footer_width - (2 - i) * 8, maxf(8, size.y - 64))
		button.add_theme_font_size_override("font_size", 19)
		_ink(button, wall_menu)
	if manor.wall_title != null:
		manor.wall_title.lettering.visible = wall_menu
	var ui_scale := minf(1.0, minf(size.y / 560.0, size.x / 320.0))
	primary.text = "Play" if mode == "title" else "Resume"
	if sleep_prompt:
		primary.text = "Sleep"
	secondary.text = "Cancel" if sleep_prompt else ""
	secondary.size = Vector2(240, 48) * ui_scale
	secondary.add_theme_font_size_override("font_size", int(22 * ui_scale))
	_ink(secondary, false)
	_ink(primary, wall_menu)
	var primary_font := int(32 * ui_scale)
	var primary_center := size / 2.0 + Vector2(0, 70 if mode == "title" else 20)
	if sleep_prompt:
		primary_center = size / 2.0 + Vector2(0, 35) * ui_scale
	if wall_menu:
		var wall := manor.wall_title
		var camera := manor.player.camera
		var at := camera.unproject_position(wall.to_global(ManorWallTitle.PLAY_CENTER))
		var edge := camera.unproject_position(wall.to_global(ManorWallTitle.PLAY_CENTER + Vector3.RIGHT * 0.145))
		# Sized from the wall's projected scale so Play reads as part of the lettering.
		primary_font = int(clampf(at.distance_to(edge) * 1.05, 20, 72))
		primary_center = at
	primary_font = maxi(8, primary_font)
	primary.add_theme_font_size_override("font_size", primary_font)
	primary.size = Vector2(primary.get_theme_font("font").get_string_size(primary.text, HORIZONTAL_ALIGNMENT_LEFT, -1, primary_font).x + primary_font * 2.4, primary_font * 1.6)
	primary.position = primary_center - primary.size / 2.0
	secondary.position = size / 2.0 + Vector2(0, 97) * ui_scale - secondary.size / 2.0
	secondary.visible = sleep_prompt
	sound_button.visible = mode in ["title", "pause"]
	title_label.visible = mode in ["title", "sleep"] and not wall_menu
	title_label.text = "Start over?" if sleep_prompt else "Belvedere"
	title_label.position = Vector2(16, size.y / 2.0 - (125 * ui_scale if sleep_prompt else 36))
	title_label.size = Vector2(maxf(0, size.x - 32), 48)
	title_label.add_theme_font_size_override("font_size", mini(40, maxi(20, int((size.x - 32) / 9.0))))
	sleep_hint.visible = sleep_prompt
	sleep_hint.add_theme_font_size_override("font_size", maxi(16, int(20 * ui_scale)))
	var hint_width := minf(520, size.x - 48)
	sleep_hint.position = Vector2((size.x - hint_width) / 2, size.y / 2 - 65 * ui_scale)
	sleep_hint.size = Vector2(hint_width, 0)
	_update_sound_accessibility()
	primary.accessibility_name = primary.text
	secondary.accessibility_name = secondary.text
	queue_redraw()

func _ink(button: ManorInkButton, on_wall: bool) -> void:
	if on_wall:
		button.set_colors(ManorWallTitle.INK, WALL_ACTIVE)
		button.set_shadow(Color.TRANSPARENT)
	else:
		button.set_colors(Color("EFE4D2"), Color("F3D697"))
		button.set_shadow(Color("30251B"))

func _activate_primary() -> void:
	if starting:
		return
	if mode == "sleep":
		manor.bed_sleep.sleep()
		return
	if mode != "title":
		manor.resume_play()
		return
	starting = true
	primary.disabled = true
	settings_button.disabled = true
	sound_button.disabled = true
	controls_button.disabled = true
	# Pointer lock must begin inside the click, before the visual fade finishes.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var transition := create_tween().set_parallel(true)
	transition.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	transition.tween_property(self, "modulate:a", 0.0, START_FADE_TIME)
	if manor.wall_title != null:
		transition.tween_property(manor.wall_title.lettering, "modulate:a", 0.0, START_FADE_TIME)
	transition.chain().tween_callback(_finish_start)

func _activate_secondary() -> void:
	manor.resume_play()

func _finish_start() -> void:
	if not manor.fresh_title:
		Manor.gesture_start = true
		get_tree().reload_current_scene()
		return
	manor.start_play()
	starting = false
	modulate.a = 1.0
	primary.disabled = false
	settings_button.disabled = false
	sound_button.disabled = false
	controls_button.disabled = false
	if manor.wall_title != null:
		manor.wall_title.lettering.modulate.a = 1.0
