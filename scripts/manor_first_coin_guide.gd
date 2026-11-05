class_name ManorFirstCoinGuide
extends Node

const TURN_TIME := 0.85
const WARM_TIME := 1.75
const REWARD_TIME := 2.25
const DRAWER_TURN_TIME := 0.85
const FINISH_TIME := 3.7
var manor: Manor
var active := false
var seen := false
var elapsed := 0.0
var completed := false
var start_yaw := 0.0
var start_pitch := 0.0
var target_yaw := 0.0
var target_pitch := 0.0
var drawer: ManorCoinDrawer

func begin() -> void:
	seen = true
	active = true
	drawer = manor.coin_drawers[manor.objectives.active]
	manor.player.cancel_pull()
	manor.player.velocity = Vector3.ZERO
	var direction := manor.objective_display.lamps[manor.objectives.active].globe.global_position - manor.player.camera.global_position
	start_yaw = manor.player.rotation.y
	start_pitch = manor.player.camera.rotation.x
	target_yaw = atan2(-direction.x, -direction.z)
	target_pitch = atan2(direction.y, Vector2(direction.x, direction.z).length())

func holding_reward() -> bool:
	return active

func _process(delta: float) -> void:
	if not active or manor.play_gate.visible or manor.at_title or manor.recovering or manor.sliding:
		return
	elapsed += delta
	var blend := smoothstep(0.0, TURN_TIME, elapsed)
	manor.player.rotation.y = lerp_angle(start_yaw, target_yaw, blend)
	manor.player.camera.rotation.x = lerpf(start_pitch, target_pitch, blend)
	if not completed and elapsed >= WARM_TIME:
		completed = true
		manor.refresh_progress()
	if elapsed >= REWARD_TIME:
		var direction := drawer.coin.global_position - manor.player.camera.global_position
		var drawer_yaw := atan2(-direction.x, -direction.z)
		var drawer_pitch := atan2(direction.y, Vector2(direction.x, direction.z).length())
		var pan := smoothstep(REWARD_TIME, REWARD_TIME + DRAWER_TURN_TIME, elapsed)
		manor.player.rotation.y = lerp_angle(target_yaw, drawer_yaw, pan)
		manor.player.camera.rotation.x = lerpf(target_pitch, drawer_pitch, pan)
	if elapsed >= FINISH_TIME:
		active = false
