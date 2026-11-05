class_name ManorBedSleep
extends Node

var manor: Manor
var opening_rules: ManorRules
var sleeping := false

func available() -> bool:
	return manor.slides > 0 and not manor.won and not sleeping

func interact() -> bool:
	if not available() or manor.controls_locked():
		return false
	manor.player.cancel_pull()
	manor.player.velocity = Vector3.ZERO
	manor.player.bot_drive = Vector3.ZERO
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	manor.play_gate.show_mode("sleep")
	return true

func sleep() -> void:
	if not available() or not manor.play_gate.visible or manor.play_gate.mode != "sleep":
		return
	sleeping = true
	manor.recovering = true
	# Browsers require pointer capture to begin inside the confirming click.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	manor.play_gate.hide()
	var transition := create_tween()
	transition.tween_property(manor.fade, "color:a", 1.0, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	transition.tween_interval(0.3)
	transition.tween_callback(_reset_layout)
	transition.tween_interval(0.15)
	transition.tween_property(manor.fade, "color:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	transition.tween_callback(func() -> void:
		sleeping = false
		manor.recovering = false)

func _reset_layout() -> void:
	# Keep the existing reward and inventory objects; only the room arrangement resets.
	manor.rules = opening_rules.copy()
	manor.slides = 0
	manor.won = false
	for id in manor.rooms:
		manor.rooms[id].position = ManorGeometry.center(manor.rules.board.find(id))
	var floors := manor.gap_floors.values()
	manor.gap_floors.clear()
	for slot in 9:
		if manor.rules.board[slot] == -1:
			var floor_node: Node3D = floors.pop_back()
			floor_node.position = ManorGeometry.center(slot) + Vector3.DOWN * 0.02
			manor.gap_floors[slot] = floor_node
	manor.fall_recovery._wake()
	manor.carpet.hide()
	for barrier in manor.perimeter:
		barrier.collision_layer = 1
	if manor.ending != null:
		manor.ending.reset()
	if manor.objectives != null:
		manor.objectives.bonus_won = false
		var remaining: Array[int] = []
		for room in ManorObjectives.ROOMS:
			if not manor.objectives.completed.has(room):
				remaining.append(room)
		manor.objectives.active = -1 if remaining.is_empty() else ManorObjectives.nearest_goal(manor.rules, remaining).room
		manor.objective_display.refresh(manor.objectives, manor.rules)
		if manor.wall_title != null:
			manor.wall_title.refresh(manor.objectives.active, manor.rules.board)
	if manor.foundation_hatch != null:
		manor.foundation_hatch.refresh()
	if manor.stopwatch != null:
		manor.stopwatch.refresh_count()
	manor.refresh_doors(true)
