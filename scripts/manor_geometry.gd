class_name ManorGeometry
extends RefCounted

const PITCH := 6.25
const DIRECTIONS := [Vector3.FORWARD, Vector3.RIGHT, Vector3.BACK, Vector3.LEFT]
const ACCENTS := {0: "7D97B8", 1: "8FC1B0", 2: "3F6B4F", 3: "D8A73A", 5: "C46A4A", 6: "7A4A6E", 7: "E6D3B0", 8: "5F7891"}
const FLOORS := {0: "B07A4E", 1: "E8E6DF", 2: "6E4A33", 3: "C47A54", 5: "B07A4E", 6: "8E4E36", 7: "A8724A", 8: "B8B4AA"}
static var materials: Dictionary[String, Material] = {}
static var grain: NoiseTexture2D

static func center(slot: int) -> Vector3:
	return Vector3((slot % 3 - 1) * PITCH, 0, (slot / 3 - 1) * PITCH)

static func material(hex: String, outline: float = 0.012) -> Material:
	var key := hex + str(outline)
	if materials.has(key):
		return materials[key]
	if grain == null:
		grain = NoiseTexture2D.new()
		grain.width = 512
		grain.height = 512
		grain.seamless = true
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

static func glass() -> Material:
	if not materials.has("glass"):
		var result := StandardMaterial3D.new()
		result.albedo_color = Color(0.81, 0.89, 0.90, 0.12)
		result.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		result.cull_mode = BaseMaterial3D.CULL_DISABLED
		result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		materials["glass"] = result
	return materials["glass"]

static func box(parent: Node3D, size: Vector3, at: Vector3, mat: Material, solid: bool = false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
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
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	node.mesh = mesh
	node.material_override = mat
	parent.add_child(node)
	node.position = at
	return node
