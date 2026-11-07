class_name ManorTrophyCase
extends Node3D

signal acquired

const TITLE := "Bell Trophy"
const DESCRIPTION := "For whom the bell tolls"
# After the ninth ring the bells replay the word themselves, quicker than anyone could walk it.
const PEAL_DELAY := 1.4
const PEAL_INTERVAL := 0.6
const DOOR_AFTER_PEAL := 0.8
const DOOR_TIME := 1.1
# Past square, so the open door reads as open from anywhere in the Foyer.
const DOOR_ANGLE := 115.0 * PI / 180.0
const LIFT_TIME := 0.35
const ARRIVE_TIME := 1.35
const HOLD_AT := 1.65
const REWARD_TIME := 2.25
# Inside the player collision radius so the case itself cannot occlude the presented trophy.
const VIEW_DISTANCE := 0.22
# Handle tip to handle tip, the span the presentation sizes to.
const TROPHY_WIDTH := 0.66

var manor: Manor
var hud: ManorTrophyHUD
var trophy: Node3D
var holder: Node3D
var prize_tray: Node3D
var door: Node3D
var door_wait := -1.0
var door_motion: Tween
# The open display above the cabinet; aiming at it while the door stands open takes the trophy.
var display_hit: StaticBody3D
var peal: Array[int] = []
var peal_wait := 0.0
var opened := false
var presenting := false
var owned := false
var accepted := false
var reward_elapsed := 0.0
var reward_origin: Transform3D

func _ready() -> void:
	var wood := ManorGeometry.material("634632", 0.005)
	var brass := ManorGeometry.material("C9A04A", 0.003)
	var dark := ManorGeometry.material("34494C", 0.004)
	ManorGeometry.box(self, Vector3(0.86, 0.88, 0.56), Vector3(0, 0.48, 0), wood)
	ManorGeometry.box(self, Vector3(0.96, 0.10, 0.64), Vector3(0, 0.10, 0), dark)
	ManorGeometry.box(self, Vector3(0.96, 0.06, 0.64), Vector3(0, 1.02, 0), brass)
	ManorGeometry.box(self, Vector3(0.86, 0.86, 0.045), Vector3(0, 1.48, -0.26), dark)
	for x in [-0.41, 0.41]:
		for z in [-0.25, 0.25]:
			ManorGeometry.box(self, Vector3(0.045, 0.86, 0.045), Vector3(x, 1.48, z), brass)
	ManorGeometry.box(self, Vector3(0.96, 0.09, 0.64), Vector3(0, 1.92, 0), wood)
	ManorGeometry.box(self, Vector3(0.88, 0.025, 0.58), Vector3(0, 1.98, 0), brass)
	for side in [-1, 1]:
		var pane := ManorGeometry.box(self, Vector3(0.012, 0.77, 0.46), Vector3(side * 0.41, 1.48, 0), ManorGeometry.glass())
		pane.name = "LeftGlass" if side < 0 else "RightGlass"
		pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_build_door(brass)
	prize_tray = Node3D.new()
	add_child(prize_tray)
	prize_tray.position.y = 1.065
	ManorGeometry.box(prize_tray, Vector3(0.68, 0.03, 0.46), Vector3.ZERO, brass)
	# The holder sits at the trophy's middle, the point the presentation centres on screen.
	holder = Node3D.new()
	prize_tray.add_child(holder)
	holder.position.y = 0.255
	trophy = ManorPrizeArt.trophy(holder)
	trophy.position.y = -0.24
	var panel := ManorGeometry.box(self, Vector3(0.64, 0.48, 0.018), Vector3(0, 0.56, 0.289), ManorGeometry.material("78553D", 0.003))
	panel.name = "CasePanel"
	ManorGeometry.barrier(self, Vector3(0.96, 1.05, 0.65), Vector3(0, 0.525, 0))
	display_hit = ManorGeometry.barrier(self, Vector3(0.96, 0.93, 0.65), Vector3(0, 1.515, 0))
	set_process(false)
	manor.bells.completed.connect(_begin_peal)

# An overlay door hinged on the outer edge of the left post, between the brass band and the top,
# so it swings outward and clear of the posts, bands and side glass.
func _build_door(brass: Material) -> void:
	door = Node3D.new()
	door.name = "CaseDoor"
	door.position = Vector3(-0.4325, 1.4625, 0.2865)
	add_child(door)
	const WIDE := 0.865
	const TALL := 0.815
	const BAR := 0.035
	for y in [-TALL / 2 + BAR / 2, TALL / 2 - BAR / 2]:
		ManorGeometry.box(door, Vector3(WIDE, BAR, 0.014), Vector3(WIDE / 2, y, -0.007), brass)
	for x in [BAR / 2, WIDE - BAR / 2]:
		ManorGeometry.box(door, Vector3(BAR, TALL - BAR * 2, 0.014), Vector3(x, 0, -0.007), brass)
	var pane := ManorGeometry.box(door, Vector3(WIDE - BAR * 2, TALL - BAR * 2, 0.008), Vector3(WIDE / 2, 0, -0.007), ManorGeometry.glass())
	pane.name = "DoorGlass"
	pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ManorGeometry.cylinder(door, 0.014, 0.022, Vector3(WIDE - 0.075, 0, 0.011), brass).rotation.x = PI / 2

func setup_hud(layer: CanvasLayer) -> void:
	hud = ManorTrophyHUD.new()
	hud.case = self
	layer.add_child(hud)
	layer.move_child(hud, layer.get_children().find(manor.play_gate))

func _begin_peal() -> void:
	peal.assign(Array(ManorBells.WORD.split("")).map(func(letter: String) -> int: return ManorBells.LETTERS.find_key(letter)))
	peal_wait = PEAL_DELAY
	set_process(true)

func _paused() -> bool:
	return manor.play_gate.visible or manor.recovering or manor.in_finale or manor.at_title

func _input(event: InputEvent) -> void:
	if presenting and not _paused() and ManorCoinHUD.is_accept_press(event):
		get_viewport().set_input_as_handled()
		if reward_elapsed >= ARRIVE_TIME:
			accepted = true
			reward_elapsed = maxf(reward_elapsed, HOLD_AT)

func _process(delta: float) -> void:
	var paused := _paused()
	if door_motion != null:
		if paused:
			door_motion.pause()
		elif not door_motion.is_running():
			door_motion.play()
	if paused:
		hud.show_caption(false, 0.0)
		return
	if not peal.is_empty():
		peal_wait -= delta
		if peal_wait <= 0.0:
			peal_wait = PEAL_INTERVAL
			manor.bell_mounts[peal.pop_front()].peal()
			if peal.is_empty():
				door_wait = DOOR_AFTER_PEAL
	elif door_wait >= 0.0:
		door_wait -= delta
		if door_wait < 0.0:
			_open_door()
	elif presenting:
		_present(delta)

func _open_door() -> void:
	manor.audio.play_at("door_open", door.global_position, -10.0)
	door_motion = create_tween()
	door_motion.tween_property(door, "rotation:y", -DOOR_ANGLE, DOOR_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	door_motion.tween_callback(func() -> void:
		door_motion = null
		opened = true
		display_hit.set_meta("trophy", self)
		# Only once it has swung clear, so the player is never caught in its path.
		ManorGeometry.barrier(door, Vector3(0.865, 0.815, 0.03), Vector3(0.4325, 0, -0.007)))

func take() -> bool:
	if not opened or owned or presenting or manor.controls_locked():
		return false
	presenting = true
	accepted = false
	reward_elapsed = 0.0
	reward_origin = holder.global_transform
	holder.reparent(self, true)
	display_hit.remove_meta("trophy")
	manor.player.cancel_pull()
	manor.player.velocity = Vector3.ZERO
	manor.player.bot_drive = Vector3.ZERO
	manor.audio.play("lever_grab", -12.0)
	return true

func _world_width(pixels: float) -> float:
	var camera := manor.player.camera
	return camera.project_position(Vector2(pixels, 0), VIEW_DISTANCE).distance_to(camera.project_position(Vector2.ZERO, VIEW_DISTANCE))

func _present(delta: float) -> void:
	reward_elapsed = minf(reward_elapsed + delta, REWARD_TIME if accepted else HOLD_AT)
	var size := hud.size
	var portrait := size.x < 600
	var at := size * (Vector2(0.5, 0.30) if portrait else Vector2(0.31, 0.50))
	var width := minf(size.x * (0.40 if portrait else 0.27), size.y * 0.36)
	var camera := manor.player.camera
	var rise := smoothstep(0.0, LIFT_TIME, reward_elapsed)
	var enter := smoothstep(LIFT_TIME, ARRIVE_TIME, reward_elapsed)
	var travel := smoothstep(HOLD_AT, REWARD_TIME, reward_elapsed)
	var destination := camera.project_position(at.lerp(hud.icon_position(), travel), VIEW_DISTANCE)
	# Upright and tipped a little toward the player, so the hollow bell mouth shows.
	var basis := camera.global_basis * Basis.from_euler(Vector3(0.22, 0.12, 0))
	var rotation_value := reward_origin.basis.orthonormalized().get_rotation_quaternion().slerp(basis.get_rotation_quaternion(), enter)
	var lifted := reward_origin.origin + Vector3.UP * 0.22
	var position_value := reward_origin.origin.lerp(lifted, rise).lerp(destination, enter)
	var scale_value := 1.0
	if enter > 0.0:
		# Interpolate apparent size, not world scale: approaching the near-camera
		# presentation otherwise makes most of the growth happen in the last instant.
		var start_depth := maxf(camera.near, -camera.to_local(lifted).z)
		var depth := maxf(camera.near, -camera.to_local(position_value).z)
		var end_scale := _world_width(width) / TROPHY_WIDTH
		scale_value = lerpf(1.0 / start_depth, end_scale / VIEW_DISTANCE, enter) * depth
	scale_value *= lerpf(1.0, 30.0 / width, travel)
	holder.global_transform = Transform3D(Basis(rotation_value).scaled(Vector3.ONE * scale_value), position_value)
	hud.show_caption(true, smoothstep(ARRIVE_TIME - 0.35, ARRIVE_TIME, reward_elapsed) * (1.0 - smoothstep(HOLD_AT, REWARD_TIME, reward_elapsed)))
	if reward_elapsed >= REWARD_TIME:
		owned = true
		presenting = false
		holder.hide()
		hud.show_caption(false, 0.0)
		hud.accessibility_name = TITLE
		set_process(false)
		acquired.emit()
