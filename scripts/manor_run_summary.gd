class_name ManorRunSummary
extends Control

const REVEAL_DELAY := 1.0
const FADE_SECONDS := 1.4
var manor: Manor
var totals: Label
var continue_button: ManorInkButton
var continue_shadow: Label
var revealed := false
var ready_to_continue := false
var exiting := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	totals = _label()
	continue_button = ManorInkButton.new()
	continue_button.text = "Continue"
	# Screenshot shortcuts must never activate the ending's button.
	continue_button.focus_mode = Control.FOCUS_NONE
	continue_button.set_colors(Color("F6EEE1"), Color("F3D697"))
	continue_button.pressed.connect(_continue)
	add_child(continue_button)
	# Button does not render Label's font-shadow theme properties.
	continue_shadow = Label.new()
	continue_shadow.text = continue_button.text
	continue_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	continue_shadow.show_behind_parent = true
	continue_shadow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	continue_shadow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	continue_shadow.add_theme_color_override("font_color", ManorEnding.TEXT_SHADOW)
	continue_button.add_child(continue_shadow)
	continue_button.button_down.connect(continue_shadow.hide)
	continue_button.button_up.connect(continue_shadow.show)
	resized.connect(_layout)
	reset()

func _label() -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color("F6EEE1"))
	label.add_theme_color_override("font_shadow_color", ManorEnding.TEXT_SHADOW)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)
	return label

func reveal() -> void:
	var stats := manor.run_stats
	var lines := PackedStringArray(["Shifts %d" % stats.shifts])
	var description := "Shifts %d. " % stats.shifts
	if stats.sleeps > 0:
		lines.append("Sleeps %s" % stats.sleep_count())
		description += "Sleeps %d, including %d falls. " % [stats.sleeps, stats.falls]
	lines.append("Time %s" % stats.time_text())
	totals.text = "\n".join(lines)
	totals.accessibility_name = description + "Time %s." % stats.time_text()
	revealed = true
	modulate.a = 0.0
	show()
	set_process(true)
	_layout()

func arm() -> void:
	ready_to_continue = true
	continue_button.disabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func reset() -> void:
	revealed = false
	ready_to_continue = false
	exiting = false
	continue_button.disabled = true
	hide()
	set_process(false)

func _layout() -> void:
	var margin := clampf(size.x * 0.025, 20, 32)
	var column_width := maxf(0, size.x / 2 - margin - 8)
	var font_size := 18 if size.x < 600 else 22
	totals.add_theme_font_size_override("font_size", font_size)
	totals.size = Vector2(column_width, 0)
	totals.position.y = size.y - margin - totals.size.y
	totals.position.x = margin
	continue_button.add_theme_font_size_override("font_size", font_size)
	continue_button.size = Vector2(minf(140, column_width), 48)
	continue_button.position = size - Vector2.ONE * margin - continue_button.size
	continue_shadow.add_theme_font_override("font", continue_button.get_theme_font("font"))
	continue_shadow.add_theme_font_size_override("font_size", font_size)
	continue_shadow.position = Vector2(0, 1)
	continue_shadow.size = continue_button.size

func _process(_delta: float) -> void:
	visible = revealed and manor.in_finale and not manor.at_title and not manor.play_gate.visible

func _continue() -> void:
	if not ready_to_continue or exiting or not visible or manor.play_gate.visible or manor.at_title:
		return
	ready_to_continue = false
	exiting = true
	continue_button.disabled = true
	manor.finale_motion = manor.create_tween()
	manor.finale_motion.tween_property(manor.fade, "color:a", 1.0, FADE_SECONDS)
	manor.finale_motion.tween_callback(manor.return_to_title)
