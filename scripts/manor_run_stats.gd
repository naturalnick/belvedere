class_name ManorRunStats
extends Node

var manor: Manor
var shifts := 0
var sleeps := 0
var falls := 0
var elapsed_seconds := 0.0
var started := false
var finished := false

func _process(delta: float) -> void:
	if started and not finished and not manor.at_title and not manor.play_gate.visible:
		elapsed_seconds += delta

func record_shift() -> void:
	if started and not finished:
		shifts += 1

func record_sleep(from_fall := false) -> void:
	if started and not finished:
		sleeps += 1
		if from_fall:
			falls += 1

func sleep_count() -> String:
	return "%d%s" % [sleeps, "*" if falls > 0 else ""]

func time_text() -> String:
	var seconds := int(elapsed_seconds)
	if seconds >= 3600:
		return "%d:%02d:%02d" % [seconds / 3600, (seconds / 60) % 60, seconds % 60]
	return "%d:%02d" % [seconds / 60, seconds % 60]
