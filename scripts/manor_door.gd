class_name ManorDoor
extends Node3D

var room_id := -1
var direction := 0
var is_front := false
var opened := false
var leaves: Array[Node3D] = []
var gate: StaticBody3D
var motion: Tween

func build(accent: String) -> void:
	var frame := ManorGeometry.material(accent, 0.02)
	var wood := ManorGeometry.material("6E4A33")
	for x in [-0.65, 0.65]:
		ManorGeometry.box(self, Vector3(0.1, 2.3, 0.32), Vector3(x, 1.15, 0), frame)
	ManorGeometry.box(self, Vector3(1.4, 0.1, 0.32), Vector3(0, 2.25, 0), frame)
	for i in 2:
		var hinge := Node3D.new()
		add_child(hinge)
		hinge.position.x = -0.6 if i == 0 else 0.6
		var offset := 0.3 if i == 0 else -0.3
		for edge in [-0.27, 0.27]:
			ManorGeometry.box(hinge, Vector3(0.06, 2.16, 0.08), Vector3(offset + edge, 1.1, 0), wood)
		for y in [0.05, 0.58, 1.1, 1.64, 2.17]:
			ManorGeometry.box(hinge, Vector3(0.6, 0.06, 0.08), Vector3(offset, y, 0), wood)
		ManorGeometry.box(hinge, Vector3(0.025, 2.15, 0.06), Vector3(offset, 1.1, 0), wood)
		var pane := ManorGeometry.box(hinge, Vector3(0.52, 2.1, 0.018), Vector3(offset, 1.1, 0), ManorGeometry.glass())
		pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ManorGeometry.box(hinge, Vector3(0.04, 0.17, 0.12), Vector3(offset * 1.75, 1.02, 0.05), ManorGeometry.material("C9A04A"))
		leaves.append(hinge)
	gate = ManorGeometry.barrier(self, Vector3(1.2, 2.2, 0.27), Vector3(0, 1.1, 0))
	gate.set_meta("door", self)

func set_open(value: bool, instant: bool = false) -> void:
	opened = value
	gate.collision_layer = 0 if value else 1
	if motion:
		motion.kill()
	motion = create_tween().set_parallel(true)
	for i in 2:
		var angle := (deg_to_rad(-100) if i == 0 else deg_to_rad(100)) if value else 0.0
		if instant:
			leaves[i].rotation.y = angle
		else:
			motion.tween_property(leaves[i], "rotation:y", angle, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if instant:
		motion.kill()

func rattle() -> void:
	if opened:
		return
	if motion:
		motion.kill()
	motion = create_tween()
	for angle in [0.035, -0.035, 0.02, 0.0]:
		motion.tween_property(leaves[0], "rotation:y", angle, 0.06)
