class_name ManorControlsPanel
extends Control

signal closed
const ACTIONS := ["Move", "Look", "Interact", "Pull lever", "Pause", "Binoculars", "Stopwatch"]
const BINDINGS := ["W A S D", "Mouse", "E / Left click", "Click + drag / E + WASD", "Esc / P", "B", "T"]
var rows: Array[Control] = []
var back: Button
var heading: Label
var owned := false
var stopwatch_owned := false

func _ready() -> void:
	heading = _label("Controls")
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(heading)
	for i in ACTIONS.size():
		var row := Control.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(row)
		rows.append(row)
		row.add_child(_label(ACTIONS[i]))
		var binding := _label(BINDINGS[i])
		binding.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(binding)
	back = ManorMenuIcons.button()
	back.text = "Back"
	back.size = Vector2(100, 52)
	back.add_theme_font_size_override("font_size", 22)
	back.pressed.connect(func() -> void: closed.emit())
	add_child(back)
	resized.connect(_layout)
	_layout()

func _label(value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color("EFE4D2"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func set_owned(value: bool, watch_owned: bool = false) -> void:
	owned = value
	stopwatch_owned = watch_owned
	_layout()

func _layout() -> void:
	var width_value := minf(430, size.x - 48)
	var count := 5 + int(owned) + int(stopwatch_owned)
	var spacing := minf(42, (size.y - 120) / (count + 1))
	var top := (size.y - (count + 2) * spacing) / 2
	heading.position = Vector2((size.x - width_value) / 2, top)
	heading.size = Vector2(width_value, 32)
	var visible_index := 0
	for i in rows.size():
		var row := rows[i]
		row.visible = i < 5 or (i == 5 and owned) or (i == 6 and stopwatch_owned)
		if not row.visible:
			continue
		row.position = Vector2((size.x - width_value) / 2, top + (visible_index + 1) * spacing)
		visible_index += 1
		row.size = Vector2(width_value, 32)
		row.get_child(0).size = Vector2(width_value * 0.30, 32)
		row.get_child(1).position.x = width_value * 0.30
		row.get_child(1).size = Vector2(width_value * 0.70, 32)
	back.position = Vector2(size.x / 2 - 50, top + (count + 1) * spacing)
