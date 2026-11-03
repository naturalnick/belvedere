class_name ManorFallRecovery
extends Node

const FALL_SECONDS := 5.0
const FADE_OUT := 0.55
const FADE_IN := 1.0
const BEDSIDE := Vector3(-0.70, 0.02, -1.0)
var manor: Manor
var elapsed := 0.0

func _physics_process(delta: float) -> void:
	if manor.controls_locked():
		return
	if manor.player.global_position.y >= -0.25 or manor.player.is_on_floor():
		elapsed = 0.0
		return
	elapsed += delta
	if elapsed >= FALL_SECONDS:
		_recover()

func _recover() -> void:
	manor.recovering = true
	manor.player.cancel_pull()
	var transition := create_tween()
	transition.tween_property(manor.fade, "color:a", 1.0, FADE_OUT)
	transition.tween_callback(_wake)
	transition.tween_interval(0.15)
	transition.tween_property(manor.fade, "color:a", 0.0, FADE_IN).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	transition.tween_callback(func() -> void:
		elapsed = 0.0
		manor.recovering = false)

func _wake() -> void:
	var bedroom: ManorRoom = manor.rooms[0]
	manor.player.global_position = bedroom.to_global(BEDSIDE)
	manor.player.velocity = Vector3.ZERO
	manor.player.bot_drive = Vector3.ZERO
	manor.player.aim_at(bedroom.to_global(Vector3(-2.02, 0.7, -1.9)))
	manor.rules.player = 0
	manor.rules.gap_slot = -1
