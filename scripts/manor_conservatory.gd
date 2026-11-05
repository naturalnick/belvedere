class_name ManorConservatory
extends Node3D

enum Phase { DORMANT, WAITING, RETRACTING, RISING, READY }
const CLOSE_TIME := 0.55
const RETRACT_TIME := 2.2
const RISE_TIME := 5.5
const SETTLE_TIME := 0.55
const START_DEPTH := -6.2
const PICKUP_TIME := 2.2
const REWARD_HOLD_AT := 1.4
const REWARD_ACCEPT_AFTER := 0.7
const UNLOCK_TIME := 1.3

var manor: Manor
var phase := Phase.DORMANT
var elapsed := 0.0
var room: ConservatoryArt
var shaft: Node3D
var slab: Node3D
var hud: ManorRedKeyHUD
var key_owned := false
var exit_unlocked := false
var collecting := false
var pickup_elapsed := 0.0
var pickup_origin := Transform3D.IDENTITY
var reward_accepted := false
var unlocking := false
var unlock_elapsed := 0.0
var unlock_door: ManorDoor
var motion_sound: AudioStreamPlayer3D
var retraction_sounded := false

func setup(game: Manor, layer: CanvasLayer) -> void:
	manor = game
	name = "ConservatorySequence"
	set_process(false)
	hud = ManorRedKeyHUD.new()
	hud.conservatory = self
	layer.add_child(hud)
	layer.move_child(hud, layer.get_children().find(manor.play_gate))

func begin() -> void:
	if phase != Phase.DORMANT:
		return
	phase = Phase.WAITING
	set_process(true)

func revealing() -> bool:
	return phase in [Phase.WAITING, Phase.RETRACTING, Phase.RISING]

func accessible() -> bool:
	return phase == Phase.READY

func _suspended() -> bool:
	return manor.at_title or manor.in_finale or manor.recovering or manor.sliding or manor.play_gate.visible

func _center_visible() -> bool:
	var target := Vector3(0, 1.4, 0)
	var camera := manor.player.camera
	if not camera.is_position_in_frustum(target):
		return false
	var ray := PhysicsRayQueryParameters3D.create(camera.global_position, target)
	ray.exclude = [manor.player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty() or not hit.collider.has_meta("door"):
		return false
	var door: ManorDoor = hit.collider.get_meta("door")
	return not door.is_front and ManorRules.neighbor(door.room_id, door.direction) == 4

func _start_reveal() -> void:
	slab = manor.gap_floors[4]
	_build_shaft()
	manor.meadow.open_center()
	room = ConservatoryArt.new()
	room.position.y = START_DEPTH
	add_child(room)
	room.key_hit.set_meta("red_key", self)
	room.key_hit.collision_layer = 0
	phase = Phase.RETRACTING
	elapsed = 0.0
	retraction_sounded = false

func _process(delta: float) -> void:
	if is_instance_valid(motion_sound):
		motion_sound.stream_paused = _suspended()
	hud.refresh_reward()
	hud.queue_redraw()
	if collecting or unlocking:
		room.key.visible = not _suspended()
	if _suspended():
		return
	if collecting:
		_collect(delta)
		hud.refresh_reward()
		return
	if unlocking:
		_unlock(delta)
		return
	if phase == Phase.WAITING:
		# Token presentations and item views must finish before the player can witness the rise.
		if not manor.controls_locked() and _center_visible():
			_start_reveal()
		return
	if phase == Phase.READY:
		return
	elapsed += delta
	if phase == Phase.RETRACTING:
		if not retraction_sounded and elapsed >= CLOSE_TIME:
			retraction_sounded = true
			_play_motion("gap_retract", -12.0)
		var progress := smoothstep(CLOSE_TIME, CLOSE_TIME + RETRACT_TIME, elapsed)
		slab.position = Vector3(ManorGeometry.PITCH * progress, -0.02, 0)
		if elapsed >= CLOSE_TIME + RETRACT_TIME + 0.35:
			slab.hide()
			phase = Phase.RISING
			elapsed = 0.0
			_play_motion("conservatory_rise", -6.0)
	elif phase == Phase.RISING:
		room.position.y = lerpf(START_DEPTH, 0.0, smoothstep(0.0, RISE_TIME, elapsed))
		if elapsed >= RISE_TIME + SETTLE_TIME:
			_stop_motion()
			room.position.y = 0.0
			phase = Phase.READY
			room.key_hit.collision_layer = 1
			manor.refresh_doors()

func _play_motion(group: String, volume_db: float) -> void:
	_stop_motion()
	# These clips follow the full motion envelope, so pitch variation would move the landing cue.
	motion_sound = manor.audio.play_at(group, Vector3.ZERO, volume_db, false)

func _stop_motion() -> void:
	if is_instance_valid(motion_sound):
		motion_sound.stop()
		motion_sound.queue_free()
	motion_sound = null

func _build_shaft() -> void:
	shaft = Node3D.new()
	shaft.name = "LiftShaft"
	add_child(shaft)
	var concrete := ManorGeometry.material("8C9088", 0.0)
	var joints := ManorGeometry.material("737B77", 0.0)
	var depth := -START_DEPTH + 0.45
	var edge := ManorGeometry.PITCH / 2
	ManorGeometry.box(shaft, Vector3(6.75, 0.2, 6.75), Vector3(0, -depth - 0.1, 0), concrete, true)
	for direction in 4:
		var wall := Node3D.new()
		shaft.add_child(wall)
		wall.position = ManorGeometry.DIRECTIONS[direction] * (edge + 0.125)
		wall.rotation.y = -direction * PI / 2.0
		ManorGeometry.box(wall, Vector3(6.75, depth, 0.25), Vector3(0, -depth / 2 - 0.02, 0), concrete, true)
		for course in range(1, 7):
			ManorGeometry.box(wall, Vector3(6.25, 0.018, 0.006), Vector3(0, -float(course), 0.128), joints)
	ManorStaticBatch.combine(shaft)

func take_key() -> bool:
	if not accessible() or key_owned or collecting or manor.controls_locked():
		return false
	collecting = true
	reward_accepted = false
	pickup_elapsed = 0.0
	pickup_origin = room.key.global_transform
	room.key.reparent(self, true)
	room.key_hit.collision_layer = 0
	manor.player.cancel_pull()
	manor.player.velocity = Vector3.ZERO
	manor.player.bot_drive = Vector3.ZERO
	manor.audio.play("lever_grab", -10.0)
	return true

func accept_reward() -> void:
	if collecting and not _suspended() and pickup_elapsed >= REWARD_ACCEPT_AFTER:
		reward_accepted = true
		pickup_elapsed = maxf(pickup_elapsed, REWARD_HOLD_AT)

func _input(event: InputEvent) -> void:
	if collecting and not _suspended() and ManorCoinHUD.is_accept_press(event):
		get_viewport().set_input_as_handled()
		accept_reward()

func _collect(delta: float) -> void:
	pickup_elapsed = minf(pickup_elapsed + delta, PICKUP_TIME if reward_accepted else REWARD_HOLD_AT)
	var enter := smoothstep(0.0, 0.65, pickup_elapsed)
	var travel := smoothstep(REWARD_HOLD_AT, PICKUP_TIME, pickup_elapsed)
	var camera := manor.player.camera
	var center := camera.project_position(hud.reward_position(), 0.85)
	var destination := camera.project_position(hud.icon_position(), 0.85)
	var at := pickup_origin.origin.lerp(center, enter).lerp(destination, travel)
	var end_basis := camera.global_basis * Basis.from_euler(Vector3(PI / 2, 0, -0.4))
	var rotation_value := pickup_origin.basis.orthonormalized().get_rotation_quaternion().slerp(end_basis.get_rotation_quaternion(), enter)
	var display_scale := camera.project_position(Vector2(hud.reward_width(), 0), 0.85).distance_to(camera.project_position(Vector2.ZERO, 0.85)) / 0.49
	var scale_value := lerpf(lerpf(1.0, display_scale, enter), 0.13, travel)
	room.key.global_transform = Transform3D(Basis(rotation_value).scaled(Vector3.ONE * scale_value), at)
	if pickup_elapsed >= PICKUP_TIME:
		room.key.hide()
		key_owned = true
		collecting = false
		hud.accessibility_name = "Red key"

func unlock_exit(door: ManorDoor) -> bool:
	if not door.is_front or not accessible() or not key_owned or exit_unlocked or unlocking or manor.controls_locked():
		return false
	unlocking = true
	unlock_elapsed = 0.0
	unlock_door = door
	manor.player.velocity = Vector3.ZERO
	manor.player.bot_drive = Vector3.ZERO
	_unlock(0.0)
	return true

func _unlock(delta: float) -> void:
	unlock_elapsed = minf(unlock_elapsed + delta, UNLOCK_TIME)
	var insert := smoothstep(0.0, 0.35, unlock_elapsed)
	var turn := smoothstep(0.35, 0.8, unlock_elapsed)
	var withdraw := smoothstep(0.95, UNLOCK_TIME, unlock_elapsed)
	var lock := unlock_door.keyhole.global_transform
	var key_basis := lock.basis * Basis(Vector3.BACK, turn * PI / 2) * Basis(Vector3.UP, PI / 2)
	var at := lock.origin + lock.basis.z * (0.14 + 0.22 * (1.0 - insert + withdraw))
	room.key.global_transform = Transform3D(key_basis.scaled(Vector3.ONE * 0.6), at)
	room.key.show()
	if unlock_elapsed >= UNLOCK_TIME:
		room.key.hide()
		unlocking = false
		exit_unlocked = true
		manor.audio.play_at("ui_click", lock.origin, -6.0)
		manor.open_exit()
