class_name ManorMeadow
extends Node3D

const CELL_SIZE := 32.0
# Trees this close to the house are within sun-shadow range of house and lawn views.
const SHADOW_RADIUS := 46.0
const HOUSE := AABB(Vector3(-9.4, -0.2, -9.4), Vector3(18.8, 3.6, 18.8))
const HILLS: Array[Vector4] = [Vector4(-72, -48, 32, 5), Vector4(65, -62, 35, 6), Vector4(-79, 48, 28, 4), Vector4(80, 52, 32, 5), Vector4(0, -95, 50, 5)]
# The 15 trees nearest the house keep their composed window-view positions and heights.
const NEAR_TREES: Array[Vector4] = [
	Vector4(19, -8, 4.878, 0), Vector4(23, 7, 4.4, 0), Vector4(-22, 6, 3.443, 0), Vector4(-17, -20, 3.828, 1),
	Vector4(9, -23, 3.828, 0), Vector4(-25, -4, 3.443, 0), Vector4(-18, 10, 3.5, 0), Vector4(-9, -19, 3.8, 0),
	Vector4(1, -21, 4.1, 0), Vector4(18, -16, 4.4, 1), Vector4(21, 1, 3.5, 0), Vector4(26, 14, 3.8, 1),
	Vector4(-27, 15, 4.1, 1), Vector4(-28, -16, 4.4, 0),
]
const WINDOW_TREE := Vector3(-17, 4.2, -6.9)
# x, z, spread, tree count; pines lead in alternate groves.
const GROVES: Array[Vector4] = [
	Vector4(-47, -27, 8, 6), Vector4(-15, -49, 9, 7), Vector4(25, -45, 8, 6), Vector4(53, -15, 7, 5),
	Vector4(49, 29, 8, 6), Vector4(-53, 23, 8, 6), Vector4(-35, 53, 7, 5), Vector4(37, 59, 7, 5),
]
const LONE_TREES: Array[Vector2] = [Vector2(64, 4), Vector2(-66, -3), Vector2(9, -70), Vector2(-31, -72)]
const TREELINE := Vector2(88, 104)
const TREELINE_SECTORS := 8
# Leave the sky behind the finale rainbow clear.
const SOUTH_GAP := 0.16

var ground_y := -0.15
var trees: Array[ManorTree] = []
var bushes: Array[Transform3D] = []
var treeline: Array[Transform3D] = []
var vegetation: Array[MeshInstance3D] = []
var parts: Dictionary[String, Array] = {}
var center_ground: Node3D
var center_collision: StaticBody3D

func build(ground_value: float, use_ground_height: bool) -> void:
	ground_y = ground_value
	var grass: ShaderMaterial = ManorGeometry.material("9DB86E", 0.0).duplicate()
	grass.set_shader_parameter("meadow", true)
	_build_ground(grass, ground_y if use_ground_height else -0.02)
	var island := ManorIsland.new()
	add_child(island)
	island.build(ground_y)
	var distant: ShaderMaterial = ManorGeometry.material("B9C98E", 0.0).duplicate()
	distant.set_shader_parameter("clip_below_ground", true)
	distant.set_shader_parameter("ground_level", ground_y)
	for data in HILLS:
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
	for i in NEAR_TREES.size():
		var data := NEAR_TREES[i]
		var pine := data.w > 0
		_plant(Vector2(data.x, data.y), data.z * (1.3 if pine else 1.0), ManorTree.Kind.PINE if pine else ManorTree.Kind.BROADLEAF, i, i * 1.7)
	var window_tree := _plant(Vector2(WINDOW_TREE.x, WINDOW_TREE.z), WINDOW_TREE.y, ManorTree.Kind.BROADLEAF, 2, 0.65)
	window_tree.name = "BedroomWindowTree"
	for g in GROVES.size():
		_plant_grove(GROVES[g], g, rng)
	for i in LONE_TREES.size():
		_plant(LONE_TREES[i], rng.randf_range(4.6, 5.8), ManorTree.Kind.BROADLEAF if i % 2 == 0 else ManorTree.Kind.PINE, i + 3, rng.randf_range(0, TAU))
	for tree in trees:
		var width := tree.tree_height * (1.0 + 0.04 * (tree.variation - 1.5))
		var cell := "%s_%d_%d" % ["cast" if tree.casts_shadow else "plain", floori(tree.position.x / CELL_SIZE), floori(tree.position.z / CELL_SIZE)]
		_part(cell, tree.model(), Transform3D(Basis(Vector3.UP, tree.rotation.y).scaled(Vector3(width, tree.tree_height, width)), tree.position))
	_plant_bushes(rng)
	_plant_treeline(rng)
	_merge()

func _build_ground(grass: Material, collision_y: float) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for rect in ManorGeometry.ground_surround():
		var shape := BoxMesh.new()
		shape.size = Vector3(rect.size.x, 0.2, rect.size.y)
		var at := Vector3(rect.get_center().x, ground_y - 0.1, rect.get_center().y)
		surface.append_from(shape, 0, Transform3D(Basis.IDENTITY, at))
		ManorGeometry.barrier(self, shape.size, Vector3(at.x, collision_y - 0.1, at.z))
	var ground := MeshInstance3D.new()
	ground.name = "GroundSurround"
	ground.mesh = surface.commit()
	ground.material_override = grass
	# The flat ground receives house shadows but must not shadow itself at grazing angles.
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ground)
	# A separate center keeps ordinary gaps walkable until the conservatory hatch opens.
	center_ground = Node3D.new()
	center_ground.name = "CenterGround"
	add_child(center_ground)
	var center := ManorGeometry.box(center_ground, Vector3(ManorGeometry.PITCH, 0.2, ManorGeometry.PITCH), Vector3(0, ground_y - 0.1, 0), grass)
	center.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	center_collision = ManorGeometry.barrier(center_ground, Vector3(ManorGeometry.PITCH, 0.2, ManorGeometry.PITCH), Vector3(0, collision_y - 0.1, 0))

func open_center() -> void:
	center_ground.hide()
	center_collision.collision_layer = 0

func _plant(at: Vector2, height_value: float, kind: ManorTree.Kind, variant: int, yaw: float) -> ManorTree:
	var tree := ManorTree.new()
	add_child(tree)
	tree.position = Vector3(at.x, ground_height(at) - 0.01, at.y)
	tree.rotation.y = yaw
	tree.setup(height_value, kind, variant, at.length() < SHADOW_RADIUS)
	trees.append(tree)
	return tree

# Groves read as natural clumps; members within shadow range avoid standing in each other's shadow.
func _plant_grove(grove: Vector4, index: int, rng: RandomNumberGenerator) -> void:
	var center := Vector2(grove.x, grove.y)
	var pine_lead := index % 2 == 1
	var planted := 0
	for attempt in 200:
		if planted == int(grove.w):
			break
		var at := center + Vector2.from_angle(rng.randf_range(0, TAU)) * grove.z * sqrt(rng.randf())
		if not _open(at, 2.8):
			continue
		var pine := rng.randf() < (0.7 if pine_lead else 0.25)
		# Central trees are taller so each clump has a rounded skyline.
		var height_value := rng.randf_range(4.2, 5.6) * lerpf(1.15, 0.9, at.distance_to(center) / grove.z) * (1.3 if pine else 1.0)
		var tree := _plant(at, height_value, ManorTree.Kind.PINE if pine else ManorTree.Kind.BROADLEAF, planted + index, rng.randf_range(0, TAU))
		if tree.casts_shadow and not _shadow_clear(tree):
			trees.erase(tree)
			tree.free()
			continue
		planted += 1

func _open(at: Vector2, spacing: float) -> bool:
	if at.y > 0 and absf(at.x) < 24:
		return false
	for tree in trees:
		var flat := Vector2(tree.position.x, tree.position.z)
		# Groves keep the original 6 m breathing room around the composed near trees.
		if flat.distance_to(at) < (6.0 if flat.length() < 30 else spacing):
			return false
	return true

func _shadow_clear(tree: ManorTree) -> bool:
	var own: Dictionary = tree.crown()
	for other in trees:
		if other == tree or not other.casts_shadow:
			continue
		if shaded_by(other, own.center, 0.0) or shaded_by(tree, other.crown().center, 0.0):
			return false
	return true

# Unshaded foliage cannot darken in a cast shadow, so shrubs sit on the sunlit side of trees.
func _plant_bushes(rng: RandomNumberGenerator) -> void:
	var sunward := Vector2(ManorGeometry.to_sun().x, ManorGeometry.to_sun().z).normalized()
	var hosts: Array[ManorTree] = []
	for tree in trees:
		var flat := Vector2(tree.position.x, tree.position.z)
		if tree.name == "BedroomWindowTree" or (tree.casts_shadow and tree.kind == ManorTree.Kind.BROADLEAF and absf(flat.x) >= 18) or (not tree.casts_shadow and rng.randf() < 0.3):
			hosts.append(tree)
	for i in hosts.size():
		var tree := hosts[i]
		var flat := Vector2(tree.position.x, tree.position.z)
		var side := sunward.orthogonal() * rng.randf_range(-1.2, 1.2)
		for step in 6:
			var at: Vector2 = flat + sunward * (tree.crown().radius + 1.0 + step * 0.6) + side
			var size := rng.randf_range(1.2, 1.7)
			var bush := Transform3D(Basis(Vector3.UP, rng.randf_range(0, TAU)).scaled(Vector3(size, size * 0.85, size)), Vector3(at.x, ground_height(at) - 0.02, at.y))
			if (at.y > 0 and absf(at.x) < 15) or _clear_of_trunks(at) < 1.6 or shaded(bush.origin + Vector3.UP * 0.4, 0.5):
				continue
			bushes.append(bush)
			var cell := "%s_%d_%d" % ["cast" if at.length() < SHADOW_RADIUS else "plain", floori(at.x / CELL_SIZE), floori(at.y / CELL_SIZE)]
			_part(cell, ManorTree.bush_model(i), bush)
			break

func _clear_of_trunks(at: Vector2) -> float:
	var nearest := INF
	for tree in trees:
		nearest = minf(nearest, Vector2(tree.position.x, tree.position.z).distance_to(at))
	return nearest

# A hazy band of low-detail woodland closes the horizon; it is never seen up close from the house.
func _plant_treeline(rng: RandomNumberGenerator) -> void:
	var bodies: Array[StaticBody3D] = []
	for sector in TREELINE_SECTORS:
		var body := StaticBody3D.new()
		body.name = "TreelineTrunks%d" % sector
		add_child(body)
		bodies.append(body)
	for row in 3:
		var radius := lerpf(TREELINE.x, TREELINE.y, row / 2.0)
		var count := int(TAU * radius / 4.2)
		for i in count:
			var angle := (i + row * 0.37 + rng.randf_range(-0.3, 0.3)) * TAU / count
			var outward := Vector2(sin(angle), cos(angle))
			if absf(angle_difference(angle, 0.0)) < SOUTH_GAP:
				continue
			# Clumped density leaves occasional glades instead of an even fence.
			var density := 0.5 + 0.5 * sin(angle * 5.0 + 1.3) * cos(angle * 3.0 - 0.4)
			if rng.randf() > 0.45 + 0.55 * density:
				continue
			var at := outward * (radius + rng.randf_range(-2.5, 2.5))
			var pine := rng.randf() < 0.55
			var height_value := rng.randf_range(7.0, 10.5) * (1.2 if pine else 1.0)
			var width := height_value * rng.randf_range(1.0, 1.2)
			var place := Transform3D(Basis(Vector3.UP, rng.randf_range(0, TAU)).scaled(Vector3(width, height_value, width)), Vector3(at.x, ground_height(at) - 0.01, at.y))
			treeline.append(place)
			var sector := posmod(floori(angle / TAU * TREELINE_SECTORS), TREELINE_SECTORS)
			_part("treeline_%d" % sector, ManorTree.tree_model(ManorTree.Kind.PINE if pine else ManorTree.Kind.BROADLEAF, i % ManorTree.VARIANTS, true), place)
			var trunk := CollisionShape3D.new()
			var shape := BoxShape3D.new()
			shape.size = Vector3(height_value * 0.08, height_value * 0.5, height_value * 0.08)
			trunk.shape = shape
			trunk.position = place.origin + Vector3.UP * height_value * 0.25
			bodies[sector].add_child(trunk)

func _part(key: String, mesh: Mesh, place: Transform3D) -> void:
	if not parts.has(key):
		parts[key] = []
	parts[key].append([mesh, place])

# One merged mesh per area replaces per-tree instances: a draw call per cell, not per model.
func _merge() -> void:
	for key in parts:
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for part in parts[key]:
			surface.append_from(part[0], 0, part[1])
		var node := MeshInstance3D.new()
		node.name = "Vegetation_" + key
		node.mesh = surface.commit()
		node.material_override = ManorTree.shared_material()
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if key.begins_with("cast") else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
		vegetation.append(node)
	parts.clear()

func ground_height(at: Vector2) -> float:
	var height := ground_y
	for hill in HILLS:
		var reach := 1.0 - pow((at.x - hill.x) / hill.z, 2) - pow((at.y - hill.y) / (hill.z * 0.75), 2)
		# The faceted hill mesh dips below the ideal ellipsoid between vertices, so settle
		# hillside trunks into it rather than letting them float.
		if reach > 0:
			height = maxf(height, -2.5 + hill.w * sqrt(reach) - 0.6)
	return height

func shaded(point: Vector3, margin: float) -> bool:
	if HOUSE.intersects_ray(point, ManorGeometry.to_sun()) != null:
		return true
	for tree in trees:
		if tree.casts_shadow and shaded_by(tree, point, margin):
			return true
	return false

## Whether a sun ray from `point` passes through the tree's crown or trunk.
static func shaded_by(tree: ManorTree, point: Vector3, margin: float) -> bool:
	var to_sun := ManorGeometry.to_sun()
	var crown: Dictionary = tree.crown()
	var blockers: Array[Vector4] = [Vector4(crown.center.x, crown.center.y, crown.center.z, crown.radius)]
	for share in [0.15, 0.3, 0.45]:
		var at: Vector3 = tree.position + Vector3.UP * tree.tree_height * share
		blockers.append(Vector4(at.x, at.y, at.z, tree.tree_height * 0.05))
	for blocker in blockers:
		var offset := Vector3(blocker.x, blocker.y, blocker.z) - point
		var along := offset.dot(to_sun)
		if along > 0 and (offset - to_sun * along).length() < blocker.w + margin:
			return true
	return false
