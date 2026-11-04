class_name ManorStopwatchHUD
extends Control

var stopwatch: ManorStopwatch

func icon_position() -> Vector2:
	var binoculars_owned := stopwatch.manor.binoculars.owned
	return Vector2(size.x - (192 if binoculars_owned else 146), 40)

func shows_icon() -> bool:
	var manor := stopwatch.manor
	return stopwatch.owned and not stopwatch.presenting and not manor.at_title and not manor.in_finale and not manor.recovering and not manor.play_gate.visible

func _draw() -> void:
	if not shows_icon():
		return
	var at := icon_position()
	var ink := Color("725637")
	var brass := Color("D8BF83")
	var cream := Color("F4E7CC")
	draw_circle(at + Vector2(0, -17), 4, ink, false, 2.5, true)
	draw_circle(at + Vector2(0, -17), 4, brass, false, 1.0, true)
	draw_rect(Rect2(at + Vector2(-3, -15), Vector2(6, 5)), ink)
	draw_rect(Rect2(at + Vector2(-2, -14), Vector2(4, 3)), brass)
	draw_circle(at + Vector2(0, 1), 14, ink, true, -1.0, true)
	draw_circle(at, 13, brass, true, -1.0, true)
	draw_circle(at, 10.5, cream, true, -1.0, true)
	draw_circle(at, 10.5, ink, false, 0.8, true)
	for i in 4:
		var direction := Vector2.from_angle(i * PI / 2)
		draw_line(at + direction * 8.0, at + direction * 9.5, ink, 1.0, true)
