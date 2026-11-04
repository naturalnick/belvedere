class_name ManorStopwatch
extends Node3D

signal acquired
signal cleared_hatch

const DESCRIPTION := "Shows the fewest shifts needed for assembly."
const LIFT_TIME := 0.35
const ARRIVE_TIME := 1.35
const CLEAR_HATCH_AT := 1.0
const HOLD_AT := 1.65
const REWARD_TIME := 2.25
const RAISE_TIME := 0.42
const LOWER_TIME := 0.30
# Inside the player collision radius so a nearby wall cannot occlude the held item.
const VIEW_DISTANCE := 0.22
enum Phase { IDLE, RAISING, VIEWING, LOWERING }

var manor: Manor
var model: ManorStopwatchArt
var solver := ManorSolver.new()
var hud: ManorStopwatchHUD
var reward_title: Label
var reward_hint: Label
var reward_key: Label
var owned := false
var claimed := false
var presenting := false
var accepted := false
var reward_elapsed := 0.0
var reward_origin: Transform3D
var phase := Phase.IDLE
var lift := 0.0
var remaining := -1
var last_key := -1

func setup(game: Manor, hud_layer: CanvasLayer) -> void:
	manor = game
	cleared_hatch.connect(manor.foundation_hatch.close_after_reward)
	model = ManorStopwatchArt.new()
	manor.foundation_hatch.contents.add_child(model)
	model.rotation = Vector3(-PI / 2, 0, -0.20)
	hud = ManorStopwatchHUD.new()
	hud.stopwatch = self
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(hud)
	hud_layer.move_child(hud, hud_layer.get_children().find(manor.binoculars.hud))
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	reward_title = ManorPrizeArt.reward_label(hud, "Stopwatch")
	reward_hint = ManorPrizeArt.reward_label(hud, DESCRIPTION)
	reward_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward_key = ManorPrizeArt.reward_label(hud, "Press T to use")
	_caption(false)
	solver.begin_build()

func locks_player(for_movement := false) -> bool:
	return presenting or (phase != Phase.IDLE and not (for_movement and phase == Phase.LOWERING))

func toggle() -> bool:
	if not owned or presenting or _suspended():
		return false
	if phase == Phase.VIEWING:
		return close()
	if phase != Phase.IDLE or manor.controls_locked() or not manor.player.is_on_floor():
		return false
	_stop_player()
	phase = Phase.RAISING
	lift = 0.0
	_pose_watch()
	model.show()
	return true

func close() -> bool:
	if phase == Phase.IDLE or _suspended():
		return false
	phase = Phase.LOWERING
	return true

func reset_view() -> void:
	phase = Phase.IDLE
	lift = 0.0
	if claimed:
		model.hide()
	_caption(false)

func present_reward() -> void:
	if claimed or manor.controls_locked():
		return
	claimed = true
	presenting = true
	reward_origin = model.global_transform
	model.reparent(self, true)
	_stop_player()
	manor.audio.play("lever_grab", -12.0)

func _stop_player() -> void:
	manor.player.cancel_pull()
	manor.player.velocity = Vector3.ZERO
	manor.player.bot_drive = Vector3.ZERO

func _suspended() -> bool:
	return manor.at_title or manor.in_finale or manor.recovering or manor.sliding or manor.play_gate.visible or manor.first_coin_guide.active or manor.binoculars.locks_player() or manor.coin_device.releasing

func _input(event: InputEvent) -> void:
	if presenting and not _suspended() and ManorCoinHUD.is_accept_press(event):
		get_viewport().set_input_as_handled()
		if reward_elapsed >= ARRIVE_TIME:
			accepted = true
			reward_elapsed = maxf(reward_elapsed, HOLD_AT)

func refresh_count() -> void:
	if not solver.ready or manor.sliding:
		return
	var key := manor.rules.key()
	if key == last_key:
		return
	last_key = key
	remaining = solver.assembly_distance(manor.rules)
	model.set_count(remaining)
	hud.accessibility_name = "Stopwatch: %d shifts to assemble the house" % remaining if remaining >= 0 else "Stopwatch"

func _process(delta: float) -> void:
	if manor == null:
		return
	hud.queue_redraw()
	# Never expose provisional BFS distances. Work is amortized during normal play,
	# not a blocking search when the player raises the watch or slides a room.
	if not solver.ready:
		var deadline := Time.get_ticks_usec() + 1500
		while not solver.ready and Time.get_ticks_usec() < deadline:
			solver.build_step(16)
	refresh_count()
	if manor.at_title or manor.in_finale or manor.recovering:
		reset_view()
		return
	if _suspended():
		_caption(false)
		if claimed:
			model.hide()
		return
	if presenting:
		_present(delta)
		return
	_caption(false)
	match phase:
		Phase.RAISING:
			lift = minf(1.0, lift + delta / RAISE_TIME)
			if lift == 1.0:
				phase = Phase.VIEWING
		Phase.LOWERING:
			lift = maxf(0.0, lift - delta / LOWER_TIME)
			if lift == 0.0:
				phase = Phase.IDLE
	if phase != Phase.IDLE:
		_pose_watch()
	model.visible = phase != Phase.IDLE or not claimed

func _pose_watch() -> void:
	var camera := manor.player.camera
	var size := hud.size
	var raised := smoothstep(0.0, 1.0, lift)
	var width := minf(size.x * 0.34, size.y * 0.28)
	var resting := size - Vector2(width * 0.72, width * 0.65)
	var lowered := Vector2(resting.x + width * 0.22, size.y + width * 1.05)
	var at := lowered.lerp(resting, raised)
	var scale_value := _world_width(width) / 0.216
	var basis := camera.global_basis * Basis.from_euler(Vector3(lerpf(-0.8, -0.15, raised), -0.18, lerpf(0.32, 0.12, raised)))
	model.global_transform = Transform3D(basis.scaled(Vector3.ONE * scale_value), camera.project_position(at, VIEW_DISTANCE))

func _world_width(pixels: float) -> float:
	var camera := manor.player.camera
	return camera.project_position(Vector2(pixels, 0), VIEW_DISTANCE).distance_to(camera.project_position(Vector2.ZERO, VIEW_DISTANCE))

func _present(delta: float) -> void:
	var previous_elapsed := reward_elapsed
	reward_elapsed = minf(reward_elapsed + delta, REWARD_TIME if accepted else HOLD_AT)
	var size := hud.size
	var portrait := size.x < 600
	var at := size * (Vector2(0.5, 0.32) if portrait else Vector2(0.31, 0.50))
	var width := minf(size.x * (0.34 if portrait else 0.25), size.y * 0.29)
	var camera := manor.player.camera
	var rise := smoothstep(0.0, LIFT_TIME, reward_elapsed)
	var enter := smoothstep(LIFT_TIME, ARRIVE_TIME, reward_elapsed)
	var travel := smoothstep(HOLD_AT, REWARD_TIME, reward_elapsed)
	var destination := camera.project_position(at.lerp(hud.icon_position(), travel), VIEW_DISTANCE)
	var basis := camera.global_basis * Basis.from_euler(Vector3(-0.10, 0.10, -0.08))
	var rotation_value := reward_origin.basis.orthonormalized().get_rotation_quaternion().slerp(basis.get_rotation_quaternion(), enter)
	var lifted := reward_origin.origin + Vector3.UP * 0.28
	var position_value := reward_origin.origin.lerp(lifted, rise).lerp(destination, enter)
	position_value += Vector3.UP * sin(enter * PI) * 0.12
	var scale_value := 1.0
	if enter > 0.0:
		# Interpolate apparent size, not world scale: approaching the near-camera
		# presentation otherwise makes most of the growth happen in the last instant.
		var start_depth := maxf(camera.near, -camera.to_local(lifted).z)
		var depth := maxf(camera.near, -camera.to_local(position_value).z)
		var end_scale := _world_width(width) / 0.216
		scale_value = lerpf(1.0 / start_depth, end_scale / VIEW_DISTANCE, enter) * depth
	scale_value *= lerpf(1.0, 26.0 / width, travel)
	model.global_transform = Transform3D(Basis(rotation_value).scaled(Vector3.ONE * scale_value), position_value)
	model.show()
	if previous_elapsed < CLEAR_HATCH_AT and reward_elapsed >= CLEAR_HATCH_AT:
		cleared_hatch.emit()
	_caption(true)
	if reward_elapsed >= REWARD_TIME:
		owned = true
		presenting = false
		model.hide()
		_caption(false)
		acquired.emit()

func _caption(showing: bool) -> void:
	var size := hud.size
	var portrait := size.x < 600
	var text_scale := minf(size.x / 1100.0, size.y / 720.0)
	var left := 24.0 if portrait else size.x * 0.52
	var top := size.y * (0.57 if portrait else 0.42)
	var width := size.x - left - 24
	reward_title.add_theme_font_size_override("font_size", maxi(28, int(58 * text_scale)))
	reward_hint.add_theme_font_size_override("font_size", maxi(17, int(25 * text_scale)))
	reward_key.add_theme_font_size_override("font_size", maxi(16, int(22 * text_scale)))
	reward_title.position = Vector2(left, top)
	reward_title.size = Vector2(width, 0)
	reward_hint.position = Vector2(left, top + reward_title.size.y + 12)
	reward_hint.size = Vector2(width, 0)
	reward_key.position = Vector2(left, reward_hint.position.y + reward_hint.size.y + 12)
	reward_key.size = Vector2(width, 0)
	for label in [reward_title, reward_hint, reward_key]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if portrait else HORIZONTAL_ALIGNMENT_LEFT
		label.visible = showing
		label.modulate.a = smoothstep(ARRIVE_TIME - 0.35, ARRIVE_TIME, reward_elapsed) * (1.0 - smoothstep(HOLD_AT, REWARD_TIME, reward_elapsed))
