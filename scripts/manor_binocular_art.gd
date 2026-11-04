class_name ManorBinocularArt
extends RefCounted

const EYE_SPACING := 0.062
const EYE_RADIUS := 0.053
const EYE_FRONT := 0.148

static func model(parent: Node3D) -> Node3D:
	var item := Node3D.new()
	item.name = "Binoculars"
	parent.add_child(item)
	var leather := ManorGeometry.material("35423D", 0.002)
	var brass := ManorGeometry.material("B39459", 0.001)
	var rubber := ManorGeometry.material("202A28", 0.0)
	var lens := ManorGeometry.material("436775", 0.0)
	for side in [-1, 1]:
		var front := Vector3(side * 0.095, 0, -0.125)
		var back := Vector3(side * EYE_SPACING, 0, 0.085)
		var shape := CylinderMesh.new()
		shape.top_radius = 0.053
		shape.bottom_radius = 0.078
		shape.height = front.distance_to(back)
		shape.radial_segments = 32
		var barrel := MeshInstance3D.new()
		barrel.mesh = shape
		barrel.material_override = leather
		item.add_child(barrel)
		barrel.position = (front + back) / 2
		barrel.quaternion = Quaternion(Vector3.UP, (back - front).normalized())
		ManorGeometry.cylinder(item, 0.083, 0.024, Vector3(front.x, 0, -0.14), brass).rotation.x = PI / 2
		ManorGeometry.cylinder(item, 0.071, 0.006, Vector3(front.x, 0, -0.155), lens).rotation.x = PI / 2
		ManorGeometry.cylinder(item, 0.055, 0.016, Vector3(back.x, 0, 0.085), brass).rotation.x = PI / 2
		ManorGeometry.cylinder(item, 0.051, 0.04, Vector3(back.x, 0, 0.114), rubber).rotation.x = PI / 2
		var eyecup := MeshInstance3D.new()
		eyecup.name = "LeftEyecup" if side < 0 else "RightEyecup"
		var ring := TorusMesh.new()
		ring.inner_radius = 0.038
		ring.outer_radius = EYE_RADIUS
		ring.rings = 32
		ring.ring_segments = 12
		eyecup.mesh = ring
		eyecup.material_override = rubber
		item.add_child(eyecup)
		eyecup.position = Vector3(back.x, 0, 0.1405)
		eyecup.rotation.x = PI / 2
		ManorGeometry.cylinder(item, 0.038, 0.004, Vector3(back.x, 0, 0.137), lens).rotation.x = PI / 2
	ManorGeometry.box(item, Vector3(0.125, 0.032, 0.075), Vector3(0, 0, 0.015), brass)
	ManorGeometry.cylinder(item, 0.024, 0.055, Vector3(0, 0.028, 0.01), rubber).rotation.x = PI / 2
	for mesh: MeshInstance3D in item.find_children("*", "MeshInstance3D", true, false):
		# These rims fill the screen during use; retain round silhouettes at that distance.
		if mesh.mesh is CylinderMesh:
			var cylinder: CylinderMesh = mesh.mesh.duplicate()
			cylinder.radial_segments = 32
			mesh.mesh = cylinder
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return item

static func draw_icon(canvas: Control, at: Vector2, scale_value: float = 1.0) -> void:
	var ink := Color("202D29")
	var leather := Color("43564A")
	var brass := Color("D8BF83")
	canvas.draw_line(at + Vector2(-8, -3) * scale_value, at + Vector2(8, -3) * scale_value, ink, 7 * scale_value, true)
	canvas.draw_line(at + Vector2(-8, -4) * scale_value, at + Vector2(8, -4) * scale_value, brass, 3 * scale_value, true)
	for side in [-1, 1]:
		var eye := at + Vector2(side * 7, -9) * scale_value
		var center := at + Vector2(side * 9.5, 5) * scale_value
		canvas.draw_circle(eye, 5 * scale_value, ink, true, -1.0, true)
		var body := PackedVector2Array([
			eye + Vector2(-4.5, 0) * scale_value,
			eye + Vector2(4.5, 0) * scale_value,
			center + Vector2(8, 0) * scale_value,
			center + Vector2(-8, 0) * scale_value,
		])
		canvas.draw_colored_polygon(body, leather)
		canvas.draw_polyline(PackedVector2Array([body[3], body[0], body[1], body[2]]), ink, 1.5 * scale_value, true)
		canvas.draw_line(eye + Vector2(-3, -1) * scale_value, eye + Vector2(3, -1) * scale_value, brass, scale_value, true)
		canvas.draw_circle(center, 8.8 * scale_value, ink, true, -1.0, true)
		canvas.draw_circle(center, 7.3 * scale_value, brass, true, -1.0, true)
		canvas.draw_circle(center, 5.6 * scale_value, Color("29434C"), true, -1.0, true)
		canvas.draw_circle(center + Vector2(0.7, 1) * scale_value, 3.7 * scale_value, Color("527D8A"), true, -1.0, true)
		canvas.draw_arc(center, 4 * scale_value, PI * 1.08, PI * 1.62, 12, Color("C1DCE0"), 1.3 * scale_value, true)
	canvas.draw_rect(Rect2(at + Vector2(-2.5, -8) * scale_value, Vector2(5, 7) * scale_value), ink)
