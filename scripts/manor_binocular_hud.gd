class_name ManorBinocularHUD
extends Control

var binoculars: ManorBinoculars
var blackout := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	accessibility_name = "Binoculars"

func icon_position() -> Vector2:
	return Vector2(size.x - 146, 39)

func _draw() -> void:
	if binoculars.manor.at_title or binoculars.manor.in_finale or binoculars.manor.recovering:
		return
	if binoculars.owned and not binoculars.presenting:
		ManorBinocularArt.draw_icon(self, icon_position())
	if binoculars.overhead and not binoculars.manor.play_gate.visible:
		var at := binoculars.overview_camera.unproject_position(binoculars.manor.player.global_position)
		if get_rect().has_point(at):
			draw_circle(at, 5, Color("303B36"))
			draw_circle(at, 3, Color("F6EEE1"))
	if blackout > 0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.025, 0.035, 0.03, blackout))
