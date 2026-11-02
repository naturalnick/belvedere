class_name Manor
extends Node3D

signal slide_finished
signal puzzle_solved

var rules: ManorRules
var rooms: Dictionary[int, ManorRoom] = {}
var player: ManorPlayer
var sliding := false
var won := false
var slides := 0
var gap_floor: Node3D
var carpet: MeshInstance3D
var seed_name := "random"
var perimeter: Array[StaticBody3D] = []

func _ready() -> void:
	var demo := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			seed_name = arg.trim_prefix("--seed=")
		elif arg == "--demo":
			demo = true
	rules = ManorRules.from_seed(seed_name)
	if rules == null:
		get_tree().quit(1)
		return
	_build_world()
	for id in ManorRules.HOME:
		if id == -1:
			continue
		var room := ManorRoom.new()
		add_child(room)
		room.build(id)
		room.position = ManorGeometry.center(rules.board.find(id))
		rooms[id] = room
	gap_floor = Node3D.new()
	add_child(gap_floor)
	ManorGeometry.box(gap_floor, Vector3(6.25, 0.2, 6.25), Vector3(0, -0.1, 0), ManorGeometry.material("DCD6C8", 0.0), true)
	for d in 4:
		var edge := ManorGeometry.box(gap_floor, Vector3(5.65, 0.008, 0.04), ManorGeometry.DIRECTIONS[d] * 2.825 + Vector3.UP * 0.004, ManorGeometry.material("C6BEAD", 0.0))
		edge.rotation.y = -d * PI / 2.0
	gap_floor.position = ManorGeometry.center(rules.board.find(-1)) + Vector3.DOWN * 0.02
	player = ManorPlayer.new()
	player.manor = self
	player.automated = demo
	add_child(player)
	# The lever sits between the player and the guaranteed open gap doorway.
	var gap_direction := 0
	for d in 4:
		if rules.can_slide(d) and rules.can_walk(d):
			gap_direction = d
	player.position = ManorGeometry.center(rules.slot()) - ManorGeometry.DIRECTIONS[gap_direction] * 1.5 + Vector3.UP * 0.02
	player.aim_at(ManorGeometry.center(rules.board.find(-1)) + Vector3.UP * 1.4)
	for arg in OS.get_cmdline_user_args():
		if arg == "--invert-y":
			player.invert_y = true
	refresh_doors(true)
	var hud := CanvasLayer.new()
	add_child(hud)
	var reticle := Control.new()
	reticle.set_script(preload("res://scripts/manor_reticle.gd"))
	reticle.player = player
	reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(reticle)
	if demo:
		var driver := Node.new()
		driver.set_script(load("res://tools/demo_driver.gd"))
		add_child(driver)
		driver.call_deferred("run", self)

func _build_world() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var atmosphere := ProceduralSkyMaterial.new()
	atmosphere.sky_top_color = Color("A9C9E6")
	atmosphere.sky_horizon_color = Color("F6E2C4")
	atmosphere.ground_bottom_color = Color("8FA66A")
	atmosphere.ground_horizon_color = Color("F6E2C4")
	sky.sky_material = atmosphere
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("F3E3CF")
	environment.ambient_light_energy = 0.55
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-28, 235, 0)
	sun.light_color = Color("FFD9A8")
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 40
	add_child(sun)
	ManorGeometry.box(self, Vector3(220, 0.2, 220), Vector3(0, -0.25, 0), ManorGeometry.material("9DB86E", 0.0), true)
	carpet = ManorGeometry.box(self, Vector3(1.8, 0.025, 13), Vector3(0, 0, 15.8), ManorGeometry.material("B3363A", 0.0))
	carpet.visible = false
	# The open gap has no rail; keep the unsolved puzzle on its 3x3 footprint.
	for d in 4:
		var size := Vector3(18.75, 3, 0.1) if d % 2 == 0 else Vector3(0.1, 3, 18.75)
		perimeter.append(ManorGeometry.barrier(self, size, ManorGeometry.DIRECTIONS[d] * 9.425 + Vector3.UP * 1.5))

func refresh_doors(instant: bool = false) -> void:
	for id in rooms:
		var state := ManorRules.new(rules.board, id)
		for door in rooms[id].doors:
			var allowed := won or (not door.is_front and state.can_walk(door.direction))
			door.set_open(allowed, instant)

func update_occupant() -> void:
	if sliding:
		return
	var p := player.global_position
	var col := int(floor((p.x + ManorGeometry.PITCH * 1.5) / ManorGeometry.PITCH))
	var row := int(floor((p.z + ManorGeometry.PITCH * 1.5) / ManorGeometry.PITCH))
	if row < 0 or row > 2 or col < 0 or col > 2:
		return
	var new_slot := row * 3 + col
	if new_slot == rules.slot():
		return
	for d in 4:
		if ManorRules.neighbor(rules.slot(), d) == new_slot and rules.can_walk(d):
			rules.apply(ManorRules.WALK, d)
			return

func request_slide(direction: int) -> bool:
	if sliding:
		return false
	if won or not rules.can_slide(direction):
		if rules.player >= 0:
			rooms[rules.player].show_pull(-1, -1, false)
		return false
	sliding = true
	var room := rooms[rules.player]
	var old_slot := rules.slot()
	var destination := ManorGeometry.center(rules.board.find(-1))
	player.reparent(room, true)
	player.velocity = Vector3.ZERO
	# Static door gates close during transit; only the room and rider move.
	for id in rooms:
		for door in rooms[id].doors:
			door.set_open(false)
	var tween := create_tween()
	tween.tween_property(room, "position", destination, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void:
		rules.apply(ManorRules.SLIDE, direction)
		player.reparent(self, true)
		gap_floor.position = ManorGeometry.center(old_slot) + Vector3.DOWN * 0.02
		slides += 1
		sliding = false
		room.show_pull(-1, -1, false)
		won = rules.solved()
		refresh_doors()
		if won:
			carpet.visible = true
			for barrier in perimeter:
				barrier.collision_layer = 0
			puzzle_solved.emit()
		slide_finished.emit())
	return true
