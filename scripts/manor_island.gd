class_name ManorIsland
extends MeshInstance3D

func build(ground_y: float) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var profile: Array[Vector2] = []
	for i in 25:
		var angle := i * PI / 48.0
		profile.append(Vector2(cos(angle), -40 * sin(angle)))
	for ring in range(profile.size() - 1):
		for side in 96:
			var corners: Array[Vector3] = []
			for pair in [Vector2i(ring, side), Vector2i(ring, side + 1), Vector2i(ring + 1, side), Vector2i(ring + 1, side + 1)]:
				var angle: float = pair.y * TAU / 96.0
				var circle := Vector2(cos(angle), sin(angle))
				var square := circle / maxf(absf(circle.x), absf(circle.y))
				var p: Vector2 = square.lerp(circle, pair.x / float(profile.size() - 1)) * (110 * profile[pair.x].x)
				corners.append(Vector3(p.x, profile[pair.x].y, p.y))
			for index in [0, 2, 1, 1, 2, 3]:
				var tone := 1.0 + corners[index].y / 40.0 * 0.18
				surface.set_color(Color(tone, tone, tone))
				surface.add_vertex(corners[index])
	surface.generate_normals()
	mesh = surface.commit()
	var soil: ShaderMaterial = ManorGeometry.material("A79B7E", 0.0).duplicate()
	soil.set_shader_parameter("island_face", true)
	soil.set_shader_parameter("vertex_colors", true)
	material_override = soil
	position.y = ground_y - 0.2
	# This is scenery below the existing walking surface, never a fall-catching collider.
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
