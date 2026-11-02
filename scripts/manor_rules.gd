class_name ManorRules
extends RefCounted
## Player is a room id, -1 for a gap (gap_slot in courtyard mode), or OUTSIDE.

const HOME := [0, 1, 2, 3, -1, 5, 6, 7, 8]
const N := 0
const E := 1
const S := 2
const W := 3
const WALK := 0
const SLIDE := 1
const ENTER_GAP := 2
const OUTSIDE := -2
const COURTYARD_START := [-1, 2, 5, 0, 1, 3, 7, -1, -1]
const WINDOW := 0
const DOOR := 1
const FRONT := 2

var board: PackedInt32Array
var player: int
var courtyards := false
var gap_slot := -1

func _init(layout: PackedInt32Array = PackedInt32Array(HOME), occupant: int = 7) -> void:
	board = layout.duplicate()
	player = occupant

static func neighbor(slot: int, direction: int) -> int:
	if slot < 0 or slot > 8 or direction < N or direction > W:
		return -1
	match direction:
		N: return slot - 3 if slot >= 3 else -1
		E: return slot + 1 if slot % 3 < 2 else -1
		S: return slot + 3 if slot < 6 else -1
		W: return slot - 1 if slot % 3 > 0 else -1
	return -1

static func opposite(direction: int) -> int:
	return (direction + 2) % 4

static func side(room: int, direction: int) -> int:
	if room == 7 and direction == S:
		return FRONT
	return DOOR if neighbor(room, direction) >= 0 else WINDOW

static func doorway(room: int, direction: int) -> bool:
	return room >= 0 and side(room, direction) == DOOR

func slot() -> int:
	if courtyards and player < 0:
		return gap_slot if player == -1 else -1
	return board.find(player)

func can_walk(direction: int) -> bool:
	if player == OUTSIDE or direction < N or direction > W:
		return false
	var q := neighbor(slot(), direction)
	if q < 0:
		return courtyards and player == -1
	var other := board[q]
	return (player == -1 or doorway(player, direction)) and (other == -1 or doorway(other, opposite(direction)))

func can_slide(direction: int) -> bool:
	var q := neighbor(slot(), direction)
	return player >= 0 and q >= 0 and board[q] == -1

func can_enter_gap(destination: int) -> bool:
	return courtyards and player == OUTSIDE and destination >= 0 and destination < 9 and board[destination] == -1 and destination != 4

func apply(kind: int, direction: int) -> bool:
	if kind == ENTER_GAP and can_enter_gap(direction):
		player = -1
		gap_slot = direction
		return true
	if kind == WALK and can_walk(direction):
		var destination := neighbor(slot(), direction)
		player = OUTSIDE if destination < 0 else board[destination]
		gap_slot = destination if player == -1 else -1
		return true
	if kind == SLIDE and can_slide(direction):
		var p := slot()
		var q := neighbor(p, direction)
		board[q] = player
		board[p] = -1
		return true
	return false

func moves() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if player == OUTSIDE:
		for destination in 9:
			if can_enter_gap(destination):
				result.append(Vector2i(ENTER_GAP, destination))
		return result
	for d in 4:
		if can_walk(d):
			result.append(Vector2i(WALK, d))
		if can_slide(d):
			result.append(Vector2i(SLIDE, d))
	return result

func solved() -> bool:
	return not courtyards and board == PackedInt32Array(HOME)

func copy() -> ManorRules:
	var result := ManorRules.new(board, player)
	result.courtyards = courtyards
	result.gap_slot = gap_slot
	return result

func valid() -> bool:
	var ordered := Array(board)
	ordered.sort()
	if courtyards:
		return ordered == [-1, -1, -1, 0, 1, 2, 3, 5, 7] and (player == OUTSIDE or (player == -1 and gap_slot >= 0 and gap_slot < 9 and board[gap_slot] == -1) or (player >= 0 and board.has(player)))
	return ordered == [-1, 0, 1, 2, 3, 5, 6, 7, 8] and board.has(player)

func key() -> int:
	var value := 0
	for i in 9:
		value |= (board[i] + 1) << (i * 4)
	if courtyards:
		# Separate open cells and the lawn must not alias one another in state keys.
		return value | ((player + 2) << 36) | ((gap_slot + 1) << 40) | (1 << 44)
	return value | ((player + 1) << 36)

static func from_key(value: int) -> ManorRules:
	var layout := PackedInt32Array()
	for i in 9:
		layout.append(((value >> (i * 4)) & 15) - 1)
	var courtyard_mode := (value & (1 << 44)) != 0
	var result := ManorRules.new(layout, ((value >> 36) & 15) - (2 if courtyard_mode else 1))
	result.courtyards = courtyard_mode
	result.gap_slot = ((value >> 40) & 15) - 1 if courtyard_mode else -1
	return result

static func courtyard_start() -> ManorRules:
	var result := ManorRules.new(PackedInt32Array(COURTYARD_START), 7)
	result.courtyards = true
	return result

static func from_seed(seed_name: String) -> ManorRules:
	match seed_name:
		"A": return ManorRules.new(PackedInt32Array([6, 2, 5, 0, 1, 3, 7, -1, 8]), 7)
		"B": return ManorRules.new(PackedInt32Array([0, 7, 1, 3, 5, 2, -1, 8, 6]), 8)
		"C": return ManorRules.new(PackedInt32Array([6, 3, 2, 0, 8, 1, -1, 7, 5]), 7)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/accepted_14_20.json"))
	var states: Array = data.states
	var index := randi_range(0, states.size() - 1)
	if seed_name != "random":
		if not seed_name.is_valid_int() or int(seed_name) < 0 or int(seed_name) >= states.size():
			push_error("Seed must be A, B, C, random, or an accepted-state index (0..%d)" % (states.size() - 1))
			return null
		index = int(seed_name)
	var entry: Dictionary = states[index]
	return ManorRules.new(PackedInt32Array(entry.board), int(entry.player))
