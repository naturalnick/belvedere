class_name ManorCoinHUD
extends Control

const PRESENT_TIME := 1.8
# The presented coin rests at HOLD_AT until a fresh key or mouse press sends it to the
# wallet; presses before ACCEPT_AFTER (while it is still arriving) are swallowed.
const HOLD_AT := 1.15
const ACCEPT_AFTER := 0.4
var manor: Manor
var count: Label
var reward_title: Label
var reward_hint: Label
var presentation := 0.0
var accepted := false
var pickup_origin := Vector2.ZERO
var pickup_radius := 8.0
var physical_pickup := false
var completed := false

func begin_pickup(at: Vector3) -> void:
	var camera := manor.player.camera
	pickup_origin = camera.unproject_position(at)
	pickup_radius = maxf(3.0, pickup_origin.distance_to(camera.unproject_position(at + camera.global_basis.x * 0.067)))
	physical_pickup = true

# Any fresh key, mouse button or gamepad button accepts a presented reward. The pause keys
# still pause, and wheel or mouse motion never accept.
static func is_accept_press(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo and not event.physical_keycode in ManorPlayer.PAUSE_KEYS
	if event is InputEventMouseButton:
		return event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]
	return event is InputEventJoypadButton and event.pressed

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The note stamp shrinks to a 30 px coin; without mipmaps it breaks into blocks.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	count = Label.new()
	count.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count.add_theme_font_size_override("font_size", 25)
	count.add_theme_color_override("font_color", Color("F6EEE1"))
	count.add_theme_color_override("font_shadow_color", Color("30251B"))
	count.add_theme_constant_override("shadow_offset_x", 1)
	count.add_theme_constant_override("shadow_offset_y", 2)
	add_child(count)
	reward_title = ManorPrizeArt.reward_label(self, "Token")
	reward_hint = ManorPrizeArt.reward_label(self, "Good for one song")
	reward_title.hide()
	reward_hint.hide()
	manor.coins.changed.connect(_refresh)
	resized.connect(_refresh)
	_refresh()

func _refresh() -> void:
	# Empty wallets have no count; the ending can show a checked coin for a completed collection.
	count.visible = manor.coins.available > 0
	count.text = str(manor.coins.available)
	count.accessibility_name = "%d Bel coins" % manor.coins.available
	count.position = Vector2(size.x - 70, 22)
	count.size = Vector2(46, 36)
	ManorPrizeArt.layout_reward_text(size, reward_title, reward_hint)
	queue_redraw()

func _process(delta: float) -> void:
	visible = manor.shows_inventory()
	var show_completion := manor.in_finale and manor.run_summary.revealed and manor.coins.collected.size() == ManorCoins.ROOMS.size() and manor.coins.inserted == ManorCoins.ROOMS.size() and manor.coins.available == 0
	if completed != show_completion:
		completed = show_completion
		accessibility_name = "All seven coins found and used" if completed else ""
		queue_redraw()
	_refresh_caption()
	if (manor.binoculars != null and manor.binoculars.locks_player()) or (manor.stopwatch != null and manor.stopwatch.locks_player()):
		queue_redraw()
		return
	# Pause, room slides and fall recovery retain the queued reward presentation.
	if not showing():
		return
	presentation = minf(presentation + delta, PRESENT_TIME if accepted else HOLD_AT)
	if accepted and presentation >= PRESENT_TIME:
		presentation = 0.0
		accepted = false
		physical_pickup = false
		manor.coins.receive_next()
	_refresh_caption()
	queue_redraw()

func _refresh_caption() -> void:
	var alpha := smoothstep(0.10, 0.35, presentation) * (1.0 - smoothstep(HOLD_AT, HOLD_AT + 0.25, presentation))
	for label in [reward_title, reward_hint]:
		label.visible = showing()
		label.modulate.a = alpha

# A coin is waiting to be shown or accepted; the player stays still until it reaches the wallet.
func presenting() -> bool:
	return not manor.coins.pending.is_empty()

func showing() -> bool:
	return visible and presenting() and not manor.in_finale and not manor.sliding and not manor.first_home_guide.active and not ((manor.binoculars != null and manor.binoculars.locks_player()) or (manor.stopwatch != null and manor.stopwatch.locks_player()))

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
	if count.visible or completed:
		ManorPrizeArt.draw_coin(self, destination, 15)
	if completed:
		var checkmark := PackedVector2Array([destination + Vector2(4, 7), destination + Vector2(9, 12), destination + Vector2(19, -1)])
		draw_polyline(checkmark, Color("4E3814"), 5, true)
		draw_polyline(checkmark, Color("F6EEE1"), 2.5, true)
	if not showing():
		return
	var enter := smoothstep(0.0, 0.3, presentation)
	var travel := smoothstep(HOLD_AT, PRESENT_TIME, presentation)
	var origin := size * Vector2(0.32, 0.5) + Vector2(0, 24 * (1 - enter))
	var radius := lerpf(minf(size.y * 0.15, 110) * lerpf(0.65, 1.0, enter), 15.0, travel)
	if physical_pickup:
		origin = pickup_origin.lerp(size * Vector2(0.32, 0.5), enter)
		radius = lerpf(lerpf(pickup_radius, minf(size.y * 0.15, 110), enter), 15.0, travel)
	var at := origin.lerp(destination, travel)
	ManorPrizeArt.draw_coin(self, at, radius, lerpf(-0.85, 0.0, enter))
