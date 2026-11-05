class_name ManorIsland
extends MeshInstance3D

const DEPTH := 12.0
const QR_SIZE := 176.0
const QR_TEXTURE := preload("res://assets/belvedere_assembly_qr.png")

func build(ground_y: float) -> void:
	name = "IslandBase"
	mesh = _casing_mesh()
	material_override = ManorGeometry.material("252D2B", 0.0)
	position.y = ground_y - 0.2 - DEPTH / 2
	# This is scenery below the existing walking surface, never a fall-catching collider.
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var code := MeshInstance3D.new()
	code.name = "AssemblyQR"
	var panel := QuadMesh.new()
	panel.size = Vector2.ONE * QR_SIZE
	code.mesh = panel
	var ink := StandardMaterial3D.new()
	ink.albedo_texture = QR_TEXTURE
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	code.material_override = ink
	code.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(code)
	code.position.y = -DEPTH / 2
	code.rotation.x = PI / 2

func _casing_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for rect in ManorGeometry.ground_surround():
		_face(surface, rect.size, Vector3(rect.get_center().x, DEPTH / 2, rect.get_center().y), Vector3(-PI / 2, 0, 0))
	for side in [-1, 1]:
		_face(surface, Vector2(220, DEPTH), Vector3(side * 110, 0, 0), Vector3(0, side * PI / 2, 0))
		_face(surface, Vector2(220, DEPTH), Vector3(0, 0, side * 110), Vector3(0, PI if side < 0 else 0.0, 0))
	# Leave an exact opening for the QR: near-coplanar backing flickers at fall distances.
	var border := (220 - QR_SIZE) / 2
	var center := (220 + QR_SIZE) / 4
	for side in [-1, 1]:
		_face(surface, Vector2(220, border), Vector3(0, -DEPTH / 2, side * center), Vector3(PI / 2, 0, 0))
		_face(surface, Vector2(border, QR_SIZE), Vector3(side * center, -DEPTH / 2, 0), Vector3(PI / 2, 0, 0))
	return surface.commit()

func _face(surface: SurfaceTool, size: Vector2, at: Vector3, rotation: Vector3) -> void:
	var face := QuadMesh.new()
	face.size = size
	surface.append_from(face, 0, Transform3D(Basis.from_euler(rotation), at))
