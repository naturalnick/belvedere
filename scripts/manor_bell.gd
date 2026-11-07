class_name ManorBell
extends Node3D

signal rung(counted: bool)
signal pealed

var manor: Manor
var room_id: int
var art: ManorBellArt

func _ready() -> void:
	art = ManorBellArt.new()
	add_child(art)
	var hit := ManorGeometry.barrier(self, ManorBellArt.HIT_SIZE, ManorBellArt.HIT_CENTER)
	hit.set_meta("bell", self)

func interact() -> bool:
	if manor.controls_locked():
		return false
	var counted := manor.bells.ring(room_id)
	art.swing()
	rung.emit(counted)
	return true

# The bells replaying the word on their own once it is complete.
func peal() -> void:
	art.swing()
	pealed.emit()
