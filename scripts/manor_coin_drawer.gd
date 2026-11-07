class_name ManorCoinDrawer
extends Node3D

const OPEN_TIME := 0.65
const RATTLE_TIME := 0.28
# Past the end of the doors' swing sounds at docking, so the latch is heard on its own.
const UNLOCK_DELAY := 1.2
var manor: Manor
var room_id: int
var tray: Node3D
var coin: Node3D
var coin_hit: StaticBody3D
var front_hit: StaticBody3D
var travel := 0.0
var opened := false
var opening := 0.0
var rattling := 0.0
var rattles := false
var opening_sounded := false
var was_home := false
var unlock_wait := -1.0

func build(width: float, height: float, depth: float, color: String, front_color: String) -> void:
	name = "CoinDrawer"
	set_process(false)
	travel = depth * 0.76
	var wall := 0.025
	_boxes(self, [
		[Vector3(wall, height, depth), Vector3(-(width - wall) / 2, 0, 0)],
		[Vector3(wall, height, depth), Vector3((width - wall) / 2, 0, 0)],
		[Vector3(width, wall, depth), Vector3(0, (height - wall) / 2, 0)],
		[Vector3(width, wall, depth), Vector3(0, -(height - wall) / 2, 0)],
		[Vector3(width, height, wall), Vector3(0, 0, -(depth - wall) / 2)]
	], color)
	tray = Node3D.new()
	add_child(tray)
	var inner := width - 0.07
	var bottom := -height / 2 + 0.045
	# Extend the tray into the face by 1 mm so no seam shows through.
	var tray_depth := depth - 0.023
	var tray_center := 0.011
	_boxes(tray, [
		[Vector3(inner, 0.02, tray_depth), Vector3(0, bottom, tray_center)],
		[Vector3(0.02, height - 0.07, tray_depth), Vector3(-(inner - 0.02) / 2, 0, tray_center)],
		[Vector3(0.02, height - 0.07, tray_depth), Vector3((inner - 0.02) / 2, 0, tray_center)],
		[Vector3(inner, height - 0.07, 0.02), Vector3(0, 0, -depth / 2 + 0.035)],
		[Vector3(width - 0.045, height - 0.035, 0.035), Vector3(0, 0, depth / 2 + 0.016)]
	], front_color, true)
	var pull := ManorGeometry.cylinder(tray, 0.014, minf(width * 0.36, 0.22), Vector3(0, 0, depth / 2 + 0.065), ManorGeometry.material("B39459", 0.0))
	pull.rotation.z = PI / 2
	front_hit = ManorGeometry.barrier(tray, Vector3(width - 0.045, height - 0.02, 0.055), Vector3(0, 0, depth / 2 + 0.065))
	front_hit.set_meta("coin_drawer", self)
	coin = ManorPrizeArt.coin(tray)
	coin.name = "DrawerCoin"
	coin.position = Vector3(0, bottom + 0.019, depth * 0.25)
	coin.rotation.x = -PI / 2
	ManorStaticBatch.combine(coin)
	coin_hit = ManorGeometry.barrier(tray, Vector3(0.19, 0.045, 0.19), coin.position + Vector3.UP * 0.016)
	coin_hit.set_meta("drawer_coin", self)
	coin_hit.collision_layer = 0

func _boxes(parent: Node3D, parts: Array, color: String, solid: bool = false) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for part: Array in parts:
		var box := BoxMesh.new()
		box.size = part[0]
		surface.append_from(box, 0, Transform3D(Basis.IDENTITY, part[1]))
		if solid:
			ManorGeometry.barrier(parent, part[0], part[1])
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.material_override = ManorGeometry.material(color, 0.0)
	parent.add_child(mesh)

func setup(game: Manor, id: int) -> void:
	manor = game
	room_id = id
	manor.coins.changed.connect(_refresh)
	was_home = _home()
	_refresh()

func _home() -> bool:
	return manor.rules.board[room_id] == room_id

# Called with the lamps, so arriving home sounds the unlock a moment after the lamp lights.
func refresh_home() -> void:
	var home := _home()
	if home and not was_home and not opened:
		unlock_wait = UNLOCK_DELAY
		set_process(true)
	was_home = home

func _refresh() -> void:
	# A closed drawer hides its coin, which would otherwise still cost draw calls in every view.
	coin.visible = opened and not manor.coins.collected.has(room_id)
	coin_hit.collision_layer = 1 if opened and opening >= OPEN_TIME and coin.visible else 0

func interact() -> bool:
	if manor == null or manor.controls_locked() or rattles or (opened and opening < OPEN_TIME):
		return false
	if not opened and manor.rules.board[room_id] == room_id:
		opened = true
		set_process(true)
		_refresh()
		return true
	rattling = 0.0
	rattles = true
	set_process(true)
	manor.audio.play_at("lever_blocked", global_position, -12.0)
	return true

func take_coin() -> bool:
	if manor == null or manor.controls_locked() or not opened or opening < OPEN_TIME or not coin.visible:
		return false
	manor.coin_hud.begin_pickup(coin.global_position)
	if not manor.coins.collect(room_id):
		return false
	manor.player.cancel_pull()
	manor.player.velocity = Vector3.ZERO
	manor.player.bot_drive = Vector3.ZERO
	return true

func _process(delta: float) -> void:
	if manor == null or manor.at_title or manor.play_gate.visible or manor.recovering or manor.in_finale:
		return
	if unlock_wait >= 0.0:
		# A new slide restarts the wait, so the click never lands on top of another slide's sounds.
		unlock_wait = UNLOCK_DELAY if manor.sliding else unlock_wait - delta
		if unlock_wait < 0.0 and _home() and not opened:
			manor.audio.play_at("drawer_unlock", global_position, -1.0)
	if manor.sliding:
		return
	if opened and opening < OPEN_TIME:
		if not opening_sounded:
			opening_sounded = true
			manor.audio.play_at("ui_tap", global_position, -5.0)
		opening = minf(opening + delta, OPEN_TIME)
		tray.position.z = travel * smoothstep(0, OPEN_TIME, opening)
		if opening >= OPEN_TIME:
			_refresh()
	elif rattles:
		rattling = minf(rattling + delta, RATTLE_TIME)
		tray.position.z = (travel if opened else 0.0) + sin(rattling / RATTLE_TIME * TAU * 2) * 0.009 * (1.0 - rattling / RATTLE_TIME)
		if rattling >= RATTLE_TIME:
			rattles = false
	if (not opened or opening >= OPEN_TIME) and not rattles and unlock_wait < 0.0:
		set_process(false)
