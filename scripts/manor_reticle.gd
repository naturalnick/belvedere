extends Control

var player: ManorPlayer

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(player) or player.manor.sliding:
		return
	var center := get_viewport_rect().size / 2.0
	draw_circle(center, 2.0, Color("F6EEE1"))
	var hit := player.focus()
	if player.held or (not hit.is_empty() and (hit.collider.has_meta("lever_room") or hit.collider.has_meta("door"))):
		draw_arc(center, 9.0, 0, TAU, 32, Color("C9A04A"), 1.5, true)
