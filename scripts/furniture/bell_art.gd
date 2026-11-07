class_name ManorBellArt
extends Node3D
## Origin on the wall surface; +Z points into the room.

const HIT_SIZE := Vector3(0.34, 0.50, 0.22)
const HIT_CENTER := Vector3(0, -0.04, 0.11)
var swinger: Node3D
var motion: Tween

func _ready() -> void:
	var wood := ManorGeometry.material("5A3B28", 0.003)
	var brass := ManorGeometry.material("B39459", 0.0)
	ManorGeometry.box(self, Vector3(0.12, 0.23, 0.024), Vector3(0, 0.07, 0.012), wood)
	for y in [-0.025, 0.155]:
		ManorGeometry.cylinder(self, 0.009, 0.005, Vector3(0, y, 0.026), brass).rotation.x = PI / 2

	# A bent strap meets the wall plate and the pivot, leaving the mouth clear below it.
	var bracket := SurfaceTool.new()
	bracket.begin(Mesh.PRIMITIVE_TRIANGLES)
	var path: Array[Vector2] = [Vector2(0.021, 0.125), Vector2(0.065, 0.125), Vector2(0.122, 0.105)]
	for i in range(path.size() - 1):
		var a := Vector3(0, path[i].y, path[i].x)
		var b := Vector3(0, path[i + 1].y, path[i + 1].x)
		var strap := ManorGeometry.box(self, Vector3(0.026, 0.012, a.distance_to(b) + 0.008), (a + b) / 2, brass)
		strap.rotation.x = -atan2(b.y - a.y, b.z - a.z)
		bracket.append_from(strap.mesh, 0, strap.transform)
		strap.free()
	_mesh(self, bracket.commit(), brass)

	swinger = Node3D.new()
	swinger.name = "BellPivot"
	swinger.position = Vector3(0, 0.105, 0.122)
	add_child(swinger)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# The profile returns up the inside: the mouth is open, with a thick rolled lip.
	var cup: Array[Vector2] = [
		Vector2(0, 0.004), Vector2(0.012, 0.004), Vector2(0.012, -0.029),
		Vector2(0.028, -0.032), Vector2(0.038, -0.044), Vector2(0.043, -0.068),
		Vector2(0.050, -0.105), Vector2(0.065, -0.143), Vector2(0.083, -0.162),
		Vector2(0.095, -0.166), Vector2(0.095, -0.177), Vector2(0.086, -0.181),
		Vector2(0.079, -0.169), Vector2(0.058, -0.149), Vector2(0.043, -0.109),
		Vector2(0.035, -0.073), Vector2(0.025, -0.053), Vector2(0, -0.053),
	]
	_lathe(surface, cup, 12)
	# The clapper is joined to the crown inside the shell, and projects below the rim.
	var clapper: Array[Vector2] = [
		Vector2(0, -0.050), Vector2(0.004, -0.050), Vector2(0.004, -0.174),
		Vector2(0.014, -0.180), Vector2(0.017, -0.191), Vector2(0.012, -0.203),
		Vector2(0, -0.207),
	]
	_lathe(surface, clapper, 99)
	surface.generate_normals()
	_mesh(swinger, surface.commit(), ManorGeometry.vertex_color_material("B39459", 0.002))
	ManorStaticBatch.combine(swinger)
	ManorStaticBatch.combine(self, [swinger])

func swing() -> void:
	if motion != null:
		motion.kill()
	swinger.rotation = Vector3.ZERO
	motion = create_tween()
	motion.tween_property(swinger, "rotation:z", 0.18, 0.065).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for angle: float in [-0.14, 0.10, -0.065, 0.038, -0.018, 0.0]:
		motion.tween_property(swinger, "rotation:z", angle, 0.19).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	motion.finished.connect(func() -> void:
		swinger.rotation = Vector3.ZERO
		motion = null)

func _lathe(surface: SurfaceTool, profile: Array[Vector2], inside_start: int) -> void:
	for p in range(profile.size() - 1):
		for segment in 24:
			var corners: Array[Vector3] = []
			for pair: Vector2i in [Vector2i(p, segment), Vector2i(p, segment + 1), Vector2i(p + 1, segment), Vector2i(p + 1, segment + 1)]:
				var angle := pair.y * TAU / 24
				var section := profile[pair.x]
				corners.append(Vector3(cos(angle) * section.x, section.y, sin(angle) * section.x))
			var facet := 0.91 + 0.09 * cos((segment + 0.5) * TAU / 24 + 0.65)
			var tint := Color(facet, facet, facet)
			if p >= inside_start:
				tint *= Color("A69677")
			elif p in [9, 10]:
				tint *= 1.08
			for index in [0, 2, 1, 1, 2, 3]:
				surface.set_color(tint)
				surface.add_vertex(corners[index])

func _mesh(parent: Node3D, shape: ArrayMesh, material: Material) -> void:
	var node := MeshInstance3D.new()
	node.mesh = shape
	node.material_override = material
	parent.add_child(node)
