class_name ManorSettingsPanel
extends Control

signal closed
const ROWS := ["fov", "sensitivity", "invert_y", "camera_shake", "master", "effects", "music"]
var preferences: ManorPreferences
var sliders: Dictionary[String, HSlider] = {}
var toggles: Dictionary[String, Button] = {}
var back: Button
var syncing := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	for key in ROWS:
		if key in ["invert_y", "camera_shake"]:
			var toggle := ManorMenuIcons.button(48)
			toggle.size.x = 80
			toggle.toggle_mode = true
			toggle.accessibility_name = "Invert vertical mouse look" if key == "invert_y" else "Camera shake"
			toggle.toggled.connect(func(value: bool) -> void:
				if not syncing:
					preferences.update(key, value))
			add_child(toggle)
			toggles[key] = toggle
		else:
			var slider := HSlider.new()
			slider.min_value = 60 if key == "fov" else (0.0005 if key == "sensitivity" else 0.0)
			slider.max_value = 100 if key == "fov" else (0.006 if key == "sensitivity" else 1.0)
			slider.step = 1 if key == "fov" else (0.0001 if key == "sensitivity" else 0.01)
			slider.accessibility_name = {"fov": "Field of view", "sensitivity": "Mouse sensitivity", "master": "Master volume", "effects": "Effects volume", "music": "Music volume"}[key]
			slider.value_changed.connect(func(value: float) -> void:
				if not syncing:
					preferences.update(key, value))
			add_child(slider)
			sliders[key] = slider
	back = ManorMenuIcons.button()
	back.accessibility_name = "Back"
	back.pressed.connect(func() -> void: closed.emit())
	add_child(back)
	resized.connect(_layout)
	preferences.changed.connect(sync)
	_layout()
	sync()

func sync() -> void:
	syncing = true
	for key in sliders:
		sliders[key].value = preferences.get(key)
	for key in toggles:
		toggles[key].button_pressed = preferences.get(key)
	syncing = false
	queue_redraw()

func open() -> void:
	show()
	sync()
	sliders["fov"].grab_focus()

func _layout() -> void:
	var width_value := minf(400, size.x - 48)
	var x := (size.x - width_value) / 2
	var spacing := minf(52, (size.y - 90) / 8)
	var top := (size.y - spacing * 8) / 2
	for i in ROWS.size():
		var key: String = ROWS[i]
		var at := Vector2(x + 64, top + i * spacing)
		if sliders.has(key):
			sliders[key].position = at
			sliders[key].size = Vector2(width_value - 64, 40)
		else:
			toggles[key].position = at + Vector2(width_value - 144, -4)
	back.position = Vector2(size.x / 2 - 26, top + spacing * 7)
	queue_redraw()

func _draw() -> void:
	var color := Color("EFE4D2")
	for key in ROWS:
		var control: Control = sliders[key] if sliders.has(key) else toggles[key]
		var x := (size.x - minf(400, size.x - 48)) / 2 + 22
		ManorMenuIcons.draw(self, key, Vector2(x, control.position.y + (20 if sliders.has(key) else 24)), color)
		if toggles.has(key):
			var at := control.position + Vector2(40, 24)
			var on: bool = preferences.get(key)
			draw_style_box(_toggle_track(on), Rect2(at - Vector2(27, 12), Vector2(54, 24)))
			draw_circle(at + Vector2(15 if on else -15, 0), 8, color)
	ManorMenuIcons.draw(self, "back", back.position + back.size / 2, color)

func _toggle_track(on: bool) -> StyleBoxFlat:
	var track := StyleBoxFlat.new()
	track.bg_color = Color("897246") if on else Color("4D4840")
	track.set_corner_radius_all(12)
	return track
