class_name ManorTree
extends Node3D
## Layout and trunk-collision marker. The meadow merges all foliage into a few static meshes.

enum Kind { BROADLEAF, PINE }
const VARIANTS := 4
const TRUNK := Color("756D55")
const LEAVES: Array[Color] = [Color("93A673"), Color("9CAE7B"), Color("A3B482"), Color("8EA270")]
const NEEDLES: Array[Color] = [Color("74906C"), Color("7D9874"), Color("6F8A68")]
const SHRUB: Array[Color] = [Color("8FA668"), Color("98AE6E"), Color("88A063")]
static var models: Dictionary[String, ArrayMesh] = {}
static var material: ShaderMaterial
var tree_height := 4.0
var kind := Kind.BROADLEAF
var variation := 0
var casts_shadow := true

func setup(height_value: float, kind_value: Kind, variant: int, casts: bool) -> void:
	tree_height = height_value
	kind = kind_value
	variation = posmod(variant, VARIANTS)
	casts_shadow = casts
	ManorGeometry.barrier(self, Vector3(height_value * 0.08, height_value * 0.5, height_value * 0.08), Vector3(0, height_value * 0.25, 0))

func model(far: bool = false) -> ArrayMesh:
	return ManorTree.tree_model(kind, variation, far)

## Approximate foliage volume, used to keep shrubs and casting trees out of each other's shadows.
func crown() -> Dictionary:
	var center_height := 0.62 if kind == Kind.PINE else 0.66
	var radius := 0.26 if kind == Kind.PINE else 0.4
	return {"center": position + Vector3.UP * tree_height * center_height, "radius": tree_height * radius}

static func shared_material() -> ShaderMaterial:
	if material == null:
		material = ShaderMaterial.new()
		material.shader = preload("res://shaders/vegetation.gdshader")
	return material

static func tree_model(kind_value: Kind, variant: int, far: bool) -> ArrayMesh:
	var key := "%d:%d:%s" % [kind_value, variant, far]
	if not models.has(key):
		models[key] = _pine(variant, far) if kind_value == Kind.PINE else _broadleaf(variant, far)
	return models[key]

static func bush_model(variant: int) -> ArrayMesh:
	var key := "bush:%d" % posmod(variant, VARIANTS)
	if not models.has(key):
		var rng := _rng(900 + variant)
		var surface := _begin()
		# Many small leafy lobes give a soft, bumpy outline instead of a faceted boulder.
		var lobes: Array[Vector4] = [Vector4(0, 0.42, 0, 0.42)]
		var ring := 5 + variant % 2
		for i in ring:
			var angle := i * TAU / ring + rng.randf_range(-0.35, 0.35)
			var reach := rng.randf_range(0.34, 0.46)
			lobes.append(Vector4(cos(angle) * reach, rng.randf_range(0.24, 0.32), sin(angle) * reach * 0.85, rng.randf_range(0.24, 0.3)))
		for i in 2:
			var angle := rng.randf_range(0, TAU)
			lobes.append(Vector4(cos(angle) * 0.16, rng.randf_range(0.66, 0.74), sin(angle) * 0.16, rng.randf_range(0.2, 0.25)))
		for i in lobes.size():
			var lobe := lobes[i]
			_blob(surface, Vector3(lobe.x, lobe.y, lobe.z), Vector3(lobe.w, lobe.w * 0.85, lobe.w), SHRUB[(variant + i) % SHRUB.size()], rng, 8, 4, Vector2(0.0, 0.95))
		models[key] = surface.commit()
	return models[key]

# Rounded deciduous crown: a dome of overlapping lobes rather than stacked flat discs.
static func _broadleaf(variant: int, far: bool) -> ArrayMesh:
	var rng := _rng(613 + variant)
	var surface := _begin()
	var fork := Vector3(rng.randf_range(-0.02, 0.02), 0.36, 0)
	# The trunk runs up inside the crown so no sky shows between them, even without branches.
	_limb(surface, Vector3.ZERO, fork, 0.045, 0.03, 5)
	_limb(surface, fork, fork + Vector3(0, 0.2, 0), 0.03, 0.02, 5)
	if not far:
		for angle in [0.4, 2.5, 4.4]:
			_limb(surface, fork, fork + Vector3(cos(angle + variant) * 0.16, 0.2, sin(angle + variant) * 0.16), 0.026, 0.012, 4)
	var color := LEAVES[variant % LEAVES.size()]
	var span := Vector2(0.36, 1.0)
	var segments := 5 if far else 7
	var bands := 3 if far else 4
	_blob(surface, Vector3(0, 0.64, 0), Vector3(0.31, 0.26, 0.31), color, rng, segments, bands, span)
	var lobes := 4 if far else 5
	for i in lobes:
		var angle := i * TAU / lobes + variant * 0.9 + rng.randf_range(-0.3, 0.3)
		var reach := rng.randf_range(0.17, 0.23)
		var size := rng.randf_range(0.19, 0.24)
		var at := Vector3(cos(angle) * reach, rng.randf_range(0.5, 0.64), sin(angle) * reach)
		_blob(surface, at, Vector3(size, size * 0.82, size), color.lerp(LEAVES[(variant + i + 1) % LEAVES.size()], 0.5), rng, segments, bands, span)
	_blob(surface, Vector3(rng.randf_range(-0.05, 0.05), 0.83, rng.randf_range(-0.05, 0.05)), Vector3(0.2, 0.16, 0.2), color.lightened(0.04), rng, segments, bands, span)
	return surface.commit()

# Layered conifer with ragged drooping tiers; dark undersides read when seen from below.
static func _pine(variant: int, far: bool) -> ArrayMesh:
	var rng := _rng(733 + variant)
	var surface := _begin()
	_limb(surface, Vector3.ZERO, Vector3(0, 0.34, 0), 0.04, 0.026, 5)
	var tiers := 3 if far else 4 + variant % 2
	var segments := 6 if far else 8
	var color := NEEDLES[variant % NEEDLES.size()]
	for tier in tiers:
		var share := float(tier) / tiers
		var base := 0.16 + share * 0.66
		var radius := 0.27 * (1.0 - share * 0.72) * rng.randf_range(0.94, 1.06)
		var apex := Vector3(rng.randf_range(-0.01, 0.01), minf(base + 0.36 - share * 0.06, 1.0) if tier < tiers - 1 else 1.0, 0)
		var ring: Array[Vector3] = []
		for i in segments:
			var angle := (i + rng.randf_range(-0.2, 0.2)) * TAU / segments + tier * 0.4
			var droop := 0.035 if i % 2 == 0 else 0.0
			ring.append(Vector3(cos(angle), 0, sin(angle)) * radius * rng.randf_range(0.88, 1.08) + Vector3.UP * (base - droop))
		var tone := color.lerp(NEEDLES[(variant + tier) % NEEDLES.size()], 0.4).lightened(share * 0.05)
		var underside := Vector3(0, base + 0.07, 0)
		for i in segments:
			_triangle(surface, ring[i], apex, ring[(i + 1) % segments], tone, Vector2(0.1, 1.0), Vector3(0, base, 0))
			_triangle(surface, ring[i], ring[(i + 1) % segments], underside, tone, Vector2(0.1, 1.0), underside + Vector3.UP)
	return surface.commit()

static func _limb(surface: SurfaceTool, from: Vector3, to: Vector3, base: float, tip: float, sides: int) -> void:
	var up := (to - from).normalized()
	var across := up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
	var other := up.cross(across)
	for i in sides:
		var a := i * TAU / sides
		var b := (i + 1) * TAU / sides
		var da := across * cos(a) + other * sin(a)
		var db := across * cos(b) + other * sin(b)
		_triangle(surface, from + da * base, from + db * base, to + db * tip, TRUNK, Vector2(-1, 2), (from + to) / 2)
		_triangle(surface, from + da * base, to + db * tip, to + da * tip, TRUNK, Vector2(-1, 2), (from + to) / 2)

static func _blob(surface: SurfaceTool, center: Vector3, radii: Vector3, color: Color, rng: RandomNumberGenerator, segments: int, bands: int, span: Vector2) -> void:
	var rings: Array[Array] = []
	for band in range(1, bands):
		var latitude := -PI / 2 + band * PI / bands
		var row: Array[Vector3] = []
		for i in segments:
			var angle := (i + 0.5 * (band % 2)) * TAU / segments
			var wobble := rng.randf_range(0.86, 1.1)
			row.append(center + wobble * Vector3(cos(angle) * cos(latitude) * radii.x, sin(latitude) * radii.y, sin(angle) * cos(latitude) * radii.z))
		rings.append(row)
	var bottom := center - Vector3(0, radii.y * 0.8, 0)
	var top := center + Vector3(0, radii.y * rng.randf_range(0.95, 1.08), 0)
	for i in segments:
		var j := (i + 1) % segments
		_triangle(surface, bottom, rings[0][i], rings[0][j], color, span, center)
		_triangle(surface, rings[-1][i], top, rings[-1][j], color, span, center)
	# Alternate rings are offset by half a segment, so each band is a zigzag strip.
	for band in rings.size() - 1:
		var low: Array = rings[band]
		var high: Array = rings[band + 1]
		var low_offset := (band + 1) % 2 == 1
		for i in segments:
			var j := (i + 1) % segments
			if low_offset:
				_triangle(surface, high[i], low[i], high[j], color, span, center)
				_triangle(surface, low[i], low[j], high[j], color, span, center)
			else:
				_triangle(surface, low[i], high[i], low[j], color, span, center)
				_triangle(surface, high[i], high[j], low[j], color, span, center)

# Colors are baked from the scene's fixed sun, with darker undersides and lower foliage.
static func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color, span: Vector2, inside: Vector3) -> void:
	var normal := (b - a).cross(c - a)
	if normal.length_squared() < 1e-10:
		return
	normal = normal.normalized()
	if normal.dot((a + b + c) / 3.0 - inside) < 0:
		normal = -normal
	var sun := clampf(normal.dot(ManorGeometry.to_sun()) * 0.5 + 0.5, 0, 1)
	var height := clampf(inverse_lerp(span.x, span.y, (a.y + b.y + c.y) / 3.0), 0, 1)
	var tone := 0.66 + 0.30 * sun + 0.12 * height - 0.10 * maxf(-normal.y, 0)
	var shaded := Color(color.r * tone, color.g * tone, color.b * tone)
	for point in [a, b, c]:
		surface.set_color(shaded)
		surface.set_normal(normal)
		surface.add_vertex(point)

static func _begin() -> SurfaceTool:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	return surface

static func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng
