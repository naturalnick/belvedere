class_name ManorStaticBatch
extends RefCounted

## Only call on a rigid assembly: all descendants must move together.
static func combine(assembly: Node3D) -> void:
	var groups: Dictionary[String, Array] = {}
	for node in assembly.find_children("*", "MeshInstance3D", true, false):
		var piece := node as MeshInstance3D
		# Transparent panes retain their individual sorting and culling.
		if not piece.material_override is ShaderMaterial or piece.get_child_count() != 0:
			continue
		var key := "%d:%d:%d" % [piece.mesh.get_instance_id(), piece.material_override.get_instance_id(), piece.cast_shadow]
		if not groups.has(key):
			groups[key] = []
		groups[key].append(piece)
	for pieces in groups.values():
		if pieces.size() < 2:
			continue
		var first: MeshInstance3D = pieces[0]
		var batch := MultiMeshInstance3D.new()
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.mesh = first.mesh
		instances.instance_count = pieces.size()
		batch.multimesh = instances
		batch.material_override = first.material_override
		batch.cast_shadow = first.cast_shadow
		assembly.add_child(batch)
		var transforms: Array[Transform3D] = []
		for i in pieces.size():
			var piece: MeshInstance3D = pieces[i]
			var transform := assembly.global_transform.affine_inverse() * piece.global_transform
			transforms.append(transform)
			instances.set_instance_transform(i, transform)
			piece.get_parent().remove_child(piece)
			piece.queue_free()
		# The headless dummy renderer does not retain MultiMesh instance transforms.
		if DisplayServer.get_name() == "headless":
			batch.set_meta("test_transforms", transforms)

static func instance_transform(batch: MultiMeshInstance3D, index: int) -> Transform3D:
	if batch.has_meta("test_transforms"):
		return batch.get_meta("test_transforms")[index]
	return batch.multimesh.get_instance_transform(index)
