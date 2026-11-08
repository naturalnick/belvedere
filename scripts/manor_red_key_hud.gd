class_name ManorRedKeyHUD
extends Control

var conservatory: ManorConservatory
var reward_title: Label
var reward_hint: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	reward_title = ManorPrizeArt.reward_label(self, "Red Key")
	reward_hint = ManorPrizeArt.reward_label(self, "To your success")
	resized.connect(_layout_reward)
	_layout_reward()
	refresh_reward()

func reward_position() -> Vector2:
	return size * Vector2(0.32, 0.5)

func reward_width() -> float:
	return minf(size.x * 0.28, size.y * 0.43)

func _layout_reward() -> void:
	ManorPrizeArt.layout_reward_text(size, reward_title, reward_hint)

func refresh_reward() -> void:
	var showing := conservatory.collecting and not conservatory._suspended()
	var alpha := smoothstep(0.35, 0.70, conservatory.pickup_elapsed) * (1.0 - smoothstep(ManorConservatory.REWARD_HOLD_AT, ManorConservatory.REWARD_HOLD_AT + 0.25, conservatory.pickup_elapsed))
	for label in [reward_title, reward_hint]:
		label.visible = showing
		label.modulate.a = alpha

func icon_position() -> Vector2:
	var manor := conservatory.manor
	var items := int(manor.binoculars != null and manor.binoculars.owned) + int(manor.stopwatch != null and manor.stopwatch.owned)
	return Vector2(size.x - 146 - items * 46, 40)

func _draw() -> void:
	var manor := conservatory.manor
	if not conservatory.key_owned or not manor.shows_inventory():
		return
	var red := Color("BA5145")
	var ink := Color("703C32")
	draw_set_transform(icon_position(), -0.6)
	draw_circle(Vector2(-8, 0), 7, ink, false, 5, true)
	draw_circle(Vector2(-8, 0), 7, red, false, 3, true)
	draw_line(Vector2(-1, 0), Vector2(18, 0), ink, 5, true)
	draw_line(Vector2(-1, 0), Vector2(18, 0), red, 3, true)
	for x in [11, 17]:
		draw_line(Vector2(x, 0), Vector2(x, 7), ink, 5, true)
		draw_line(Vector2(x, 0), Vector2(x, 6), red, 3, true)
	draw_set_transform(Vector2.ZERO)
