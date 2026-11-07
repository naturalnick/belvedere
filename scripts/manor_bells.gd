class_name ManorBells
extends RefCounted

signal completed

const WORD := "BELVEDERE"
const LETTERS: Dictionary[int, String] = {0: "B", 6: "E", 2: "L", 3: "V", 5: "D", 7: "R"}
# On the inside of each room's accent wall, whose outside face carries the painted letter.
# Position is on the wall surface; yaw turns the mount's +Z into the room.
const MOUNTS: Dictionary[int, Array] = {
	0: [Vector3(1.55, 1.75, 3.0), PI],
	6: [Vector3(-1.80, 1.75, -3.0), 0.0],
	2: [Vector3(-1.60, 1.75, 3.0), PI],
	3: [Vector3(3.0, 1.75, -1.40), -PI / 2],
	5: [Vector3(-3.0, 1.75, 1.05), PI / 2],
	7: [Vector3(1.85, 1.75, -3.0), 0.0],
}
var progress := 0
var complete := false

# Returns whether the ring counted, which is what the bell's tone reports.
func ring(room: int) -> bool:
	if complete:
		return true
	var letter := LETTERS[room]
	if letter == WORD[progress]:
		progress += 1
		complete = progress == WORD.length()
		if complete:
			completed.emit()
		return true
	# B always starts the word, so a mistaken B doubles as a fresh start.
	progress = 1 if letter == WORD[0] else 0
	return progress == 1
