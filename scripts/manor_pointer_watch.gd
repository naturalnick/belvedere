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

func _process(delta: float) -> void:
	if manor.at_title or manor.play_gate.visible or manor.player.automated:
		locked = false
		waiting = 0.0
		return
	if captured.call():
		locked = true
		waiting = 0.0
		return
	# Escape is ignored during slides and falls as well; pause once they finish.
	if manor.sliding or manor.recovering:
		return
	waiting += delta
	if locked or waiting > LOCK_TIMEOUT:
		manor.release_pointer()
