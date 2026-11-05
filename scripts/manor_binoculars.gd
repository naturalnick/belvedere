class_name ManorBinoculars
extends Node3D

signal acquired

enum Phase { IDLE, RAISING, REVEALING, OVERVIEW, CLOSING, LOWERING }
const RAISE_TIME := 0.62
const REVEAL_TIME := 0.40
const CLOSE_TIME := 0.22
const LOWER_TIME := 0.45
const REWARD_TIME := 2.2
# The reward rests in front of the player from REWARD_HOLD_AT until a fresh press
# (see ManorCoinHUD.is_accept_press), accepted once it has finished arriving.
const REWARD_HOLD_AT := 1.40
const REWARD_ACCEPT_AFTER := 0.7
const BOARD_SPAN := 21.6

var manor: Manor
var hud: ManorBinocularHUD
var overview_camera: Camera3D
var held_model: Node3D
var reward: Node3D
var owned := false
var reward_claimed := false
var presenting := false
var reward_elapsed := 0.0
var reward_accepted := false
var reward_origin := Transform3D.IDENTITY
var phase := Phase.IDLE
var elapsed := 0.0
var overhead := false
var framed_viewport := Vector2.ZERO
var close_blackout := 0.0

func setup(game: Manor, hud_layer: CanvasLayer) -> void:
	manor = game
	overview_camera = Camera3D.new()
	overview_camera.name = "ManorOverview"
	overview_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	overview_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	overview_camera.position = Vector3(0, 28, 0)
	overview_camera.rotation.x = -PI / 2
	overview_camera.far = 90
	add_child(overview_camera)
	held_model = ManorBinocularArt.model(manor.player.camera)
	held_model.hide()
	reward = ManorBinocularArt.model(manor.study_safe.contents)
	reward.position = Vector3(0, 0.13, 0.01)
	reward.rotation.y = PI
	reward.scale = Vector3.ONE * 0.85
	manor.study_safe.opened.connect(present_reward)
	hud = ManorBinocularHUD.new()
	hud.binoculars = self
	hud_layer.add_child(hud)
	hud_layer.move_child(hud, hud_layer.get_children().find(manor.play_gate))
	_frame_board()

func locks_player() -> bool:
	return phase != Phase.IDLE or presenting

func toggle() -> bool:
	if manor.conservatory != null and manor.conservatory.revealing():
		return false
	if not owned or presenting or _suspended():
		return false
	if phase == Phase.OVERVIEW:
		return close()
	if phase != Phase.IDLE or manor.controls_locked() or not manor.player.is_on_floor():
		return false
	manor.player.cancel_pull()
	manor.player.velocity = Vector3.ZERO
	manor.player.bot_drive = Vector3.ZERO
	phase = Phase.RAISING
	elapsed = 0.0
	_pose_held(0.0)
	held_model.show()
	return true

func close() -> bool:
	if phase == Phase.IDLE or _suspended():
		return false
	if phase not in [Phase.CLOSING, Phase.LOWERING]:
		close_blackout = hud.blackout
		phase = Phase.CLOSING
		elapsed = 0.0
	return true

func present_reward() -> void:
	if reward_claimed or presenting:
		return
	# Preserve the safe's room transform before the reward flies independently to the player.
	reward_origin = reward.global_transform
	reward.reparent(self, true)
	reward_elapsed = 0.0
	reward_accepted = false
	presenting = true
	manor.player.cancel_pull()
	manor.player.velocity = Vector3.ZERO
	manor.player.bot_drive = Vector3.ZERO

func accept_reward() -> void:
	if presenting and not _suspended() and reward_elapsed >= REWARD_ACCEPT_AFTER:
		reward_accepted = true
		reward_elapsed = maxf(reward_elapsed, REWARD_HOLD_AT)

func _input(event: InputEvent) -> void:
	if presenting and not _suspended() and ManorCoinHUD.is_accept_press(event):
		get_viewport().set_input_as_handled()
		accept_reward()

func reset_view() -> void:
	_set_overhead(false)
	phase = Phase.IDLE
	elapsed = 0.0
	held_model.hide()
	hud.blackout = 0.0
	hud.queue_redraw()

func _suspended() -> bool:
	return manor.at_title or manor.in_finale or manor.recovering or manor.sliding or manor.play_gate.visible or (manor.first_coin_guide != null and manor.first_coin_guide.active) or manor.coin_device.releasing

func _process(delta: float) -> void:
	if manor == null:
		return
	hud.refresh_reward()
	if manor.at_title or manor.in_finale or manor.recovering:
		if phase != Phase.IDLE:
			reset_view()
		reward.visible = not presenting and not reward_claimed
		hud.queue_redraw()
		return
	_frame_board()
	if _suspended():
		hud.queue_redraw()
		return
	if presenting:
		_present(delta)
		hud.refresh_reward()
		hud.queue_redraw()
		return
	elapsed += delta
	match phase:
		Phase.RAISING:
			_pose_held(elapsed / RAISE_TIME)
			hud.blackout = smoothstep(0.48, RAISE_TIME, elapsed)
			if elapsed >= RAISE_TIME:
				_set_overhead(true)
				held_model.hide()
				phase = Phase.REVEALING
				elapsed = 0.0
		Phase.REVEALING:
			hud.blackout = 1.0 - smoothstep(0.0, REVEAL_TIME, elapsed)
			if elapsed >= REVEAL_TIME:
				phase = Phase.OVERVIEW
				hud.blackout = 0.0
		Phase.CLOSING:
			hud.blackout = lerpf(close_blackout, 1.0, smoothstep(0.0, CLOSE_TIME, elapsed))
			if elapsed >= CLOSE_TIME:
				_set_overhead(false)
				held_model.show()
				phase = Phase.LOWERING
				elapsed = 0.0
		Phase.LOWERING:
			_pose_held(1.0 - elapsed / LOWER_TIME)
			hud.blackout = 1.0 - smoothstep(0.0, 0.22, elapsed)
			if elapsed >= LOWER_TIME:
				phase = Phase.IDLE
				held_model.hide()
				hud.blackout = 0.0
	hud.queue_redraw()

func _pose_held(progress: float) -> void:
	var raise := smoothstep(0.0, 1.0, progress)
	var angle := raise * PI / 2
	var camera := manor.player.camera
	var viewport_size := get_viewport().get_visible_rect().size
	var right := camera.to_local(camera.project_position(viewport_size * Vector2(1.0, 0.5), 1.0)).x
	var top := camera.to_local(camera.project_position(viewport_size * Vector2(0.5, 0.0), 1.0)).y
	# Fit both eyecups before fading, including at the player's narrowest FOV.
	var eye_distance := maxf((ManorBinocularArt.EYE_SPACING + ManorBinocularArt.EYE_RADIUS) / (right * 0.72), ManorBinocularArt.EYE_RADIUS / (top * 0.72))
	eye_distance = maxf(eye_distance, camera.near + 0.025)
	var end_z := -ManorBinocularArt.EYE_FRONT - eye_distance
	var start_z := minf(-0.60, end_z - 0.20)
	# A continuous forearm-like arc lifts and draws inward together, with no midair stop.
	held_model.position = Vector3(0, -0.36 * (1.0 - sin(angle)), lerpf(start_z, end_z, 1.0 - cos(angle)))
	held_model.rotation = Vector3(lerpf(-0.24, 0.0, raise), 0, 0)

func _present(delta: float) -> void:
	reward.show()
	reward_elapsed = minf(reward_elapsed + delta, REWARD_TIME if reward_accepted else REWARD_HOLD_AT)
	var camera := manor.player.camera
	var center := camera.project_position(hud.reward_position(), 0.85)
	var enter := smoothstep(0.0, 0.65, reward_elapsed)
	var travel := smoothstep(REWARD_HOLD_AT, REWARD_TIME, reward_elapsed)
	var destination := camera.project_position(hud.icon_position(), 0.85)
	var at := reward_origin.origin.lerp(center, enter).lerp(destination, travel)
	var displayed_basis := camera.global_basis * Basis.from_euler(Vector3(-0.30, PI + lerpf(0.30, 0.60, enter), -0.10))
	var start_rotation := reward_origin.basis.orthonormalized().get_rotation_quaternion()
	var rotation_value := start_rotation.slerp(displayed_basis.get_rotation_quaternion(), enter)
	var display_scale := camera.project_position(Vector2(hud.reward_width(), 0), 0.85).distance_to(camera.project_position(Vector2.ZERO, 0.85)) / 0.36
	var scale_value := lerpf(lerpf(0.85, display_scale, enter), 0.13, travel)
	reward.global_transform = Transform3D(Basis(rotation_value).scaled(Vector3.ONE * scale_value), at)
	if reward_elapsed >= REWARD_TIME:
		owned = true
		reward_claimed = true
		presenting = false
		reward.hide()
		acquired.emit()

func _set_overhead(enabled: bool) -> void:
	overhead = enabled
	for room in manor.rooms.values():
		room.set_overview(enabled)
	# Window clues remain exclusive to looking through their room's windows.
	for clue in manor.fruit_clues:
		clue.visible = not enabled
	if enabled:
		overview_camera.make_current()
	else:
		manor.player.camera.make_current()

func _frame_board() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size == framed_viewport:
		return
	framed_viewport = viewport_size
	var aspect := viewport_size.x / maxf(viewport_size.y, 1.0)
	overview_camera.size = BOARD_SPAN / minf(aspect, 1.0)
