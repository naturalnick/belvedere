class_name ManorTrophyHUD
extends Control

var case: ManorTrophyCase
var title: Label
var hint: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title = ManorPrizeArt.reward_label(self, ManorTrophyCase.TITLE)
	hint = ManorPrizeArt.reward_label(self, ManorTrophyCase.DESCRIPTION)
	show_caption(false, 0.0)

func _process(_delta: float) -> void:
	queue_redraw()

func show_caption(showing: bool, alpha: float) -> void:
	var portrait := size.x < 600
	var text_scale := minf(size.x / 1100.0, size.y / 720.0)
	var left := 24.0 if portrait else size.x * 0.52
	var top := size.y * (0.57 if portrait else 0.42)
	var width := size.x - left - 24
	title.add_theme_font_size_override("font_size", maxi(28, int(58 * text_scale)))
	hint.add_theme_font_size_override("font_size", maxi(17, int(25 * text_scale)))
	title.position = Vector2(left, top)
	title.size = Vector2(width, 0)
	hint.position = Vector2(left, top + title.size.y + 12)
	hint.size = Vector2(width, 0)
	for label in [title, hint]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if portrait else HORIZONTAL_ALIGNMENT_LEFT
		label.visible = showing
		label.modulate.a = alpha

# Last in the item row, after the binoculars, stopwatch and red key.
func icon_position() -> Vector2:
	var manor := case.manor
	var items := int(manor.binoculars.owned) + int(manor.stopwatch.owned) + int(manor.conservatory.key_owned)
	return Vector2(size.x - 146 - items * 46, 40)

func _draw() -> void:
	var manor := case.manor
	if not case.owned or manor.at_title or manor.in_finale or manor.recovering or manor.play_gate.visible:
		return
	var at := icon_position()
	var ink := Color("725637")
	var gold := Color("D6AD55")
	var bright := Color("EED393")
	for side in [-1.0, 1.0]:
		var handle := PackedVector2Array()
		for step in 9:
			var t := step / 8.0
			var u := 1.0 - t
			handle.append(at + Vector2(side * (8.0 * u * u * u + 18.0 * 3 * u * u * t + 16.0 * 3 * u * t * t + 4.5 * t * t * t), -9.5 * u * u * u - 12.0 * 3 * u * u * t - 1.0 * 3 * u * t * t - 2.5 * t * t * t))
		draw_polyline(handle, ink, 3.5, true)
		draw_polyline(handle, gold, 1.8, true)
	var cup := PackedVector2Array([Vector2(-10, -12), Vector2(10, -12), Vector2(7, -8), Vector2(4.5, -3), Vector2(3, 2), Vector2(-3, 2), Vector2(-4.5, -3), Vector2(-7, -8)])
	for i in cup.size():
		cup[i] += at
	draw_colored_polygon(cup, gold)
	cup.append(cup[0])
	draw_polyline(cup, ink, 1.2, true)
	draw_line(at + Vector2(-10.5, -12), at + Vector2(10.5, -12), bright, 1.6, true)
	draw_rect(Rect2(at + Vector2(-2, 2), Vector2(4, 7)), ink)
	draw_rect(Rect2(at + Vector2(-1, 2), Vector2(2, 7)), gold)
	draw_rect(Rect2(at + Vector2(-9, 9), Vector2(18, 6)), ink)
	draw_rect(Rect2(at + Vector2(-8, 10), Vector2(16, 4)), Color("364C50"))
