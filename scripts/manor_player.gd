class_name ManorPlayer
extends CharacterBody3D

var camera: Camera3D
var manor: Node3D
var bot_drive := Vector3.ZERO
var automated := false
var invert_y := false
var camera_shake_enabled := false
var sensitivity := 0.0022
var held := false
var selected_direction := -1
var drag := Vector2.ZERO

func _ready() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)
	camera = Camera3D.new()
	camera.position.y = 1.65
	camera.fov = 75
	camera.near = 0.05
	add_child(camera)
	camera.make_current()
	floor_snap_length = 0.15
	Input.use_accumulated_input = false

func _unhandled_input(event: InputEvent) -> void:
	if automated or manor.sliding or manor.in_finale or manor.at_title:
		return
	if manor.play_gate != null and manor.play_gate.visible:
		return
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		manor.release_pointer()
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			begin_interact()
		else:
			release_interact()
	if event is InputEventKey and event.physical_keycode == KEY_E and not event.echo:
		if event.pressed:
			begin_interact()
		else:
			release_interact()
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if held:
			drag += event.screen_relative
			if drag.length() > 18:
				select_pull(_screen_direction(drag))
		else:
			rotation.y -= event.screen_relative.x * sensitivity
			camera.rotation.x = clampf(camera.rotation.x - event.screen_relative.y * sensitivity * (-1.0 if invert_y else 1.0), -1.35, 1.35)

func _physics_process(delta: float) -> void:
	if manor.controls_locked():
		velocity = Vector3.ZERO
		return
	var input := Vector2.ZERO
	if not automated and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		input = Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	if held:
		if input.length() > 0.1:
			select_pull(_screen_direction(input))
		velocity = Vector3.ZERO
		return
	var direction := bot_drive if automated else (global_basis * Vector3(input.x, 0, input.y)).normalized()
	velocity.x = move_toward(velocity.x, direction.x * 3.0, 30.0 * delta)
	velocity.z = move_toward(velocity.z, direction.z * 3.0, 30.0 * delta)
	velocity.y = 0.0 if is_on_floor() else velocity.y - 15.0 * delta
	move_and_slide()
	manor.update_occupant()

func aim_at(target: Vector3) -> void:
	var direction := target - camera.global_position
	rotation.y = atan2(-direction.x, -direction.z)
	camera.rotation.x = atan2(direction.y, Vector2(direction.x, direction.z).length())

func focus() -> Dictionary:
	var from := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(from, from - camera.global_basis.z * 2.2)
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query)

func begin_interact() -> bool:
	if manor.controls_locked() or held:
		return false
	var hit := focus()
	if hit.is_empty():
		return false
	var collider: Object = hit.collider
	if collider.has_meta("door"):
		var door: ManorDoor = collider.get_meta("door")
		door.rattle()
		return false
	if not collider.has_meta("lever_room") or int(collider.get_meta("lever_room")) != manor.rules.player:
		return false
	held = true
	selected_direction = -1
	drag = Vector2.ZERO
	select_pull(-1)
	return true

func select_pull(direction: int) -> void:
	if not held:
		return
	selected_direction = direction
	var valid := 0
	for d in 4:
		if manor.rules.can_slide(d):
			valid |= 1 << d
	var room: ManorRoom = manor.rooms[manor.rules.player]
	room.show_pull(direction, valid, true)

func release_interact() -> void:
	if not held:
		return
	held = false
	var room: ManorRoom = manor.rooms[manor.rules.player]
	room.show_pull(selected_direction, -1, false)
	if selected_direction >= 0:
		manor.request_slide(selected_direction)
	else:
		room.show_pull(-1, -1, false)

func cancel_pull() -> void:
	if held:
		var room: ManorRoom = manor.rooms[manor.rules.player]
		room.show_pull(-1, -1, false)
	held = false

func _screen_direction(input: Vector2) -> int:
	var world := global_basis * Vector3(input.x, 0, input.y)
	if absf(world.x) > absf(world.z):
		return ManorRules.E if world.x > 0 else ManorRules.W
	return ManorRules.S if world.z > 0 else ManorRules.N
