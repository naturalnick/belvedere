class_name ManorCoins
extends RefCounted

signal changed
signal received

const REQUIRED := 7
var awarded: Array[int] = []
var pending: Array[int] = []
var available := 0
var inserted := 0

func award(rooms: Array[int]) -> void:
	for room in rooms:
		if room in ManorObjectives.ROOMS and not awarded.has(room):
			awarded.append(room)
			pending.append(room)
	changed.emit()

func receive_next() -> void:
	if pending.is_empty():
		return
	pending.pop_front()
	available += 1
	changed.emit()
	received.emit()

func insert_one() -> bool:
	if available == 0 or inserted == REQUIRED:
		return false
	available -= 1
	inserted += 1
	changed.emit()
	return true

func remaining() -> int:
	return REQUIRED - inserted
