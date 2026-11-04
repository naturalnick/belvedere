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
	var trees := meadow.find_children("*", "ManorTree", true, false)
	check(trees.size() == 59, "expanded layout contains 59 trees")
	check(trees.filter(func(tree: ManorTree) -> bool: return tree.flat).size() == 44, "most trees use flat silhouettes")
	var added := 0
	for tree: ManorTree in trees:
		check(tree.find_children("*", "CollisionShape3D", true, false).size() == 1, "tree trunk collision survives visual batching")
		if tree.has_meta("added_tree"):
			added += 1
			var edge_distance := Vector2(maxf(absf(tree.position.x) - 9.375, 0), maxf(absf(tree.position.z) - 9.375, 0)).length()
			check(edge_distance >= 7.625, "added trees stay outside the closest existing tree's house clearance")
			check(Vector2(tree.position.x, tree.position.z).length() >= Vector2(-17, -6.9).length(), "added trees stay beyond the closest existing radius")
			if tree.flat:
				check(tree.position.z <= 0 or absf(tree.position.x) >= 24, "distant additions keep the south approach open")
	check(added == 32, "eight nearer trees and 24 distant trees were added")
	var window_tree: ManorTree = meadow.find_child("BedroomWindowTree", true, false)
	check(window_tree != null and not window_tree.flat and window_tree.position.is_equal_approx(Vector3(-17, -0.05, -6.9)), "opening window keeps its original closest 3D tree")
	var instances: Dictionary[int, int] = {}
	var resources: Dictionary[int, bool] = {}
	for chunk in meadow.tree_chunks.values():
		for geometry in chunk.find_children("*", "GeometryInstance3D", true, false):
			var mesh: Mesh = geometry.multimesh.mesh if geometry is MultiMeshInstance3D else geometry.mesh
			var count: int = geometry.multimesh.instance_count if geometry is MultiMeshInstance3D else 1
			var id := mesh.get_instance_id()
			instances[id] = instances.get(id, 0) + count
			resources[id] = true
			check(geometry.material_override.next_pass == null, "vegetation does not add outline passes")
			if mesh == ManorTree.shared_mesh(true):
				check(geometry.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "flat distant trees add no shadow passes")
				var bounds: AABB = geometry.multimesh.custom_aabb if geometry is MultiMeshInstance3D else geometry.custom_aabb
				check(bounds.size.z > 0.9, "billboard bounds cover rotation rather than just the flat mesh")
	check(resources.size() == 3, "all vegetation shares one solid tree, one flat tree and one bush mesh")
	check(instances.get(ManorTree.shared_mesh(false).get_instance_id(), 0) == 15, "all 15 solid trees survive batching")
	check(instances.get(ManorTree.shared_mesh(true).get_instance_id(), 0) == 44, "all 44 flat trees survive batching")
	check(instances.get(ManorTree.bush_mesh().get_instance_id(), 0) == 5, "all five bushes survive batching")
	for flat in [false, true]:
		var mesh := ManorTree.shared_mesh(flat)
		var triangles := mesh.surface_get_array_len(0) / 3
		check(triangles <= (20 if flat else 200), "tree mesh stays within its geometry budget")
		print("%s tree: %d triangles" % ["Flat" if flat else "Solid", triangles])
	meadow.queue_free()
	await process_frame
	print("Vegetation: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
