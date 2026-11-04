extends SceneTree
# Sheet coordinates from tools/gen_plan.py; the sheet shows east at the top and south to the right.
const VIEW_SIZE := 2048.0
const MARGIN := 170.0
const CELL := (VIEW_SIZE - 2.0 * MARGIN) / 3.0
const WINDOW_OFFSET := 150.0
const LIGHT := 0.90
const DARK := 0.85
var checks := 0
var failures := 0
var sheet: Image

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func run() -> void:
	var source := FileAccess.get_file_as_string("res://assets/house_plan.svg")
	check(not source.contains("<text"), "the plan carries no lettering")
	sheet = Image.new()
	check(sheet.load_svg_from_string(source) == OK, "plan sheet loads")
	for room in [0, 1, 2, 3, 5, 6, 7, 8]:
		for direction in 4:
			check_side(room, direction)
	var furniture := ManorFurnishings.new(8)
	root.add_child(furniture)
	var plan: Node3D = furniture.get_node("HousePlan")
	check(plan.position.is_equal_approx(Vector3(2.995, 1.62, 0)), "plan hangs between the Laundry's east windows, in line with its west door")
	check(plan.global_basis.z.is_equal_approx(Vector3.LEFT), "plan faces back into the room")
	check(plan.global_basis.x.is_equal_approx(Vector3.BACK), "south is on the viewer's right, as it is on the sheet")
	check(plan.find_children("*", "StaticBody3D", true, false).is_empty(), "plan never blocks the player")
	var foyer := ManorFurnishings.new(7)
	root.add_child(foyer)
	check(not foyer.has_node("HousePlan"), "only the Laundry has a plan")
	foyer.queue_free()
	print("House plan: %d checks, %d failures" % [checks, failures])
	furniture.queue_free()
	await process_frame
	quit(1 if failures else 0)

func check_side(room: int, direction: int) -> void:
	var cell := Vector2(room / 3, 2 - room % 3) * CELL + Vector2.ONE * (MARGIN + CELL / 2.0)
	# Compass directions on the sheet: north left, east up, south right, west down.
	var outward: Vector2 = [Vector2.LEFT, Vector2.UP, Vector2.RIGHT, Vector2.DOWN][direction]
	var along := Vector2(outward.y, outward.x)
	var edge := cell + outward * CELL / 2.0
	var side := ManorRules.side(room, direction)
	var label := "room %d side %d" % [room, direction]
	var mid_opening := brightness(edge + along * 60.0)
	var outer_opening := brightness(edge + along * WINDOW_OFFSET + outward * 18.0)
	if side == ManorRules.WINDOW:
		check(mid_opening < DARK, label + " has solid wall between its windows")
		check(outer_opening > LIGHT, label + " has a window")
	elif side == ManorRules.FRONT:
		check(mid_opening < 0.35, label + " is the solid front door")
	else:
		check(mid_opening > LIGHT, label + " has a door opening")
		check(outer_opening < DARK, label + " has no window")

func brightness(at: Vector2) -> float:
	var center := at * sheet.get_width() / VIEW_SIZE
	var total := 0.0
	for x in range(-3, 4):
		for y in range(-3, 4):
			total += sheet.get_pixelv(Vector2i(center) + Vector2i(x, y)).get_luminance()
	return total / 49.0
