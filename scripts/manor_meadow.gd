class_name ManorMeadow
extends Node3D

func build(ground_y: float, solid: bool) -> void:
	var grass: ShaderMaterial = ManorGeometry.material("9DB86E", 0.0).duplicate()
	grass.set_shader_parameter("meadow", true)
	var ground := ManorGeometry.box(self, Vector3(220, 0.2, 220), Vector3(0, ground_y - 0.1, 0), grass, solid)
	# The flat ground receives house shadows but must not shadow itself at grazing angles.
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var distant := ManorGeometry.material("B9C98E", 0.0)
	for data in [Vector4(-72, -48, 32, 5), Vector4(65, -62, 35, 6), Vector4(-79, 48, 28, 4), Vector4(80, 52, 32, 5), Vector4(0, -95, 50, 5)]:
		var hill := MeshInstance3D.new()
		var shape := SphereMesh.new()
		shape.radius = 1
		shape.height = 2
		shape.radial_segments = 24
		shape.rings = 8
		hill.mesh = shape
		hill.material_override = distant
		hill.position = Vector3(data.x, -2.5, data.y)
		hill.scale = Vector3(data.z, data.w, data.z * 0.75)
		add_child(hill)
	var rng := RandomNumberGenerator.new()
	rng.seed = 381
	var bark := ManorGeometry.material("8A8064", 0.0)
	var leaves := [ManorGeometry.material("9DAC7D", 0.0), ManorGeometry.material("AAB889", 0.0)]
	for i in 22:
		var angle := rng.randf_range(0, TAU)
		var at := Vector3(cos(angle), 0, sin(angle)) * rng.randf_range(38, 68)
		# Keep the carpet and rainbow approach open; trees only frame the meadow.
		if at.z > 0 and absf(at.x) < 24:
			continue
		var tree := Node3D.new()
		add_child(tree)
		tree.position = at
		var height_value := rng.randf_range(3.2, 5.0)
		ManorGeometry.cylinder(tree, 0.13, height_value * 0.55, Vector3(0, height_value * 0.275, 0), bark)
		ManorGeometry.barrier(tree, Vector3(0.26, height_value * 0.55, 0.26), Vector3(0, height_value * 0.275, 0))
		var canopy := MeshInstance3D.new()
		var shape := SphereMesh.new()
		shape.radius = 1
		shape.height = 2
		shape.radial_segments = 10
		shape.rings = 5
		canopy.mesh = shape
		canopy.material_override = leaves[i % 2]
		canopy.position.y = height_value * 0.72
		canopy.scale = Vector3(height_value * 0.32, height_value * 0.40, height_value * 0.30)
		tree.add_child(canopy)
