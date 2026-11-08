class_name ManorPointerWatch
extends Node

## Browsers end pointer lock themselves (Escape, tab switches, clicks outside the canvas) and keep
## that Escape from the game, which would leave play running with no mouse look and no menu.
## Lock requests also complete after the click, or are refused shortly after the user exits a lock,
## so only a lock that was granted, or one still missing after the timeout, opens the pause menu.

const LOCK_TIMEOUT := 1.0
var manor: Manor
var captured := func() -> bool: return Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
var locked := false
var waiting := 0.0
var resume_on_click := false

func _input(event: InputEvent) -> void:
	if resume_on_click and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		resume_on_click = false
		waiting = 0.0
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if manor.at_title or manor.play_gate.visible or manor.player.automated or manor.run_summary.ready_to_continue or manor.run_summary.exiting:
		resume_on_click = false
		locked = false
		waiting = 0.0
		return
	if captured.call():
		resume_on_click = false
		locked = true
		waiting = 0.0
		return
	if resume_on_click:
		return
	if locked and ((manor.binoculars != null and manor.binoculars.close()) or (manor.stopwatch != null and manor.stopwatch.close())):
		# Browser Escape releases pointer lock without forwarding the key. Lower the
		# held item now; browsers require a later click to capture the pointer again.
		locked = false
		waiting = 0.0
		resume_on_click = true
		return
	# Escape is ignored during slides and falls as well; pause once they finish.
	if manor.sliding or manor.recovering:
		return
	waiting += delta
	if locked or waiting > LOCK_TIMEOUT:
		manor.release_pointer()
