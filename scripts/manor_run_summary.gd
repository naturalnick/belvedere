class_name ManorRunSummary
extends Control

const REVEAL_DELAY := 1.0
const FADE_SECONDS := 1.4
var manor: Manor
var totals: Label
var continue_hint: Label
var revealed := false
var ready_to_continue := false
var exiting := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	totals = _label()
	continue_hint = _label()
	continue_hint.text = "Any key to continue"
	continue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	resized.connect(_layout)
	reset()

func _label() -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color("F6EEE1"))
	label.add_theme_color_override("font_shadow_color", Color("30251B"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(label)
	return label

func reveal() -> void:
	var stats := manor.run_stats
	totals.text = "Shifts %d\nSleeps %s\nTime %s" % [stats.shifts, stats.sleep_count(), stats.time_text()]
	totals.accessibility_name = "Shifts %d. Sleeps %d, including %d falls. Time %s." % [stats.shifts, stats.sleeps, stats.falls, stats.time_text()]
	revealed = true
	modulate.a = 0.0
	show()
	set_process(true)
	_layout()

func arm() -> void:
	ready_to_continue = true

func reset() -> void:
	revealed = false
	ready_to_continue = false
	exiting = false
	hide()
	set_process(false)

func _layout() -> void:
	var margin := clampf(size.x * 0.025, 20, 32)
	var column_width := maxf(0, size.x / 2 - margin - 8)
	var font_size := 18 if size.x < 600 else 22
	continue_hint.text = "Any key\nto continue" if size.x < 600 else "Any key to continue"
	for label in [totals, continue_hint]:
		label.add_theme_font_size_override("font_size", font_size)
		label.size = Vector2(column_width, 0)
		label.position.y = size.y - margin - label.size.y
	totals.position.x = margin
	continue_hint.position.x = size.x - margin - column_width

func _process(_delta: float) -> void:
	visible = revealed and manor.in_finale and not manor.at_title and not manor.play_gate.visible

func _input(event: InputEvent) -> void:
	if not ready_to_continue or exiting or not visible or manor.play_gate.visible or manor.at_title:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		ready_to_continue = false
		exiting = true
		manor.finale_motion = manor.create_tween()
		manor.finale_motion.tween_property(manor.fade, "color:a", 1.0, FADE_SECONDS)
		manor.finale_motion.tween_callback(manor.return_to_title)
