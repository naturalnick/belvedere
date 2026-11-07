class_name ManorPianoArt
extends Node3D
## Origin on the floor at the footprint centre, back at -DEPTH / 2, facing +Z.

const WIDTH := 1.40
const DEPTH := 0.56
const HEIGHT := 1.36
const SLOT_POSITION := Vector3(0.52, 0.98, DEPTH / 2 + 0.004)
var playing := false
var _keys: Array[Node3D] = []
var _spools: Array[Node3D] = []
var _paper: Node3D
var _time := 0.0

func _ready() -> void:
	set_process(false)
	_case()
	_coin_slot()
	_keyboard()
	_roll_window()
	var moving: Array[Node] = [_paper]
	moving.append_array(_keys)
	moving.append_array(_spools)
	# Unlike repeated chairs, the joinery has many different dimensions. Bake by material first
	# so the shared batcher can separate the ink shells without a draw per moulding or key.
	_bake(self, moving)
	ManorStaticBatch.combine(self, moving)

func _case() -> void:
	_box(self, Vector3(1.30, 1.27, 0.045), Vector3(0, 0.665, -0.2575), "5A3B28", 0.0)
	for side in [-1, 1]:
		var x: float = side * 0.625
		_box(self, Vector3(0.09, 1.24, 0.36), Vector3(x, 0.68, -0.10), "5A3B28")
		_box(self, Vector3(0.014, 0.91, 0.24), Vector3(side * 0.677, 0.73, -0.10), "6E4A33", 0.0)
		_box(self, Vector3(0.15, 0.09, 0.54), Vector3(side * 0.605, 0.045, -0.01), "5A3B28")
		_box(self, Vector3(0.102, 0.10, 0.115), Vector3(side * 0.605, 0.135, 0.197), "6E4A33")
		_box(self, Vector3(0.075, 0.45, 0.082), Vector3(side * 0.605, 0.41, 0.197), "6E4A33")
		for y in [0.205, 0.605]:
			_box(self, Vector3(0.098, 0.032, 0.106), Vector3(side * 0.605, y, 0.197), "8A6247", 0.0)
		_box(self, Vector3(0.114, 0.065, 0.15), Vector3(side * 0.605, 0.668, 0.175), "5A3B28")
		_box(self, Vector3(0.105, 0.09, 0.31), Vector3(side * 0.605, 0.78, 0.105), "5A3B28")
		_box(self, Vector3(0.11, 0.018, 0.32), Vector3(side * 0.605, 0.828, 0.105), "8A6247", 0.0)

	_box(self, Vector3(1.34, 0.08, 0.36), Vector3(0, 0.12, -0.09), "5A3B28")
	_box(self, Vector3(1.17, 0.52, 0.038), Vector3(0, 0.43, 0.025), "6E4A33", 0.0)
	for x in [-0.288, 0.288]:
		_box(self, Vector3(0.51, 0.40, 0.024), Vector3(x, 0.425, 0.054), "5A3B28", 0.0)
		_box(self, Vector3(0.455, 0.345, 0.018), Vector3(x, 0.425, 0.075), "8A6247", 0.0)
		_box(self, Vector3(0.405, 0.295, 0.012), Vector3(x, 0.425, 0.087), "6E4A33", 0.0)
	_box(self, Vector3(1.34, 0.052, 0.55), Vector3(0, 0.712, -0.005), "5A3B28")
	_box(self, Vector3(1.12, 0.027, 0.028), Vector3(0, 0.751, 0.26), "8A6247", 0.0)
	_box(self, Vector3(1.10, 0.012, 0.27), Vector3(0, 0.746, 0.109), "30261F", 0.0)
	_box(self, Vector3(1.10, 0.015, 0.025), Vector3(0, 0.760, -0.014), "30261F", 0.0)
	_box(self, Vector3(1.16, 0.105, 0.06), Vector3(0, 0.8375, -0.05), "6E4A33")
	_box(self, Vector3(1.12, 0.008, 0.009), Vector3(0, 0.802, -0.015), "C46A4A", 0.0)

	# The upper case is a frame around the mechanism, rather than a solid box behind it.
	_box(self, Vector3(1.16, 0.43, 0.025), Vector3(0, 1.085, -0.10), "30261F", 0.0)
	for x in [-0.46, 0.46]:
		_box(self, Vector3(0.24, 0.43, 0.12), Vector3(x, 1.085, -0.025), "6E4A33", 0.0)
		# The right panel is pierced separately for the coin channel.
		if x < 0:
			_box(self, Vector3(0.17, 0.31, 0.023), Vector3(x, 1.085, 0.047), "8A6247", 0.0)
	_box(self, Vector3(1.17, 0.09, 0.12), Vector3(0, 0.91, -0.025), "6E4A33", 0.0)
	_box(self, Vector3(1.17, 0.05, 0.12), Vector3(0, 1.275, -0.025), "6E4A33", 0.0)
	for x in [-0.348, 0.348]:
		_box(self, Vector3(0.026, 0.31, 0.04), Vector3(x, 1.105, 0.055), "8A6247", 0.0)
	for y in [0.955, 1.255]:
		_box(self, Vector3(0.72, 0.026, 0.04), Vector3(0, y, 0.055), "8A6247", 0.0)
	_box(self, Vector3(0.86, 0.022, 0.14), Vector3(0, 0.914, 0.09), "5A3B28")
	_box(self, Vector3(0.86, 0.017, 0.018), Vector3(0, 0.928, 0.151), "8A6247", 0.0)
	_box(self, Vector3(1.34, 0.028, 0.37), Vector3(0, 1.301, -0.095), "8A6247", 0.0)
	_box(self, Vector3(WIDTH, 0.045, 0.39), Vector3(0, HEIGHT - 0.0225, -0.085), "5A3B28", 0.0)

	_box(self, Vector3(0.28, 0.055, 0.04), Vector3(0, 0.145, 0.10), "30261F", 0.0)
	for x in [-0.085, 0.0, 0.085]:
		var pedal := _box(self, Vector3(0.022, 0.022, 0.13), Vector3(x, 0.115, 0.15), "B39459", 0.0)
		pedal.rotation.x = 0.22
		_box(self, Vector3(0.047, 0.018, 0.065), Vector3(x, 0.098, 0.226), "C9A04A", 0.0)

func _coin_slot() -> void:
	# The channel stays open through both wood and brass, and clears the entire edge-on coin.
	# Its projecting housing puts the existing insertion target at the case's foremost face.
	var centre := Vector2(SLOT_POSITION.x, SLOT_POSITION.y)
	_frame(centre, Vector2(0.145, 0.25), Vector2(0.026, 0.16), 0.114, 0.308, "5A3B28")
	_frame(centre, Vector2(0.118, 0.224), Vector2(0.022, 0.154), 0.274, 0.012, "B39459")
	for x in [-0.043, 0.043]:
		for y in [-0.093, 0.093]:
			var screw := ManorGeometry.cylinder(self, 0.004, 0.002, Vector3(centre.x + x, centre.y + y, 0.279), ManorGeometry.material("5A3B28", 0.0))
			screw.rotation.x = PI / 2

func _frame(centre: Vector2, size: Vector2, opening: Vector2, z: float, depth: float, color: String) -> void:
	for side in [-1, 1]:
		_box(self, Vector3((size.x - opening.x) / 2, size.y, depth), Vector3(centre.x + side * (size.x + opening.x) / 4, centre.y, z), color, 0.0)
		_box(self, Vector3(opening.x, (size.y - opening.y) / 2, depth), Vector3(centre.x, centre.y + side * (size.y + opening.y) / 4, z), color, 0.0)

func _keyboard() -> void:
	for i in 8:
		var group := Node3D.new()
		group.name = "KeyGroup%d" % i
		group.position = Vector3(0, 0.779, -0.025)
		add_child(group)
		_keys.append(group)
	var pitch := 1.075 / 42
	for i in 42:
		var x := (i - 20.5) * pitch
		var group := _keys[i % _keys.size()]
		_box(group, Vector3(pitch - 0.0018, 0.023, 0.252), Vector3(x, 0, 0.132), "E7E1D4", 0.0)
		if i % 7 in [0, 1, 3, 4, 5] and i < 41:
			_box(group, Vector3(0.015, 0.026, 0.14), Vector3(x + pitch / 2, 0.0245, 0.076), "30261F", 0.0)
	for group in _keys:
		_bake(group)
		ManorStaticBatch.combine(group)

func _roll_window() -> void:
	for y in [0.987, 1.227]:
		var spool := Node3D.new()
		spool.name = "PaperSpool"
		spool.position = Vector3(0, y, 0.008)
		add_child(spool)
		_spools.append(spool)
		ManorGeometry.cylinder(spool, 0.038, 0.55, Vector3.ZERO, ManorGeometry.material("E7E1D4", 0.0)).rotation.z = PI / 2
		for side in [-1, 1]:
			ManorGeometry.cylinder(spool, 0.042, 0.016, Vector3(side * 0.28, 0, 0), ManorGeometry.material("5A3B28", 0.0)).rotation.z = PI / 2
			ManorGeometry.cylinder(spool, 0.009, 0.065, Vector3(side * 0.312, 0, 0), ManorGeometry.material("B39459", 0.0)).rotation.z = PI / 2
			_box(spool, Vector3(0.004, 0.058, 0.006), Vector3(side * 0.289, 0, 0), "B39459", 0.0)
		_bake(spool)
		ManorStaticBatch.combine(spool)
		for x in [-0.327, 0.327]:
			_box(self, Vector3(0.022, 0.072, 0.075), Vector3(x, y, -0.011), "B39459", 0.0)
	# Actual perforations expose the dark recess; extra rows disappear behind the spool covers.
	var sheet := SurfaceTool.new()
	sheet.begin(Mesh.PRIMITIVE_TRIANGLES)
	for column in 22:
		for row in 12:
			var x := -0.264 + column * 0.024
			var y := 0.947 + row * 0.032
			if (column * 7 + (row % 2) * 11 + column * (row % 2)) % 13 < 4:
				_paper_rect(sheet, x, y, 0.008, 0.032)
				_paper_rect(sheet, x + 0.015, y, 0.009, 0.032)
				_paper_rect(sheet, x + 0.008, y, 0.007, 0.008)
				_paper_rect(sheet, x + 0.008, y + 0.024, 0.007, 0.008)
			else:
				_paper_rect(sheet, x, y, 0.024, 0.032)
	_paper = MeshInstance3D.new()
	_paper.name = "PerforatedPaper"
	(_paper as MeshInstance3D).mesh = sheet.commit()
	(_paper as MeshInstance3D).material_override = ManorGeometry.material("E7E1D4", 0.0)
	add_child(_paper)
	# These opaque covers hide the paper wrap without transparent glass or a new shader.
	_box(self, Vector3(0.64, 0.13, 0.035), Vector3(0, 0.916, 0.065), "5A3B28", 0.0)
	_box(self, Vector3(0.64, 0.10, 0.035), Vector3(0, 1.295, 0.065), "5A3B28", 0.0)
	for y in [0.976, 1.246]:
		_box(self, Vector3(0.60, 0.007, 0.012), Vector3(0, y, 0.087), "B39459", 0.0)

func set_playing(value: bool) -> void:
	playing = value
	set_process(value)
	if not value:
		for group in _keys:
			group.rotation.x = 0.0

func _process(delta: float) -> void:
	_time += delta
	for i in _keys.size():
		var beat := fposmod(_time * 2.8 + i * 0.73, 4.0)
		_keys[i].rotation.x = sin(beat * PI / 0.72) * 0.065 if beat < 0.72 else 0.0
	for spool in _spools:
		spool.rotation.x = fposmod(_time * 0.6, TAU)
	_paper.position.y = -fposmod(_time * 0.018, 0.064)

func _paper_rect(surface: SurfaceTool, x: float, y: float, width: float, height: float) -> void:
	var corners: Array[Vector3] = [Vector3(x, y, 0.039), Vector3(x + width, y, 0.039), Vector3(x, y + height, 0.039), Vector3(x + width, y + height, 0.039)]
	for index in [0, 2, 1, 1, 2, 3]:
		surface.set_normal(Vector3.BACK)
		surface.add_vertex(corners[index])

func _box(parent: Node3D, size: Vector3, at: Vector3, color: String, outline: float = 0.003) -> MeshInstance3D:
	return ManorGeometry.box(parent, size, at, ManorGeometry.material(color, outline))

func _bake(assembly: Node3D, skip: Array[Node] = []) -> void:
	var surfaces: Dictionary[Material, SurfaceTool] = {}
	for child in assembly.get_children():
		var piece := child as MeshInstance3D
		if piece == null or child in skip:
			continue
		var material := piece.material_override
		if not surfaces.has(material):
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			surfaces[material] = surface
		surfaces[material].append_from(piece.mesh, 0, piece.transform)
		piece.free()
	for material in surfaces:
		var mesh := MeshInstance3D.new()
		mesh.mesh = surfaces[material].commit()
		mesh.material_override = material
		assembly.add_child(mesh)
