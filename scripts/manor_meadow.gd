class_name ManorMeadow
extends Node3D

const TREE_CHUNK_SIZE := 24.0
var tree_chunks: Dictionary[Vector2i, Node3D] = {}

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
		var tree := _add_tree(at, ground_y, rng.randf_range(3.2, 5.0), i, true)
		tree.rotation.y = i * 2.4
	var originals: Array[Node] = find_children("*", "ManorTree", true, false)
	var nearer: Array[Vector2] = [Vector2(19, -8), Vector2(23, 7), Vector2(-22, 6), Vector2(-17, -20), Vector2(9, -23), Vector2(-25, -4)]
	for i in nearer.size():
		var source := _nearest(originals, nearer[i])
		var tree := _add_tree(Vector3(nearer[i].x, 0, nearer[i].y), ground_y, source.tree_height, source.variation, false)
		tree.rotation.y = i * 1.7
	# Preserve the closest tree and the opening Bedroom window composition.
	var window_tree := _add_tree(Vector3(-17, 0, -6.9), ground_y, 4.2, 22, false)
	window_tree.name = "BedroomWindowTree"
	window_tree.rotation.y = 0.65
	var additions: Array[Vector2] = [Vector2(-18, 10), Vector2(-9, -19), Vector2(1, -21), Vector2(18, -16), Vector2(21, 1), Vector2(26, 14), Vector2(-27, 15), Vector2(-28, -16)]
	for i in additions.size():
		var tree := _add_tree(Vector3(additions[i].x, 0, additions[i].y), ground_y, 3.5 + (i % 4) * 0.3, i, false)
		tree.rotation.y = i * 1.3
		tree.set_meta("added_tree", true)
	var occupied: Array[Vector3] = []
	for tree: ManorTree in find_children("*", "ManorTree", true, false):
		occupied.append(tree.position)
	var added := 0
	for attempt in 240:
		if added == 24:
			break
		var angle := rng.randf_range(0, TAU)
		var at := Vector3(cos(angle), 0, sin(angle)) * rng.randf_range(34, 86)
		if (at.z > 0 and absf(at.x) < 24) or occupied.any(func(other: Vector3) -> bool: return Vector2(at.x - other.x, at.z - other.z).length() < 6):
			continue
		var tree := _add_tree(at, ground_y, rng.randf_range(3.4, 5.2), added, true)
		tree.set_meta("added_tree", true)
		occupied.append(at)
		added += 1
	var bush_positions: Array[Vector2] = [Vector2(15, -14), Vector2(24, -10), Vector2(26, 5), Vector2(-19, 9), Vector2(-24, -3)]
	for at in bush_positions:
		var bush := MeshInstance3D.new()
		bush.name = "Bush"
		bush.mesh = ManorTree.bush_mesh()
		bush.material_override = ManorTree.shared_material(false)
		_chunk(Vector3(at.x, 0, at.y)).add_child(bush)
		bush.position = Vector3(at.x, ground_y, at.y)
	# Small spatial batches retain useful culling without per-frame tree scripts.
	for chunk in tree_chunks.values():
		ManorStaticBatch.combine(chunk)
	var skip: Array[Node] = []
	skip.assign(tree_chunks.values())
	ManorStaticBatch.combine(self, skip)

func _chunk(at: Vector3) -> Node3D:
	var cell := Vector2i(floori(at.x / TREE_CHUNK_SIZE), floori(at.z / TREE_CHUNK_SIZE))
	if not tree_chunks.has(cell):
		var chunk := Node3D.new()
		chunk.name = "Trees_%d_%d" % [cell.x, cell.y]
		add_child(chunk)
		tree_chunks[cell] = chunk
	return tree_chunks[cell]

func _add_tree(at: Vector3, ground_y: float, height_value: float, variant: int, flat: bool) -> ManorTree:
	var tree := ManorTree.new()
	_chunk(at).add_child(tree)
	tree.position = at + Vector3.UP * (ground_y - 0.01)
	tree.build(height_value, variant, flat)
	return tree

func _nearest(trees: Array[Node], at: Vector2) -> ManorTree:
	var nearest: ManorTree = trees[0]
	for tree: ManorTree in trees:
		if Vector2(tree.position.x, tree.position.z).distance_squared_to(at) < Vector2(nearest.position.x, nearest.position.z).distance_squared_to(at):
			nearest = tree
	return nearest
