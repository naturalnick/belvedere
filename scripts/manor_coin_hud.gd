class_name ManorCoinHUD
extends Control

const PRESENT_TIME := 1.8
var manor: Manor
var count: Label
var presentation := 0.0

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
	if not visible or manor.sliding or manor.first_coin_guide.holding_reward():
		return
	if manor.coins.pending.is_empty():
		return
	presentation += delta
	if presentation >= PRESENT_TIME:
		presentation = 0.0
		manor.coins.receive_next()
	queue_redraw()

func _draw() -> void:
	var destination := Vector2(size.x - 94, 40)
	ManorPrizeArt.draw_coin(self, destination, 15)
	if manor.coins.pending.is_empty() or manor.first_coin_guide.holding_reward() or (manor.binoculars != null and manor.binoculars.locks_player()):
		return
	var enter := smoothstep(0.0, 0.3, presentation)
	var travel := smoothstep(1.15, PRESENT_TIME, presentation)
	var origin := size * Vector2(0.5, 0.59) + Vector2(0, 24 * (1 - enter))
	var radius := lerpf(minf(size.y * 0.115, 82) * lerpf(0.65, 1.0, enter), 15.0, travel)
	var at := origin.lerp(destination, travel)
	ManorPrizeArt.draw_coin(self, at, radius, lerpf(-0.85, 0.0, enter), radius > 30)
