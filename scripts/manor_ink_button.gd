class_name ManorInkButton
extends Button

# Menu buttons are plain lettering: hover and keyboard focus tint the word;
# pressing sets it down slightly without its shadow.
signal marked_changed
const PRESS_DROP := 2.0
var _shadow := Color.TRANSPARENT
var _normal := Color.WHITE
var _active := Color.WHITE
# Focus is marked only while the keyboard is in use, so a pointer hover and a
# stale focus never mark two buttons at once.
static var keyboard_nav := false

static func click(from: Node) -> void:
	from.get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED, "menu_audio", "menu_click")

static func focus_quietly(control: Control) -> void:
	control.grab_focus(not keyboard_nav)

static func note_input(event: InputEvent, viewport: Viewport) -> void:
	var keyboard := keyboard_nav
	if event is InputEventKey or event is InputEventJoypadButton:
		keyboard = true
	elif event is InputEventMouse:
		keyboard = false
	if keyboard == keyboard_nav:
		return
	keyboard_nav = keyboard
	var owner := viewport.gui_get_focus_owner()
	if owner is ManorInkButton:
		owner._refresh_focus()

func _init() -> void:
	set_colors(Color("EFE4D2"), Color("F3D697"))
	action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for style in ["normal", "hover", "disabled", "focus"]:
		add_theme_stylebox_override(style, StyleBoxEmpty.new())
	for style in ["pressed", "hover_pressed"]:
		var lowered := StyleBoxEmpty.new()
		lowered.content_margin_top = PRESS_DROP * 2
		add_theme_stylebox_override(style, lowered)
	focus_entered.connect(_refresh_focus)
	for changed in [focus_exited, mouse_entered, mouse_exited]:
		changed.connect(marked_changed.emit)
	pressed.connect(click.bind(self))
	button_down.connect(_set_down.bind(true))
	button_up.connect(_set_down.bind(false))

func set_colors(normal: Color, active: Color) -> void:
	add_theme_color_override("font_color", normal)
	add_theme_color_override("font_disabled_color", normal)
	for state in ["font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		add_theme_color_override(state, active)
	_normal = normal
	_active = active
	_refresh_focus()

# True while hovered or keyboard-focused; panels that draw a button's content
# themselves (the Invert Y switch) use this for its highlight.
func is_marked() -> bool:
	return not disabled and (is_hovered() or (keyboard_nav and has_focus()))

func _refresh_focus() -> void:
	add_theme_color_override("font_focus_color", _active if keyboard_nav else _normal)
	marked_changed.emit()

func set_shadow(color: Color, offset := Vector2(1, 2)) -> void:
	_shadow = color
	add_theme_color_override("font_shadow_color", color)
	add_theme_constant_override("shadow_offset_x", int(offset.x))
	add_theme_constant_override("shadow_offset_y", int(offset.y))

func _set_down(down: bool) -> void:
	if _shadow.a > 0:
		add_theme_color_override("font_shadow_color", Color.TRANSPARENT if down else _shadow)
