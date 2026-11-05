extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func run() -> void:
	var meadow := ManorMeadow.new()
	root.add_child(meadow)
	meadow.build(-0.04, true)
	await process_frame
	var trees: Array[ManorTree] = meadow.trees
	check(trees.size() == meadow.find_children("*", "ManorTree", true, false).size(), "every tree marker is tracked")
	check(trees.size() == 65, "15 near trees, 46 grove trees and four lone trees")
	var pines := trees.filter(func(tree: ManorTree) -> bool: return tree.kind == ManorTree.Kind.PINE).size()
	check(pines >= 15 and pines <= trees.size() - 30, "pines add variety without replacing broadleaf trees")
	for i in ManorMeadow.NEAR_TREES.size():
		var data := ManorMeadow.NEAR_TREES[i]
		check(trees.any(func(tree: ManorTree) -> bool: return tree.position.x == data.x and tree.position.z == data.y), "near tree %d keeps its composed position" % i)
	var window_tree: ManorTree = meadow.find_child("BedroomWindowTree", true, false)
	check(window_tree != null and window_tree.kind == ManorTree.Kind.BROADLEAF and window_tree.casts_shadow and window_tree.position.is_equal_approx(Vector3(-17, -0.05, -6.9)), "opening window keeps its original closest broadleaf tree")
	var closest_edge := 7.625
	for tree in trees:
		check(tree.find_children("*", "CollisionShape3D", true, false).size() == 1, "every tree keeps a trunk collision")
		var flat := Vector2(tree.position.x, tree.position.z)
		var edge_distance := Vector2(maxf(absf(flat.x) - 9.375, 0), maxf(absf(flat.y) - 9.375, 0)).length()
		check(edge_distance >= closest_edge, "no tree is closer to the house than the original closest tree")
		check(tree.casts_shadow == (flat.length() < ManorMeadow.SHADOW_RADIUS), "only trees within shadow range cast shadows")
		if flat.length() > 30:
			check(flat.y <= 0 or absf(flat.x) >= 24, "groves keep the south approach open")
			if tree.casts_shadow:
				for other in trees:
					if other != tree and other.casts_shadow:
						check(not ManorMeadow.shaded_by(other, tree.crown().center, 0.0), "casting grove trees do not stand in another tree's shadow")
	check(meadow.bushes.size() >= 12, "shrubs ground the near trees and groves")
	for bush in meadow.bushes:
		var flat := Vector2(bush.origin.x, bush.origin.z)
		check(not meadow.shaded(bush.origin + Vector3.UP * 0.4, 0.5), "shrub at %s sits in sunlight, clear of tree and house shadows" % flat)
		check(flat.y <= 0 or absf(flat.x) >= 15, "shrubs keep the carpet approach open")
	check(meadow.treeline.size() >= 200, "a woodland band closes the horizon")
	for place in meadow.treeline:
		var flat := Vector2(place.origin.x, place.origin.z)
		check(flat.length() > 84 and flat.length() < 108, "treeline stays inside the island edge")
		check(absf(angle_difference(atan2(flat.x, flat.y), 0.0)) >= ManorMeadow.SOUTH_GAP, "treeline leaves the sky behind the rainbow open")
	var trunks := 0
	for body in meadow.get_children():
		if body is StaticBody3D and str(body.name).begins_with("Treeline"):
			trunks += body.get_child_count()
	check(trunks == meadow.treeline.size(), "treeline trunks keep simple collisions")
	var triangles := 0
	for geometry in meadow.find_children("*", "GeometryInstance3D", true, false):
		if geometry.material_override == ManorTree.shared_material():
			check(meadow.vegetation.has(geometry), "foliage renders only through merged meshes")
	check(meadow.vegetation.size() <= 32, "merged foliage stays within its draw budget")
	for mesh in meadow.vegetation:
		triangles += mesh.mesh.surface_get_array_len(0) / 3
		check(mesh.material_override.next_pass == null, "vegetation adds no outline passes")
		var bounds := mesh.get_aabb()
		var far := Vector2(bounds.get_center().x, bounds.get_center().z).length() > ManorMeadow.SHADOW_RADIUS + ManorMeadow.CELL_SIZE
		if str(mesh.name).begins_with("Vegetation_treeline") or far:
			check(mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "distant foliage adds no shadow passes")
	for kind in [ManorTree.Kind.BROADLEAF, ManorTree.Kind.PINE]:
		for far in [false, true]:
			var count := ManorTree.tree_model(kind, 0, far).surface_get_array_len(0) / 3
			check(count <= (140 if far else 360), "tree model stays within its geometry budget")
			print("%s %s: %d triangles" % ["Pine" if kind == ManorTree.Kind.PINE else "Broadleaf", "far" if far else "near", count])
	check(triangles <= 60000, "all foliage stays within its triangle budget")
	print("Vegetation: %d trees, %d treeline, %d shrubs, %d meshes, %d triangles" % [trees.size(), meadow.treeline.size(), meadow.bushes.size(), meadow.vegetation.size(), triangles])
	await physics_frame
	var space := meadow.get_world_3d().direct_space_state
	var center_ray := PhysicsRayQueryParameters3D.create(Vector3(0, 1, 0), Vector3(0, -8, 0))
	check(not space.intersect_ray(center_ray).is_empty(), "ordinary center ground remains walkable before the reveal")
	meadow.open_center()
	await physics_frame
	check(space.intersect_ray(center_ray).is_empty(), "opening the center removes its walking surface")
	for point in [Vector3(-4, 0, 0), Vector3(4, 0, 0), Vector3(0, 0, -4), Vector3(0, 0, 4)]:
		var ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP, point + Vector3.DOWN)
		var hit := space.intersect_ray(ray)
		check(not hit.is_empty() and is_equal_approx(hit.position.y, -0.04), "shaft opening preserves the surrounding lawn collision")
	meadow.queue_free()
	await process_frame
	print("Vegetation: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
