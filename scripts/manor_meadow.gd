class_name ManorMeadow
extends Node3D

func build(ground_y: float, solid: bool) -> void:
	var grass: ShaderMaterial = ManorGeometry.material("9DB86E", 0.0).duplicate()
	grass.set_shader_parameter("meadow", true)
	var ground := ManorGeometry.box(self, Vector3(220, 0.2, 220), Vector3(0, ground_y - 0.1, 0), grass, solid)
	# The flat ground receives house shadows but must not shadow itself at grazing angles.
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var island := ManorIsland.new()
	add_child(island)
	island.build(ground_y)
	var distant: ShaderMaterial = ManorGeometry.material("B9C98E", 0.0).duplicate()
	distant.set_shader_parameter("clip_below_ground", true)
	distant.set_shader_parameter("ground_level", ground_y)
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
	for i in 22:
		var angle := rng.randf_range(0, TAU)
		var at := Vector3(cos(angle), 0, sin(angle)) * rng.randf_range(38, 68)
		# Keep the carpet and rainbow approach open; trees only frame the meadow.
		if at.z > 0 and absf(at.x) < 24:
			continue
		var tree := ManorTree.new()
		add_child(tree)
		tree.position = at + Vector3.UP * (ground_y - 0.01)
		tree.rotation.y = i * 2.4
		tree.build(rng.randf_range(3.2, 5.0), i)
	var originals: Array[Node] = find_children("*", "ManorTree", false, false)
	var nearer: Array[Vector2] = [Vector2(19, -8), Vector2(23, 7), Vector2(-22, 6), Vector2(-17, -20), Vector2(9, -23), Vector2(-25, -4)]
	for i in nearer.size():
		# Reuse complete original mesh resources, retaining their grain and silhouette.
		var tree: ManorTree = _nearest(originals, nearer[i]).duplicate()
		add_child(tree)
		tree.position = Vector3(nearer[i].x, ground_y - 0.01, nearer[i].y)
		tree.rotation.y = i * 1.7
	# Frame the right Bedroom window from the opening view without hiding the trunk behind its mullion.
	var window_tree := ManorTree.new()
	window_tree.name = "BedroomWindowTree"
	add_child(window_tree)
	window_tree.position = Vector3(-17, ground_y - 0.01, -6.9)
	window_tree.rotation.y = 0.65
	window_tree.build(4.2, 22)
	var bush_positions: Array[Vector2] = [Vector2(15, -14), Vector2(24, -10), Vector2(26, 5), Vector2(-19, 9), Vector2(-24, -3)]
	for at in bush_positions:
		var source: MeshInstance3D = _nearest(originals, at).foliage_prototype()
		var bush := Node3D.new()
		bush.name = "Bush"
		add_child(bush)
		bush.position = Vector3(at.x, ground_y, at.y)
		for i in 3:
			var leaves := MeshInstance3D.new()
			leaves.mesh = source.mesh
			leaves.material_override = source.material_override
			bush.add_child(leaves)
			leaves.position = Vector3((i - 1) * 0.45, 0.35 + i * 0.06, (i % 2) * 0.25)
			leaves.scale = Vector3(0.65, 0.45, 0.6)
			leaves.rotation.y = i * 2.1
	ManorStaticBatch.combine(self)

func _nearest(trees: Array[Node], at: Vector2) -> ManorTree:
	var nearest: ManorTree = trees[0]
	for tree: ManorTree in trees:
		if Vector2(tree.position.x, tree.position.z).distance_squared_to(at) < Vector2(nearest.position.x, nearest.position.z).distance_squared_to(at):
			nearest = tree
	return nearest
