class_name ManorSunReach
extends RefCounted
## The sun is fixed and rooms only slide, so furniture the sun cannot reach through its own
## room's openings is already in shadow everywhere and adds nothing to the shadow map.

const INNER_FACE := 3.0
const WINDOW_SPANS: Array[Vector2] = [Vector2(-2.3, -0.9), Vector2(0.9, 2.3)]
const WINDOW_HEIGHT := Vector2(0.9, 2.4)
const DOOR_SPANS: Array[Vector2] = [Vector2(-0.6, 0.6)]
# Lintels hide in the binocular overview, so treat doorways as open to the ceiling.
const DOOR_HEIGHT := Vector2(0.0, 3.0)

static func trim_casters(room: ManorRoom, furniture: Node3D) -> void:
	for geometry: GeometryInstance3D in furniture.find_children("*", "GeometryInstance3D", true, false):
		if geometry.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			continue
		if not boxes_in_room(geometry, room).any(func(box: AABB) -> bool: return sunlit(room.room_id, box)):
			geometry.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

static func boxes_in_room(geometry: GeometryInstance3D, room: Node3D) -> Array[AABB]:
	var local := Transform3D()
	var node: Node = geometry
	while node != room:
		local = (node as Node3D).transform * local
		node = node.get_parent()
	var boxes: Array[AABB] = []
	if geometry is MultiMeshInstance3D:
		var batch := geometry as MultiMeshInstance3D
		for i in batch.multimesh.instance_count:
			boxes.append(local * ManorStaticBatch.instance_transform(batch, i) * batch.multimesh.mesh.get_aabb())
	else:
		boxes.append(local * geometry.get_aabb())
	return boxes

## Conservative: projects the whole box along the sun ray onto each sunward wall and keeps it
## if that shadow-free footprint overlaps any opening, ignoring frames, leaves and other pieces.
static func sunlit(room_id: int, box: AABB) -> bool:
	var to_sun := ManorGeometry.to_sun()
	for d in 4:
		var normal: Vector3 = ManorGeometry.DIRECTIONS[d]
		var toward := to_sun.dot(normal)
		if toward <= 0.0:
			continue
		# Openings are symmetric about each wall's centre, so the tangent's sign does not matter.
		var across := Vector3(normal.z, 0, -normal.x)
		var low := Vector2(INF, INF)
		var high := Vector2(-INF, -INF)
		for corner in 8:
			var point := box.get_endpoint(corner)
			var hit := point + to_sun * (INNER_FACE - point.dot(normal)) / toward
			var flat := Vector2(hit.dot(across), hit.y)
			low = low.min(flat)
			high = high.max(flat)
		var window := ManorRules.side(room_id, d) == ManorRules.WINDOW
		var height := WINDOW_HEIGHT if window else DOOR_HEIGHT
		for span in WINDOW_SPANS if window else DOOR_SPANS:
			if low.x < span.y and high.x > span.x and low.y < height.y and high.y > height.x:
				return true
	return false
