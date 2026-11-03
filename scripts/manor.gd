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
var gap_floors: Dictionary[int, Node3D] = {}
var carpet: MeshInstance3D
var seed_name := "random"
var perimeter: Array[StaticBody3D] = []
var play_gate: Control
var preferences: ManorPreferences
static var gesture_start := false
var objectives: ManorObjectives
var objective_display: ManorObjectiveDisplay
var ending: ManorEnding
var environment: Environment
var fade: ColorRect
var in_finale := false
var at_title := false

func _ready() -> void:
	var demo := false
	var classic := OS.get_cmdline_user_args().has("--classic")
	var three_gaps := OS.get_cmdline_user_args().has("--courtyard")
	if three_gaps:
		seed_name = "courtyard"
	elif not classic:
		seed_name = "A"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			seed_name = arg.trim_prefix("--seed=")
		elif arg == "--demo":
			demo = true
	if three_gaps and seed_name not in ["courtyard", "A"]:
		printerr("The three-gap prototype has one fixed start; omit --courtyard to use other seeds.")
		get_tree().quit(1)
		return
	rules = ManorRules.courtyard_start() if three_gaps else ManorRules.from_seed(seed_name)
	if rules == null:
		get_tree().quit(1)
		return
	if not classic:
		rules.courtyards = true
	_build_world()
	for id in rules.board:
		if id == -1:
			continue
		var room := ManorRoom.new()
		add_child(room)
		room.build(id)
		room.position = ManorGeometry.center(rules.board.find(id))
		rooms[id] = room
	for slot_index in 9:
		if rules.board[slot_index] != -1:
			continue
		var floor_node := Node3D.new()
		add_child(floor_node)
		ManorGeometry.build_gap_floor(floor_node)
		floor_node.position = ManorGeometry.center(slot_index) + Vector3.DOWN * 0.02
		gap_floors[slot_index] = floor_node
		if gap_floor == null:
			gap_floor = floor_node
	player = ManorPlayer.new()
	player.manor = self
	player.automated = demo
	add_child(player)
	preferences = ManorPreferences.new()
	preferences.load_file()
	preferences.changed.connect(func() -> void: preferences.apply(player))
	preferences.apply(player)
	place_player_at_spawn()
	for arg in OS.get_cmdline_user_args():
		if arg == "--invert-y":
			preferences.invert_y = true
			preferences.apply(player)
	refresh_doors(true)
	var hud := CanvasLayer.new()
	add_child(hud)
	var reticle := Control.new()
	reticle.set_script(preload("res://scripts/manor_reticle.gd"))
	reticle.player = player
	reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(reticle)
	play_gate = Control.new()
	play_gate.set_script(preload("res://scripts/play_gate.gd"))
	play_gate.manor = self
	hud.add_child(play_gate)
	play_gate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not classic and not three_gaps:
		objectives = ManorObjectives.new()
		objectives.advance(rules)
		objective_display = ManorObjectiveDisplay.new()
		add_child(objective_display)
		objective_display.setup(self)
		objective_display.refresh(objectives)
		ending = ManorEnding.new()
		ending.player = player
		add_child(ending)
	fade = ColorRect.new()
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0.06, 0.045, 0.035, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(fade)
	if (OS.has_feature("web") or OS.get_cmdline_user_args().has("--web-entry")) and not gesture_start:
		release_pointer()
	else:
		resume_play()
	gesture_start = false
	if demo:
		var driver := Node.new()
		driver.set_script(load("res://tools/demo_driver.gd"))
		add_child(driver)
		driver.call_deferred("run", self)

func place_player_at_spawn() -> void:
	# The lever sits between the player and the guaranteed open gap doorway.
	var gap_direction := 0
	for d in 4:
		if rules.can_slide(d) and rules.can_walk(d):
			gap_direction = d
	player.position = ManorGeometry.center(rules.slot()) - ManorGeometry.DIRECTIONS[gap_direction] * 1.7 + Vector3.UP * 0.02
	player.aim_at(ManorGeometry.center(rules.slot()) + ManorGeometry.DIRECTIONS[gap_direction] * ManorGeometry.PITCH + Vector3.UP * 0.1)
	player.camera.rotation.x = deg_to_rad(-16)

func resume_play() -> void:
	if in_finale or at_title:
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	play_gate.hide()

func release_pointer() -> void:
	player.cancel_pull()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	play_gate.show_mode("pause")

func controls_locked() -> bool:
	return sliding or in_finale or at_title or (play_gate != null and play_gate.visible)

func return_to_title() -> void:
	at_title = true
	if ending != null:
		ending.set_process(false)
	player.cancel_pull()
	player.velocity = Vector3.ZERO
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	fade.color.a = 0
	play_gate.show_mode("title")

func refresh_progress() -> void:
	if objectives == null:
		won = rules.solved()
	else:
		var had_main := objectives.main_won
		objectives.advance(rules)
		objective_display.refresh(objectives)
		won = objectives.bonus_won
		if objectives.main_won and not had_main:
			var warmth := create_tween()
			warmth.tween_property(environment, "ambient_light_energy", 0.60, 1.5)
			player.cancel_pull()
			player.velocity = Vector3.ZERO
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			play_gate.show_mode("victory")
	if won:
		carpet.visible = true
		for barrier in perimeter:
			barrier.collision_layer = 0
		if ending != null:
			ending.activate()
	refresh_doors()

func begin_finale() -> void:
	if in_finale or ending == null or not won:
		return
	in_finale = true
	player.cancel_pull()
	player.velocity = Vector3.ZERO
	player.bot_drive = Vector3.ZERO
	var travel := create_tween()
	travel.tween_property(player, "position", Vector3(0, -0.02, 22), 8.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	travel.tween_interval(2.0)
	travel.tween_property(fade, "color:a", 1.0, 1.4)
	travel.tween_callback(return_to_title)

func _process(delta: float) -> void:
	if in_finale and not at_title:
		var direction := Vector3(0, 1.3, 36) - player.camera.global_position
		player.rotation.y = lerp_angle(player.rotation.y, atan2(-direction.x, -direction.z), minf(delta * 2.5, 1))
		player.camera.rotation.x = lerpf(player.camera.rotation.x, atan2(direction.y, Vector2(direction.x, direction.z).length()), minf(delta * 2.5, 1))

func _build_world() -> void:
	var world := WorldEnvironment.new()
	environment = Environment.new()
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
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 0.65
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-28, 235, 0)
	sun.light_color = Color("FFD9A8")
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 40
	add_child(sun)
	# Level courtyard/lawn collision avoids an unjumpable step on the return trip.
	if rules.courtyards:
		ManorGeometry.barrier(self, Vector3(220, 0.2, 220), Vector3(0, -0.12, 0))
	var meadow := ManorMeadow.new()
	add_child(meadow)
	meadow.build(-0.04 if rules.courtyards else -0.15, not rules.courtyards)
	carpet = ManorGeometry.box(self, Vector3(1.8, 0.025, 13), Vector3(0, 0, 15.8), ManorGeometry.material("B3363A", 0.0))
	for x in [-0.84, 0.84]:
		ManorGeometry.box(carpet, Vector3(0.06, 0.006, 13), Vector3(x, 0.016, 0), ManorGeometry.material("C9A04A", 0.0))
	carpet.visible = false
	if not rules.courtyards:
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
	if won and objectives != null and rules.player == 7 and p.z > 9.45 and absf(p.x) < 0.7:
		begin_finale()
		return
	var col := int(floor((p.x + ManorGeometry.PITCH * 1.5) / ManorGeometry.PITCH))
	var row := int(floor((p.z + ManorGeometry.PITCH * 1.5) / ManorGeometry.PITCH))
	if row < 0 or row > 2 or col < 0 or col > 2:
		if rules.courtyards and rules.player == -1:
			for d in 4:
				if ManorRules.neighbor(rules.slot(), d) < 0:
					rules.apply(ManorRules.WALK, d)
					break
		return
	var new_slot := row * 3 + col
	if rules.player == ManorRules.OUTSIDE:
		rules.apply(ManorRules.ENTER_GAP, new_slot)
		return
	if new_slot == rules.slot():
		return
	for d in 4:
		if ManorRules.neighbor(rules.slot(), d) == new_slot and rules.can_walk(d):
			rules.apply(ManorRules.WALK, d)
			return
	# One physics tick can cross both grid axes at a corner of connected courtyards.
	if rules.courtyards and rules.player == -1 and rules.board[new_slot] == -1:
		for d in 4:
			var middle := ManorRules.neighbor(rules.slot(), d)
			if middle < 0 or rules.board[middle] != -1:
				continue
			for onward in 4:
				if ManorRules.neighbor(middle, onward) == new_slot:
					rules.apply(ManorRules.WALK, d)
					rules.apply(ManorRules.WALK, onward)
					return

func request_slide(direction: int) -> bool:
	if controls_locked():
		return false
	if won or not rules.can_slide(direction):
		if rules.player >= 0:
			rooms[rules.player].show_pull(-1, -1, false)
		return false
	sliding = true
	var room := rooms[rules.player]
	var old_slot := rules.slot()
	var destination_slot := ManorRules.neighbor(old_slot, direction)
	var destination := ManorGeometry.center(destination_slot)
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
		var vacated_floor: Node3D = gap_floors[destination_slot]
		gap_floors.erase(destination_slot)
		gap_floors[old_slot] = vacated_floor
		vacated_floor.position = ManorGeometry.center(old_slot) + Vector3.DOWN * 0.02
		slides += 1
		sliding = false
		room.show_pull(-1, -1, false)
		refresh_progress()
		if won:
			puzzle_solved.emit()
		slide_finished.emit())
	return true
