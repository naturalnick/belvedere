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
var trophy_view: TextureRect
var trophy_viewport: SubViewport
var play_radius := 35.0
var starting := false
const START_FADE_TIME := 0.55

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	title_label = Label.new()
	title_label.text = "Belvedere"
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
	_build_trophy_view()
	resized.connect(_layout)
	_layout()

func show_mode(value: String) -> void:
	mode = value
	show()
	_layout()
	primary.grab_focus()

func _draw() -> void:
	var center := size / 2.0
	var wall_menu := mode == "title" and manor.wall_title != null and manor.at_title
	if not wall_menu:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.10, 0.075, 0.06, 0.97 if mode == "title" else 0.9))
	if mode == "settings":
		return
	var brass := Color("C9A04A")
	var ivory := Color("EFE4D2")
	if mode != "victory":
		if manor.wall_title == null:
			for row in 3:
				for col in 3:
					if row == 1 and col == 1:
						continue
					draw_rect(Rect2(center + Vector2((col - 1) * 18 - 7, (row - 1) * 18 - 80), Vector2(14, 14)), brass)
		_play_icon(primary.position + primary.size / 2, ManorWallTitle.INK if wall_menu else ivory)
		_sound_icon(sound_button.position + sound_button.size / 2.0, ivory)
		ManorMenuIcons.draw(self, "settings", settings_button.position + settings_button.size / 2.0, ivory)

func _play_icon(center: Vector2, color: Color) -> void:
	draw_circle(center, play_radius, color, false, 2, true)
	draw_colored_polygon(PackedVector2Array([center + Vector2(-9, -15) * play_radius / 35, center + Vector2(-9, 15) * play_radius / 35, center + Vector2(16, 0) * play_radius / 35]), color)

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
	if starting:
		return
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
	var won := mode == "victory"
	var wall_menu := mode == "title" and manor.wall_title != null and manor.at_title
	if manor.wall_title != null:
		manor.wall_title.lettering.visible = wall_menu
	play_radius = 35.0
	var ui_scale := minf(1.0, minf(size.y / 560.0, size.x / 320.0))
	primary.text = "Keep Playing" if won else ""
	secondary.text = "Quit to Menu" if won else ""
	primary.size = Vector2(240, 48) * ui_scale if won else Vector2(76, 76)
	secondary.size = Vector2(240, 48) * ui_scale
	for button in [primary, secondary]:
		button.add_theme_font_size_override("font_size", int(22 * ui_scale))
		button.add_theme_color_override("font_color", Color("EFE4D2"))
		button.add_theme_color_override("font_hover_color", Color("F3D697"))
	primary.position = size / 2.0 + (Vector2(0, 130) * ui_scale if won else Vector2(0, 70 if mode == "title" else 20)) - primary.size / 2.0
	if wall_menu:
		var wall := manor.wall_title
		var camera := manor.player.camera
		var at := camera.unproject_position(wall.to_global(ManorWallTitle.PLAY_CENTER))
		var edge := camera.unproject_position(wall.to_global(ManorWallTitle.PLAY_CENTER + Vector3.RIGHT * 0.145))
		play_radius = maxf(18, at.distance_to(edge))
		primary.size = Vector2.ONE * (play_radius * 2 + 8)
		primary.position = at - primary.size / 2
	secondary.position = size / 2.0 + Vector2(0, 188) * ui_scale - secondary.size / 2.0
	secondary.visible = mode == "victory"
	sound_button.visible = mode in ["title", "pause"]
	sound_button.position = Vector2(maxf(8, size.x - 72), maxf(8, size.y - 72))
	title_label.visible = mode in ["title", "victory"] and not wall_menu
	title_label.text = "Thanks for Playing" if won else "Belvedere"
	title_label.position = Vector2(16, size.y / 2.0 - (218 * ui_scale if won else 36))
	title_label.size = Vector2(maxf(0, size.x - 32), 48)
	title_label.add_theme_font_size_override("font_size", int(32 * ui_scale) if won else mini(40, maxi(20, int((size.x - 32) / 9.0))))
	trophy_view.visible = won
	trophy_view.size = Vector2.ONE * 280 * ui_scale
	trophy_view.position = size / 2.0 + Vector2(-140, -170) * ui_scale
	trophy_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE if won else SubViewport.UPDATE_DISABLED
	_update_sound_accessibility()
	primary.accessibility_name = "Keep Playing" if won else ("Play" if mode == "title" else "Resume")
	secondary.accessibility_name = "Quit to Menu"
	queue_redraw()

func _build_trophy_view() -> void:
	trophy_viewport = SubViewport.new()
	trophy_viewport.size = Vector2i(512, 512)
	trophy_viewport.own_world_3d = true
	trophy_viewport.transparent_bg = true
	trophy_viewport.msaa_3d = Viewport.MSAA_4X
	trophy_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(trophy_viewport)
	var stage := Node3D.new()
	trophy_viewport.add_child(stage)
	ManorPrizeArt.trophy(stage)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_CLEAR_COLOR
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("FFF0DA")
	world.environment.ambient_light_energy = 0.7
	stage.add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -25, 0)
	stage.add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 0.74
	stage.add_child(camera)
	camera.position = Vector3(0.65, 0.65, 2)
	camera.look_at(Vector3(0, 0.24, 0))
	trophy_view = TextureRect.new()
	trophy_view.texture = trophy_viewport.get_texture()
	trophy_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	trophy_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(trophy_view)

func _activate_primary() -> void:
	if starting:
		return
	if mode != "title":
		manor.resume_play()
		return
	starting = true
	primary.disabled = true
	settings_button.disabled = true
	sound_button.disabled = true
	# Pointer lock must begin inside the click, before the visual fade finishes.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var transition := create_tween().set_parallel(true)
	transition.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	transition.tween_property(self, "modulate:a", 0.0, START_FADE_TIME)
	if manor.wall_title != null:
		transition.tween_property(manor.wall_title.lettering, "modulate:a", 0.0, START_FADE_TIME)
	transition.chain().tween_callback(_finish_start)

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
	if manor.wall_title != null:
		manor.wall_title.lettering.modulate.a = 1.0
