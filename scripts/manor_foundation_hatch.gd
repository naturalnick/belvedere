class_name ManorFoundationHatch
extends Node3D

const SLOT := 0
var manor: Manor
var lid: Node3D
var contents: Node3D
var handle: Node3D
var lid_hit: StaticBody3D
var opened := false
var emptied := false
var busy := false
var motion: Tween

func _ready() -> void:
	name = "FoundationHatch"
	position = ManorGeometry.center(SLOT) + Vector3(0.8, 0, 0.5)
	var iron := ManorGeometry.material("526160", 0.002)
	var dark := ManorGeometry.material("242E2D", 0.0)
	var brass := ManorGeometry.material("B58D4E", 0.001)
	# A shallow lined recess sits above the walking slab; it never opens a fall hazard.
	ManorGeometry.box(self, Vector3(0.68, 0.012, 0.78), Vector3(0, -0.008, 0), dark)
	for x in [-0.35, 0.35]:
		ManorGeometry.box(self, Vector3(0.04, 0.045, 0.84), Vector3(x, 0.003, 0), iron)
	for z in [-0.40, 0.40]:
		ManorGeometry.box(self, Vector3(0.68, 0.045, 0.04), Vector3(0, 0.003, z), iron)
	contents = Node3D.new()
	add_child(contents)
	contents.position.y = 0.012
	lid = Node3D.new()
	lid.name = "Lid"
	lid.position = Vector3(0, 0.025, -0.38)
	add_child(lid)
	ManorGeometry.box(lid, Vector3(0.67, 0.025, 0.76), Vector3(0, 0, 0.38), iron)
	ManorGeometry.box(lid, Vector3(0.57, 0.006, 0.64), Vector3(0, 0.015, 0.38), ManorGeometry.material("64716D", 0.0))
	for x in [-0.27, 0.27]:
		for z in [0.09, 0.67]:
			ManorGeometry.cylinder(lid, 0.012, 0.007, Vector3(x, 0.021, z), brass)
	for x in [-0.23, 0.23]:
		var hinge := ManorGeometry.cylinder(lid, 0.025, 0.12, Vector3(x, 0, 0), brass)
		hinge.rotation.z = PI / 2
	handle = Node3D.new()
	handle.position = Vector3(0, 0.035, 0.61)
	lid.add_child(handle)
	for x in [-0.07, 0.07]:
		ManorGeometry.box(handle, Vector3(0.018, 0.045, 0.018), Vector3(x, 0, 0), brass)
	ManorGeometry.box(handle, Vector3(0.16, 0.018, 0.018), Vector3(0, 0.025, 0), brass)
	lid_hit = ManorGeometry.barrier(self, Vector3(0.67, 0.07, 0.76), Vector3(0, 0.035, 0))
	lid_hit.set_meta("foundation_hatch", self)
	manor.slide_started.connect(refresh)
	manor.slide_finished.connect(refresh)
	refresh()

func exposed() -> bool:
	return not manor.sliding and manor.rules.board[SLOT] == -1

func refresh() -> void:
	visible = exposed()
	contents.visible = visible and opened
	lid_hit.collision_layer = 1 if visible and not opened and not emptied else 0

func interact() -> bool:
	if not exposed() or busy or manor.controls_locked():
		return false
	if opened or emptied:
		return false
	manor.player.cancel_pull()
	manor.player.velocity = Vector3.ZERO
	manor.player.bot_drive = Vector3.ZERO
	opened = true
	busy = true
	refresh()
	manor.audio.play_at("door_open", global_position, -12.0)
	motion = create_tween()
	motion.tween_property(lid, "rotation:x", deg_to_rad(-105), 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	motion.tween_interval(0.25)
	motion.tween_callback(func() -> void:
		busy = false
		motion = null
		manor.stopwatch.present_reward()
		refresh())
	return true

func close_after_reward() -> void:
	if not opened or busy or emptied:
		return
	emptied = true
	busy = true
	motion = create_tween()
	motion.tween_property(lid, "rotation:x", 0.0, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	motion.tween_callback(func() -> void:
		opened = false
		busy = false
		motion = null
		refresh()
		manor.audio.play_at("door_close", global_position, -14.0))

func _process(_delta: float) -> void:
	if motion != null and motion.is_valid():
		if manor.stopwatch._suspended():
			motion.pause()
		elif not motion.is_running():
			motion.play()
