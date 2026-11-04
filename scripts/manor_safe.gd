class_name ManorSafe
extends Node3D

signal opened
signal button_pressed
signal handle_tried(success: bool)

var manor: Manor
var counts: Array[int] = [0, 0, 0, 0]
var unlocked := false
var busy := false
var door: Node3D
var handle: Node3D
var contents: Node3D
var buttons: Array[Node3D] = []
var button_motions: Array[Tween] = [null, null, null, null]
var motion: Tween

func _ready() -> void:
	name = "StudySafe"
	var iron := ManorGeometry.material("505A59", 0.004)
	var edge := ManorGeometry.material("303B3C", 0.003)
	var brass := ManorGeometry.material("B39459", 0.002)
	var inside := ManorGeometry.material("242D2E", 0.0)
	ManorGeometry.box(self, Vector3(1.22, 0.06, 0.68), Vector3(0, 0.05, 0), edge, true)
	for x in [-0.57, 0.57]:
		ManorGeometry.box(self, Vector3(0.08, 0.80, 0.64), Vector3(x, 0.48, 0), iron, true)
	for y in [0.12, 0.84]:
		ManorGeometry.box(self, Vector3(1.06, 0.08, 0.64), Vector3(0, y, 0), iron, true)
	ManorGeometry.box(self, Vector3(1.06, 0.64, 0.07), Vector3(0, 0.48, -0.285), inside, true)
	ManorGeometry.box(self, Vector3(1.04, 0.012, 0.51), Vector3(0, 0.166, 0.005), inside)
	contents = Node3D.new()
	contents.name = "Contents"
	contents.position = Vector3(0, 0.18, 0)
	add_child(contents)
	door = Node3D.new()
	door.name = "Door"
	door.position = Vector3(-0.53, 0, 0.345)
	add_child(door)
	ManorGeometry.box(door, Vector3(1.06, 0.66, 0.075), Vector3(0.53, 0.48, 0), iron)
	ManorGeometry.box(door, Vector3(0.97, 0.57, 0.018), Vector3(0.53, 0.48, 0.047), edge)
	ManorGeometry.barrier(door, Vector3(1.06, 0.66, 0.09), Vector3(0.53, 0.48, 0))
	for y in [0.25, 0.72]:
		ManorGeometry.cylinder(self, 0.037, 0.13, Vector3(-0.55, y, 0.34), brass)
	for i in 4:
		var button := Node3D.new()
		button.name = ["Red", "Yellow", "Orange", "Green"][i] + "Button"
		button.position = Vector3(0.17 + i * 0.24, 0.62, 0.078)
		door.add_child(button)
		ManorGeometry.cylinder(button, 0.085, 0.025, Vector3.ZERO, brass).rotation.x = PI / 2
		ManorGeometry.cylinder(button, 0.065, 0.04, Vector3(0, 0, 0.021), ManorGeometry.material(ManorFruitClue.COLORS[i], 0.002)).rotation.x = PI / 2
		var hit := ManorGeometry.barrier(door, Vector3(0.18, 0.18, 0.06), button.position + Vector3(0, 0, 0.02))
		hit.set_meta("safe", self)
		hit.set_meta("safe_button", i)
		buttons.append(button)
	handle = Node3D.new()
	handle.name = "Handle"
	handle.position = Vector3(0.53, 0.31, 0.10)
	door.add_child(handle)
	ManorGeometry.cylinder(handle, 0.055, 0.09, Vector3.ZERO, brass).rotation.x = PI / 2
	ManorGeometry.box(handle, Vector3(0.32, 0.045, 0.045), Vector3(0, 0, 0.055), brass)
	var latch := ManorGeometry.barrier(handle, Vector3(0.37, 0.16, 0.10), Vector3(0, 0, 0.045))
	latch.set_meta("safe", self)
	latch.set_meta("safe_button", -1)

func interact(index: int) -> bool:
	if unlocked or busy or manor.controls_locked() or index < -1 or index >= 4:
		return false
	if index == -1:
		_try_handle()
		return true
	counts[index] += 1
	if button_motions[index] != null:
		button_motions[index].kill()
	var button := buttons[index]
	button.position.z = 0.064
	var tween := create_tween()
	tween.tween_property(button, "position:z", 0.078, 0.16).set_trans(Tween.TRANS_SINE)
	button_motions[index] = tween
	tween.finished.connect(func() -> void: button_motions[index] = null)
	button_pressed.emit()
	return true

func _try_handle() -> void:
	busy = true
	var correct := counts == ManorFruitClue.COUNTS
	handle_tried.emit(correct)
	motion = create_tween()
	motion.tween_property(handle, "rotation:z", -PI / 4 if correct else -0.13, 0.18)
	if correct:
		unlocked = true
		motion.tween_property(door, "rotation:y", deg_to_rad(-105), 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		motion.tween_callback(func() -> void: opened.emit())
	else:
		motion.tween_property(handle, "rotation:z", 0.07, 0.10)
		motion.tween_property(handle, "rotation:z", 0.0, 0.12)
		motion.tween_callback(func() -> void: counts.fill(0))
	motion.finished.connect(func() -> void:
		busy = false
		motion = null)

func _process(_delta: float) -> void:
	var paused := manor.controls_locked()
	for tween in button_motions + [motion]:
		if tween == null or not tween.is_valid():
			continue
		if paused:
			tween.pause()
		elif not tween.is_running():
			tween.play()
