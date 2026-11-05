class_name ManorDoor
extends Node3D

signal swung(opening: bool)
signal rattled

const EXIT_OPEN_SECONDS := 3.5

var room_id := -1
var direction := 0
var is_front := false
var opened := false
var leaves: Array[Node3D] = []
var gate: StaticBody3D
var motion: Tween
var emblems: Array[MeshInstance3D] = []
var keyhole: Node3D

func build(accent: String) -> void:
	var frame := ManorGeometry.material(accent, 0.0)
	# Expanded box hulls become detached sheets when thin joinery is viewed up close.
	var wood := ManorGeometry.material("6E4A33", 0.0)
	var faces: Array[int] = [1]
	if is_front:
		faces.append(-1)
	for face in faces:
		for x in [-0.65, 0.65]:
			ManorGeometry.box(self, Vector3(0.1, 2.3, 0.12), Vector3(x, 1.15, face * 0.125), frame)
		ManorGeometry.box(self, Vector3(1.2, 0.1, 0.12), Vector3(0, 2.25, face * 0.125), frame)
	for i in 2:
		var hinge := Node3D.new()
		add_child(hinge)
		hinge.position.x = -0.6 if i == 0 else 0.6
		var offset := 0.3 if i == 0 else -0.3
		if not is_front:
			for edge in [-0.27, 0.27]:
				ManorGeometry.box(hinge, Vector3(0.06, 2.18, 0.08), Vector3(offset + edge, 1.11, 0), wood)
			var rails: Array[float] = [0.05, 0.58, 1.1, 1.64, 2.17]
			for y in rails:
				ManorGeometry.box(hinge, Vector3(0.48, 0.06, 0.08), Vector3(offset, y, 0), wood)
			for section in range(rails.size() - 1):
				var bottom := rails[section] + 0.03
				var top := rails[section + 1] - 0.03
				ManorGeometry.box(hinge, Vector3(0.025, top - bottom, 0.06), Vector3(offset, (top + bottom) / 2, 0), wood)
		if is_front:
			ManorGeometry.box(hinge, Vector3(0.6, 2.2, 0.10), Vector3(offset, 1.1, -0.015), ManorGeometry.material("A43D36", 0.0))
			for face in faces:
				for y in [0.32, 0.85, 1.38, 1.91]:
					ManorGeometry.box(hinge, Vector3(0.44, 0.40, 0.025), Vector3(offset, y, -0.015 + face * 0.07), ManorGeometry.material("BA5145", 0.006))
		else:
			var pane := ManorGeometry.box(hinge, Vector3(0.52, 2.1, 0.018), Vector3(offset, 1.1, 0), ManorGeometry.glass())
			pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var handle_x := offset * (1.86 if is_front else 1.75)
		for face in faces:
			var handle_z := -0.015 + face * 0.065 if is_front else 0.05
			ManorGeometry.box(hinge, Vector3(0.04, 0.17, 0.12), Vector3(handle_x, 1.02, handle_z), ManorGeometry.material("C9A04A"))
			if is_front and i == 0:
				var lock_plate := _build_keyhole(hinge, handle_x, face)
				if face == 1:
					keyhole = lock_plate
		ManorStaticBatch.combine(hinge)
		leaves.append(hinge)
	gate = ManorGeometry.barrier(self, Vector3(1.2, 2.2, 0.27), Vector3(0, 1.1, 0))
	gate.set_meta("door", self)
	if is_front:
		for face in faces:
			var mark := Node3D.new()
			add_child(mark)
			mark.position = Vector3(0, 2.58, face * 0.13)
			emblems.append(ManorGeometry.box(mark, Vector3(0.32, 0.25, 0.04), Vector3.ZERO, ManorGeometry.material("85744E")))
			for side in [-1, 1]:
				var roof := ManorGeometry.box(mark, Vector3(0.25, 0.045, 0.045), Vector3(side * 0.085, 0.19, 0), ManorGeometry.material("C9A04A"))
				roof.rotation.z = side * -PI / 4.0

func _build_keyhole(hinge: Node3D, x: float, face: int) -> Node3D:
	var plate := Node3D.new()
	plate.name = "Keyhole" if face == 1 else "OuterKeyhole"
	hinge.add_child(plate)
	# Mount against the flat center stile, clear of the raised decorative panels.
	plate.position = Vector3(x, 0.79, -0.015 + face * 0.06)
	plate.rotation.y = 0.0 if face == 1 else PI
	var brass := ManorGeometry.material("C9A04A", 0.0)
	var dark := ManorGeometry.material("30251B", 0.0)
	ManorGeometry.box(plate, Vector3(0.07, 0.17, 0.018), Vector3.ZERO, brass)
	var opening := ManorGeometry.cylinder(plate, 0.024, 0.003, Vector3(0, 0.012, 0.011), dark)
	opening.rotation.x = PI / 2
	ManorGeometry.box(plate, Vector3(0.025, 0.046, 0.003), Vector3(0, -0.019, 0.011), dark)
	for y in [-0.064, 0.064]:
		var screw := ManorGeometry.cylinder(plate, 0.007, 0.003, Vector3(0, y, 0.011), ManorGeometry.material("85744E", 0.0))
		screw.rotation.x = PI / 2
	return plate

func set_open(value: bool, instant: bool = false) -> void:
	if value == opened and not instant and (motion == null or not motion.is_running()):
		return
	var changed := value != opened
	opened = value
	for emblem in emblems:
		emblem.material_override = ManorGeometry.glowing_material("FFE3A1") if value else ManorGeometry.material("85744E")
	gate.collision_layer = 0 if value and (instant or not is_front) else 1
	if motion:
		motion.kill()
	if not instant:
		motion = create_tween().set_parallel(true)
		if changed:
			swung.emit(value)
	for i in 2:
		var angle := (deg_to_rad(-100) if i == 0 else deg_to_rad(100)) if value else 0.0
		if instant:
			leaves[i].rotation.y = angle
		else:
			motion.tween_property(leaves[i], "rotation:y", angle, EXIT_OPEN_SECONDS if is_front and value else 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if is_front and value and not instant:
		# Keep the player from walking through the solid panels during their slow reveal.
		motion.chain().tween_callback(func() -> void: gate.collision_layer = 0)

func rattle() -> void:
	if opened:
		return
	if motion:
		motion.kill()
	rattled.emit()
	motion = create_tween()
	for angle in [0.035, -0.035, 0.02, 0.0]:
		motion.tween_property(leaves[0], "rotation:y", angle, 0.06)
		motion.parallel().tween_property(leaves[1], "rotation:y", -angle, 0.06)
