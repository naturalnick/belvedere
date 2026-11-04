class_name ManorStaticBatch
extends RefCounted

static var fills: Dictionary[Material, Material] = {}

## Descendants must move together; `skip` excludes subtrees that animate, swap materials or batch separately.
static func combine(assembly: Node3D, skip: Array[Node] = []) -> void:
	var groups: Dictionary[String, Array] = {}
	for node in assembly.find_children("*", "MeshInstance3D", true, false):
		var piece := node as MeshInstance3D
		# Transparent panes retain their individual sorting and culling.
		if not piece.material_override is ShaderMaterial or piece.get_child_count() != 0:
			continue
		if skip.any(func(part: Node) -> bool: return part == piece or part.is_ancestor_of(piece)):
			continue
		var key := "%d:%d:%d" % [piece.mesh.get_instance_id(), piece.material_override.get_instance_id(), piece.cast_shadow]
		if not groups.has(key):
			groups[key] = []
		groups[key].append(piece)
	for pieces in groups.values():
		var first: MeshInstance3D = pieces[0]
		var outline := first.material_override.next_pass
		if pieces.size() < 2:
			if outline != null:
				first.material_override = _fill(first.material_override)
				var shell := MeshInstance3D.new()
				shell.mesh = first.mesh
				_shell(shell, outline)
				first.add_child(shell)
			continue
		var batch := MultiMeshInstance3D.new()
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.mesh = first.mesh
		instances.instance_count = pieces.size()
		batch.multimesh = instances
		batch.material_override = first.material_override if outline == null else _fill(first.material_override)
		batch.cast_shadow = first.cast_shadow
		assembly.add_child(batch)
		var transforms: Array[Transform3D] = []
		var bounds := AABB()
		for i in pieces.size():
			var piece: MeshInstance3D = pieces[i]
			var transform := assembly.global_transform.affine_inverse() * piece.global_transform
			transforms.append(transform)
			instances.set_instance_transform(i, transform)
			var local_bounds := piece.custom_aabb if piece.custom_aabb.size != Vector3.ZERO else piece.mesh.get_aabb()
			var piece_bounds: AABB = transform * local_bounds
			bounds = piece_bounds if i == 0 else bounds.merge(piece_bounds)
			piece.get_parent().remove_child(piece)
			piece.queue_free()
		# Preserve shader-expanded bounds, such as trees rotating to face the camera.
		instances.custom_aabb = bounds
		# The headless dummy renderer does not retain MultiMesh instance transforms.
		if DisplayServer.get_name() == "headless":
			batch.set_meta("test_transforms", transforms)
		if outline != null:
			var shell := MultiMeshInstance3D.new()
			shell.multimesh = instances
			_shell(shell, outline)
			assembly.add_child(shell)
			if batch.has_meta("test_transforms"):
				shell.set_meta("test_transforms", transforms)

static func instance_transform(batch: MultiMeshInstance3D, index: int) -> Transform3D:
	if batch.has_meta("test_transforms"):
		return batch.get_meta("test_transforms")[index]
	return batch.multimesh.get_instance_transform(index)

static func is_outline_shell(node: Node) -> bool:
	return node.has_meta("outline_shell")

# An outline pass would otherwise be drawn into the sun's shadow map as a second, invisible caster.
static func _shell(shell: GeometryInstance3D, outline: Material) -> void:
	shell.name = "OutlineShell"
	shell.material_override = outline
	shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shell.set_meta("outline_shell", true)

static func _fill(material: Material) -> Material:
	if not fills.has(material):
		var fill: Material = material.duplicate()
		fill.next_pass = null
		fills[material] = fill
	return fills[material]
