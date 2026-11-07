class_name ManorCoins
extends RefCounted

signal changed
signal received

# The Foyer alone has no coin drawer.
const ROOMS: Array[int] = [0, 1, 2, 3, 5, 6, 8]
var collected: Array[int] = []
var pending: Array[int] = []
var available := 0
var inserted := 0

func collect(room: int) -> bool:
	if not room in ROOMS or collected.has(room):
		return false
	collected.append(room)
	pending.append(room)
	changed.emit()
	return true

func receive_next() -> void:
	if pending.is_empty():
		return
	pending.pop_front()
	available += 1
	changed.emit()
	received.emit()

func insert_one() -> bool:
	if available == 0:
		return false
	available -= 1
	inserted += 1
	changed.emit()
	return true
