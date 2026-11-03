class_name ManorGeometry
extends RefCounted

const PITCH := 6.25
const DIRECTIONS := [Vector3.FORWARD, Vector3.RIGHT, Vector3.BACK, Vector3.LEFT]
const ACCENTS := {0: "7D97B8", 1: "8FC1B0", 2: "3F6B4F", 3: "D8A73A", 5: "C46A4A", 6: "7A4A6E", 7: "E6D3B0", 8: "5F7891"}
const FLOORS := {0: "B07A4E", 1: "E8E6DF", 2: "6E4A33", 3: "C47A54", 5: "B07A4E", 6: "8E4E36", 7: "A8724A", 8: "B8B4AA"}
static var materials: Dictionary[String, Material] = {}
static var boxes: Dictionary[Vector3, BoxMesh] = {}
static var cylinders: Dictionary[Vector2, CylinderMesh] = {}
static var grain: NoiseTexture2D

static func center(slot: int) -> Vector3:
	return Vector3((slot % 3 - 1) * PITCH, 0, (slot / 3 - 1) * PITCH)

static func build_gap_floor(parent: Node3D) -> void:
	if not materials.has("gap_tracks"):
		var concrete: ShaderMaterial = material("747B7D", 0.0).duplicate()
		concrete.set_shader_parameter("gap_tracks", true)
		materials["gap_tracks"] = concrete
	# Tracks are shaded into the slab: no raised faces or extra walking collisions.
	box(parent, Vector3(PITCH, 0.2, PITCH), Vector3(0, -0.1, 0), materials["gap_tracks"], true)

static func material(hex: String, outline: float = 0.012) -> Material:
	var key := hex + str(outline)
	if materials.has(key):
		return materials[key]
	if grain == null:
		grain = NoiseTexture2D.new()
		grain.width = 512
		grain.height = 512
		grain.seamless = true
		grain.generate_mipmaps = true
		var noise := FastNoiseLite.new()
		noise.seed = 73
		noise.frequency = 0.12
		noise.noise_type = FastNoiseLite.TYPE_VALUE
		grain.noise = noise
	var result := ShaderMaterial.new()
	result.shader = preload("res://shaders/toon.gdshader")
	result.set_shader_parameter("base_color", Color(hex))
	result.set_shader_parameter("paper_grain", grain)
	if outline > 0:
		var ink := ShaderMaterial.new()
		ink.shader = preload("res://shaders/outline.gdshader")
		ink.set_shader_parameter("width", outline)
		result.next_pass = ink
	materials[key] = result
	return result

static func floor_material(id: int) -> Material:
	var key := "floor_%d" % id
	if not materials.has(key):
		var floor_mat: ShaderMaterial = material(FLOORS[id], 0.0).duplicate()
		if id in [1, 3, 7, 8]:
			floor_mat.set_shader_parameter("floor_pattern", 2 if id == 7 else 1)
			floor_mat.set_shader_parameter("tile_size", 0.6 if id == 7 else 0.45)
			var grout := {1: "C9C5BA", 3: "A96F53", 7: "A69985", 8: "A3A197"}
			floor_mat.set_shader_parameter("grout_color", Color(grout[id]))
			if id == 7:
				floor_mat.set_shader_parameter("base_color", Color("EDE4D3"))
		else:
			floor_mat.set_shader_parameter("floor_pattern", 3)
		materials[key] = floor_mat
	return materials[key]

static func vertex_color_material(hex: String, outline: float) -> Material:
	var key := "vertex_%s%s" % [hex, outline]
	if not materials.has(key):
		var result: ShaderMaterial = material(hex, outline).duplicate()
		result.set_shader_parameter("vertex_colors", true)
		materials[key] = result
	return materials[key]

static func glass() -> Material:
	if not materials.has("glass"):
		var result := StandardMaterial3D.new()
		result.albedo_color = Color(0.81, 0.89, 0.90, 0.12)
		result.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		result.cull_mode = BaseMaterial3D.CULL_DISABLED
		result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		materials["glass"] = result
	return materials["glass"]

static func glowing_material(hex: String) -> Material:
	var key := "lit_" + hex
	if not materials.has(key):
		var result: ShaderMaterial = material(hex, 0.006).duplicate()
		result.set_shader_parameter("self_light", 0.7)
		materials[key] = result
	return materials[key]

static func box(parent: Node3D, size: Vector3, at: Vector3, mat: Material, solid: bool = false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	if not boxes.has(size):
		var mesh := BoxMesh.new()
		mesh.size = size
		boxes[size] = mesh
	node.mesh = boxes[size]
	node.material_override = mat
	parent.add_child(node)
	node.position = at
	if solid:
		barrier(parent, size, at)
	return node

static func barrier(parent: Node3D, size: Vector3, at: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cube := BoxShape3D.new()
	cube.size = size
	shape.shape = cube
	body.add_child(shape)
	parent.add_child(body)
	body.position = at
	return body

static func cylinder(parent: Node3D, radius: float, height: float, at: Vector3, mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var key := Vector2(radius, height)
	if not cylinders.has(key):
		var mesh := CylinderMesh.new()
		mesh.top_radius = radius
		mesh.bottom_radius = radius
		mesh.height = height
		mesh.radial_segments = 12
		cylinders[key] = mesh
	node.mesh = cylinders[key]
	node.material_override = mat
	parent.add_child(node)
	node.position = at
	return node
