class_name ManorCoinHUD
extends Control

const PRESENT_TIME := 1.8
# The presented coin rests at HOLD_AT until a fresh key or mouse press sends it to the
# wallet; presses before ACCEPT_AFTER (while it is still arriving) are swallowed.
const HOLD_AT := 1.15
const ACCEPT_AFTER := 0.4
var manor: Manor
var count: Label
var presentation := 0.0
var accepted := false

# Any fresh key, mouse button or gamepad button accepts a presented reward. Escape still
# pauses, and wheel or mouse motion never accept.
static func is_accept_press(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo and event.physical_keycode != KEY_ESCAPE
	if event is InputEventMouseButton:
		return event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]
	return event is InputEventJoypadButton and event.pressed

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	count = Label.new()
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count.add_theme_font_size_override("font_size", 25)
	count.add_theme_color_override("font_color", Color("F6EEE1"))
	count.add_theme_color_override("font_shadow_color", Color("30251B"))
	count.add_theme_constant_override("shadow_offset_x", 1)
	count.add_theme_constant_override("shadow_offset_y", 2)
	add_child(count)
	manor.coins.changed.connect(_refresh)
	resized.connect(_refresh)
	_refresh()

func _refresh() -> void:
	count.text = str(manor.coins.available)
	count.accessibility_name = "%d Bel coins" % manor.coins.available
	count.position = Vector2(size.x - 70, 22)
	count.size = Vector2(46, 36)
	queue_redraw()

func _process(delta: float) -> void:
	visible = not manor.at_title and not manor.in_finale and not manor.recovering and not manor.play_gate.visible
	if manor.binoculars != null and manor.binoculars.locks_player():
		queue_redraw()
		return
	# Pause, room slides and fall recovery retain the queued reward presentation.
	if not showing():
		return
	presentation = minf(presentation + delta, PRESENT_TIME if accepted else HOLD_AT)
	if accepted and presentation >= PRESENT_TIME:
		presentation = 0.0
		accepted = false
		manor.coins.receive_next()
	queue_redraw()

# A coin is waiting to be shown or accepted; the player stays still until it reaches the wallet.
func presenting() -> bool:
	return not manor.coins.pending.is_empty()

func showing() -> bool:
	return visible and presenting() and not manor.sliding and not manor.first_coin_guide.holding_reward() and not (manor.binoculars != null and manor.binoculars.locks_player())

func accept() -> void:
	if showing() and presentation >= ACCEPT_AFTER:
		accepted = true
		# The coin is at rest until HOLD_AT, so its flight starts on the press.
		presentation = maxf(presentation, HOLD_AT)

func _input(event: InputEvent) -> void:
	if showing() and is_accept_press(event):
		get_viewport().set_input_as_handled()
		accept()

func _draw() -> void:
	var destination := Vector2(size.x - 94, 40)
	ManorPrizeArt.draw_coin(self, destination, 15)
	if not presenting() or manor.sliding or manor.first_coin_guide.holding_reward() or (manor.binoculars != null and manor.binoculars.locks_player()):
		return
	var enter := smoothstep(0.0, 0.3, presentation)
	var travel := smoothstep(HOLD_AT, PRESENT_TIME, presentation)
	var origin := size * Vector2(0.5, 0.59) + Vector2(0, 24 * (1 - enter))
	var radius := lerpf(minf(size.y * 0.115, 82) * lerpf(0.65, 1.0, enter), 15.0, travel)
	var at := origin.lerp(destination, travel)
	ManorPrizeArt.draw_coin(self, at, radius, lerpf(-0.85, 0.0, enter), radius > 30)
