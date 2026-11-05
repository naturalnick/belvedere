class_name ManorFrameRate
extends CanvasLayer

# Static so the readout stays on across the scene reload behind Play.
static var shown := false
var label: Label
var rate := -1

func _ready() -> void:
	layer = 2
	label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = Vector2(24, 22)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color("F6EEE1"))
	label.add_theme_color_override("font_shadow_color", Color("30251B"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(label)
	_apply()

# Must run before the "any key" handlers, so Manor adds this as its last child: _input runs in
# reverse tree order, and a period must not accept a reward or dismiss the ending.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_PERIOD:
		get_viewport().set_input_as_handled()
		shown = not shown
		_apply()

func _apply() -> void:
	visible = shown
	set_process(shown)
	if shown:
		_process(0.0)

func _process(_delta: float) -> void:
	var current := roundi(Engine.get_frames_per_second())
	if current != rate:
		rate = current
		label.text = "%d FPS" % rate
		label.accessibility_name = "%d frames per second" % rate
