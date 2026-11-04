class_name ManorBinocularHUD
extends Control

var binoculars: ManorBinoculars
var blackout := 0.0
var reward_title: Label
var reward_hint: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	accessibility_name = "Binoculars"
	reward_title = ManorPrizeArt.reward_label(self, "Binoculars")
	reward_hint = ManorPrizeArt.reward_label(self, "Press B to use")
	resized.connect(_layout_reward)
	_layout_reward()
	refresh_reward()

func reward_position() -> Vector2:
	return size * Vector2(0.32, 0.5)

func reward_width() -> float:
	return minf(size.x * 0.28, size.y * 0.43)

func refresh_reward() -> void:
	var showing := binoculars.presenting and not binoculars._suspended()
	var alpha := smoothstep(0.35, 0.70, binoculars.reward_elapsed) * (1.0 - smoothstep(ManorBinoculars.REWARD_HOLD_AT, ManorBinoculars.REWARD_HOLD_AT + 0.25, binoculars.reward_elapsed))
	for label in [reward_title, reward_hint]:
		label.visible = showing
		label.modulate.a = alpha

func _layout_reward() -> void:
	ManorPrizeArt.layout_reward_text(size, reward_title, reward_hint)

func player_marker_position() -> Vector2:
	var player := binoculars.manor.player
	var room: int = binoculars.manor.rules.player
	var at := player.global_position
	if room >= 0:
		# A fixed corner marks occupancy without covering the room's home-order number.
		at = binoculars.manor.rooms[room].global_position + Vector3(1.95, 3.2, 1.95)
	return binoculars.overview_camera.unproject_position(at)

func _draw_person(at: Vector2) -> void:
	var cream := Color("F6EEE1")
	var ink := Color("30251B")
	var shoulders := PackedVector2Array()
	for step in 13:
		var angle := PI + PI * step / 12.0
		shoulders.append(at + Vector2(cos(angle) * 7, 6 + sin(angle) * 6))
	draw_colored_polygon(shoulders, cream)
	shoulders.append(shoulders[0])
	draw_polyline(shoulders, ink, 1.2, true)
	draw_circle(at + Vector2(0, -6), 4.6, ink, true, -1, true)
	draw_circle(at + Vector2(0, -6), 3.5, cream, true, -1, true)

func icon_position() -> Vector2:
	return Vector2(size.x - 146, 39)

func _draw() -> void:
	if binoculars.manor.at_title or binoculars.manor.in_finale or binoculars.manor.recovering:
		return
	if binoculars.owned and not binoculars.presenting:
		ManorBinocularArt.draw_icon(self, icon_position())
	if binoculars.overhead and not binoculars.manor.play_gate.visible:
		var at := player_marker_position()
		if get_rect().has_point(at):
			_draw_person(at)
	if blackout > 0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.025, 0.035, 0.03, blackout))
