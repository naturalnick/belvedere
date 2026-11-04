class_name ManorMenuIcons
extends RefCounted

static func button(side: float = 52) -> ManorInkButton:
	var result := ManorInkButton.new()
	result.size = Vector2.ONE * side
	return result

static func draw(canvas: Control, kind: String, at: Vector2, color: Color) -> void:
	match kind:
		"settings":
			canvas.draw_circle(at, 11, color, false, 2, true)
			canvas.draw_circle(at, 4, color, false, 2, true)
			for i in 8:
				var direction := Vector2.from_angle(i * TAU / 8)
				canvas.draw_line(at + direction * 11, at + direction * 17, color, 3, true)
		"fov":
			canvas.draw_polyline(PackedVector2Array([at + Vector2(19, -14), at + Vector2(-16, 0), at + Vector2(19, 14)]), color, 2, true)
			canvas.draw_arc(at + Vector2(-16, 0), 24, -0.4, 0.4, 16, color, 2, true)
		"sensitivity", "invert_y":
			canvas.draw_style_box(_mouse_shape(color), Rect2(at + Vector2(-9, -16), Vector2(18, 32)))
			canvas.draw_line(at + Vector2(0, -12), at + Vector2(0, -5), color, 2, true)
			var vertical := kind == "invert_y"
			var a := at + (Vector2(17, -12) if vertical else Vector2(-17, 21))
			var b := at + (Vector2(17, 12) if vertical else Vector2(17, 21))
			canvas.draw_line(a, b, color, 2, true)
			var along := (b - a).normalized()
			var across := along.orthogonal() * 4
			canvas.draw_polyline(PackedVector2Array([a + along * 5 + across, a, a + along * 5 - across]), color, 2, true)
			canvas.draw_polyline(PackedVector2Array([b - along * 5 + across, b, b - along * 5 - across]), color, 2, true)
		"master":
			canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(-16, -5), at + Vector2(-10, -5), at + Vector2(-2, -12), at + Vector2(-2, 12), at + Vector2(-10, 5), at + Vector2(-16, 5)]), color)
			canvas.draw_arc(at + Vector2(-2, 0), 16, -PI / 3, PI / 3, 16, color, 2, true)
		"effects":
			for i in 7:
				var height_value: float = [4, 9, 15, 7, 12, 6, 3][i]
				canvas.draw_line(at + Vector2((i - 3) * 5, -height_value), at + Vector2((i - 3) * 5, height_value), color, 2, true)
		"music":
			canvas.draw_polyline(PackedVector2Array([at + Vector2(-8, 10), at + Vector2(-8, -11), at + Vector2(12, -16), at + Vector2(12, 6)]), color, 3, true)
			canvas.draw_circle(at + Vector2(-12, 11), 5, color)
			canvas.draw_circle(at + Vector2(8, 7), 5, color)
		"back":
			canvas.draw_line(at + Vector2(14, 0), at + Vector2(-14, 0), color, 2, true)
			canvas.draw_polyline(PackedVector2Array([at + Vector2(-4, -10), at + Vector2(-14, 0), at + Vector2(-4, 10)]), color, 2, true)

static func _mouse_shape(color: Color) -> StyleBoxFlat:
	var shape := StyleBoxFlat.new()
	shape.bg_color = Color.TRANSPARENT
	shape.border_color = color
	shape.set_border_width_all(2)
	shape.set_corner_radius_all(8)
	return shape
