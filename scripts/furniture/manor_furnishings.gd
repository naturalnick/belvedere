class_name ManorFurnishings
extends FurnitureKit

var room_id: int

func _init(id: int = 1) -> void:
	room_id = id
	name = "Furnishings"

func _ready() -> void:
	match room_id:
		1: bathroom()
		2: study()
		3: kitchen()
		5: living()
		6: dining()
		7: foyer()
		8: laundry()
	skirting(room_id)

func bathroom() -> void:
	var tub := group("ClawfootTub", Vector3(-1.80, 0, -2.30))
	for x in [-0.60, 0.60]:
		for z in [-0.24, 0.24]:
			rod(tub, Vector3(x, 0.05, z * 1.3), Vector3(x * 0.90, 0.23, z), 0.055, BRASS)
	basin(tub, Vector3(0, 0.15, 0), 1.95, 0.90, 0.45)
	tap(tub, Vector3(0.68, 0.47, -0.32))
	solid(tub, Vector3(1.95, 0.6, 0.90), Vector3(0, 0.30, 0))
	var sink := cabinet("Washstand", Vector3(2.56, 0, -1.80), 0.95, 0.66, 0.58, "8FC1B0", -PI / 2)
	basin(sink, Vector3(0, 0.65, 0), 0.86, 0.52, 0.20)
	tap(sink, Vector3(0, 0.82, -0.25))
	mirror(sink, Vector3(0, 1.53, -0.34), 0.75, 0.90)
	var towels := group("TowelRail", Vector3(-1.85, 0, 2.87), PI)
	for x in [-0.48, 0.48]:
		rod(towels, Vector3(x, 1.08, 0), Vector3(x, 1.08, 0.12), 0.025, BRASS)
	rod(towels, Vector3(-0.48, 1.08, 0.12), Vector3(0.48, 1.08, 0.12), 0.025, BRASS)
	box(towels, Vector3(0.52, 0.65, 0.045), Vector3(0, 0.765, 0.15), "C4D7CD")
	box(towels, Vector3(0.52, 0.04, 0.008), Vector3(0, 0.49, 0.178), "8AA89C", 0.0)
	var stool := table("BathStool", Vector3(-2.25, 0, 1.85), 0.52, 0.48, 0.42)
	box(stool, Vector3(0.40, 0.10, 0.32), Vector3(0, 0.47, 0), CREAM)
	var hamper := cabinet("LinenHamper", Vector3(2.35, 0, 2.40), 0.70, 0.70, 0.58, "A99679", PI)
	for y in [0.20, 0.32, 0.44, 0.56]:
		box(hamper, Vector3(0.58, 0.018, 0.008), Vector3(0, y, 0.325), "8C7D65", 0.0)

func study() -> void:
	var desk := table("WritingDesk", Vector3(-1.85, 0, -2.30), 1.70, 0.78, 0.75, "5A3B28")
	box(desk, Vector3(0.67, 0.19, 0.63), Vector3(0.40, 0.59, 0), "5A3B28")
	box(desk, Vector3(0.60, 0.13, 0.025), Vector3(0.40, 0.59, 0.33), "75513A")
	rod(desk, Vector3(0.28, 0.59, 0.36), Vector3(0.52, 0.59, 0.36), 0.012, BRASS)
	box(desk, Vector3(0.62, 0.012, 0.43), Vector3(0, 0.758, 0.04), "547563", 0.0)
	box(desk, Vector3(0.28, 0.018, 0.22), Vector3(0.20, 0.774, 0.03), CREAM, 0.002)
	lamp(desk, Vector3(-0.58, 0.75, -0.13), 0.45)
	chair("DeskChair", Vector3(-1.85, 0, -1.52), PI, "547563")
	var shelf := group("Bookcase", Vector3(-2.70, 0, 1.85), PI / 2)
	box(shelf, Vector3(1.68, 2.18, 0.06), Vector3(0, 1.09, -0.18), "5A3B28")
	for x in [-0.82, 0.82]:
		box(shelf, Vector3(0.08, 2.20, 0.40), Vector3(x, 1.10, 0), "5A3B28")
	for y in [0.09, 0.62, 1.15, 1.68, 2.17]:
		box(shelf, Vector3(1.60, 0.06, 0.40), Vector3(0, y, 0), "5A3B28")
	var colors := ["887356", "7A4A4A", "587366", "A69575", "63798A"]
	for level in 4:
		for book in 6:
			var height := 0.26 + (book % 3) * 0.055
			box(shelf, Vector3(0.085, height, 0.25), Vector3(-0.64 + book * 0.23, 0.12 + level * 0.53 + height / 2, 0.045), colors[(book + level) % colors.size()], 0.003)
	solid(shelf, Vector3(1.76, 2.20, 0.4), Vector3(0, 1.1, 0))
	var stand := table("GlobeStand", Vector3(2.05, 0, -2.05), 0.64, 0.64, 0.65, "5A3B28")
	cylinder(stand, 0.16, 0.05, Vector3(0, 0.68, 0), BRASS)
	rod(stand, Vector3(0, 0.7, 0), Vector3(0, 0.94, 0), 0.025, BRASS)
	globe(stand, 0.26, Vector3(0, 1.06, 0), "9AAE9B")
	var meridian := ring(stand, 0.28, 0.30, Vector3(0, 1.06, 0), BRASS)
	meridian.rotation.z = PI / 2 - 0.35
	ring(stand, 0.258, 0.267, Vector3(0, 1.06, 0), "B5B691")
	chair("ReadingChair", Vector3(2.10, 0, 1.95), -PI * 0.75, "547563", true)

func kitchen() -> void:
	var sink := cabinet("SinkCounter", Vector3(-2.55, 0, -1.80), 1.65, 0.80, 0.68, "C6AA68", PI / 2)
	basin(sink, Vector3(0, 0.78, 0), 0.78, 0.55, 0.12)
	tap(sink, Vector3(0, 0.89, -0.27))
	var range_unit := group("Range", Vector3(1.78, 0, -2.52))
	box(range_unit, Vector3(1.02, 0.84, 0.68), Vector3(0, 0.42, 0), "3E3A36")
	box(range_unit, Vector3(1.06, 0.06, 0.72), Vector3(0, 0.87, 0), "BBB5A7")
	box(range_unit, Vector3(0.82, 0.43, 0.03), Vector3(0, 0.40, 0.36), "686A64")
	box(range_unit, Vector3(0.64, 0.26, 0.012), Vector3(0, 0.40, 0.384), "303C3D", 0.0)
	rod(range_unit, Vector3(-0.34, 0.66, 0.40), Vector3(0.34, 0.66, 0.40), 0.025, BRASS)
	for x in [-0.28, 0.28]:
		for z in [-0.18, 0.18]:
			cylinder(range_unit, 0.13, 0.025, Vector3(x, 0.912, z), "3E3A36")
	for x in [-0.33, -0.11, 0.11, 0.33]:
		cylinder(range_unit, 0.035, 0.035, Vector3(x, 0.77, 0.37), "DDD3BD").rotation.x = PI / 2
	solid(range_unit, Vector3(1.06, 0.9, 0.8), Vector3(0, 0.45, 0.04))
	cabinet("RangeCounter", Vector3(2.60, 0, -2.52), 0.55, 0.90, 0.68, "C6AA68")
	var fridge := group("Refrigerator", Vector3(2.52, 0, 1.90), -PI / 2)
	box(fridge, Vector3(0.84, 1.85, 0.73), Vector3(0, 0.925, 0), CREAM)
	box(fridge, Vector3(0.78, 0.46, 0.05), Vector3(0, 1.58, 0.39), "D9DEC9")
	box(fridge, Vector3(0.78, 1.20, 0.05), Vector3(0, 0.71, 0.39), "D9DEC9")
	for y in [1.18, 1.48]:
		cylinder(fridge, 0.018, 0.20, Vector3(-0.27, y, 0.44), BRASS)
	solid(fridge, Vector3(0.84, 1.85, 0.83), Vector3(0, 0.925, 0.05))
	var prep := table("PreparationTable", Vector3(-1.95, 0, 2.28), 1.58, 0.90, 0.85)
	box(prep, Vector3(1.60, 0.05, 0.92), Vector3(0, 0.875, 0), "F2E7D0")
	box(prep, Vector3(0.55, 0.025, 0.38), Vector3(0.25, 0.913, 0), "B18B5E", 0.003)
	bowl(prep, Vector3(-0.43, 0.90, 0), 0.14, 0.12)

func living() -> void:
	box(self, Vector3(2.10, 0.006, 2.1), Vector3(-1.86, 0.004, -1.83), "D9B48A", 0.0)
	var sofa := group("Sofa", Vector3(-1.83, 0, -2.43))
	legs(sofa, 1.95, 0.76, 0.16)
	box(sofa, Vector3(1.95, 0.21, 0.76), Vector3(0, 0.265, 0), "A34E36")
	box(sofa, Vector3(1.95, 0.52, 0.15), Vector3(0, 0.60, -0.33), "A34E36")
	for x in [-0.91, 0.91]:
		box(sofa, Vector3(0.17, 0.40, 0.82), Vector3(x, 0.43, 0), "A34E36")
	for x in [-0.42, 0.42]:
		box(sofa, Vector3(0.78, 0.10, 0.61), Vector3(x, 0.42, 0.05), "B9654D")
	solid(sofa, Vector3(2.0, 0.86, 0.88), Vector3(0, 0.43, 0))
	table("CoffeeTable", Vector3(-1.85, 0, -1.45), 1.16, 0.46, 0.40)
	var fireplace := group("Fireplace", Vector3(1.85, 0, -2.64))
	box(fireplace, Vector3(1.48, 0.06, 0.62), Vector3(0, 0.03, 0), "8F8577")
	box(fireplace, Vector3(1.17, 0.91, 0.055), Vector3(0, 0.52, -0.16), "3E3A36", 0.0)
	for x in [-0.59, 0.59]:
		box(fireplace, Vector3(0.24, 1.02, 0.39), Vector3(x, 0.57, 0), "B5654A")
	box(fireplace, Vector3(1.42, 0.23, 0.39), Vector3(0, 1.045, 0), "B5654A")
	box(fireplace, Vector3(1.58, 0.07, 0.49), Vector3(0, 1.195, 0), "D3B695")
	for x in [-0.18, 0.18]:
		rod(fireplace, Vector3(x - 0.14, 0.17, -0.07), Vector3(x + 0.12, 0.17, 0.20), 0.08, "68503B")
	solid(fireplace, Vector3(1.58, 1.23, 0.62), Vector3(0, 0.615, 0))
	chair("Armchair", Vector3(-2.05, 0, 1.9), 3 * PI / 4, "A34E36", true)
	var floor_lamp := group("FloorLamp", Vector3(-2.65, 0, 2.55))
	lamp(floor_lamp, Vector3.ZERO, 1.55)
	solid(floor_lamp, Vector3(0.30, 1.55, 0.30), Vector3(0, 0.775, 0))
	var console := cabinet("LowSideboard", Vector3(2.56, 0, 1.60), 1.45, 0.90, 0.52, WOOD, -PI / 2)
	for i in 2:
		box(console, Vector3(0.38, 0.045, 0.26), Vector3(-0.34, 0.928 + i * 0.047, 0.16), "768D80" if i == 0 else "AA8865", 0.003)

func dining() -> void:
	var dining_table := table("DiningTable", Vector3(-1.55, 0, 0), 0.80, 2.30, 0.75, "6A3A2A")
	box(dining_table, Vector3(0.26, 0.006, 2.12), Vector3(0, 0.754, 0), "B79BA6", 0.0)
	for side in [-1, 1]:
		for end in [-1, 1]:
			chair("DiningChair%d_%d" % [side, end], Vector3(-1.55 + side * 0.61, 0, end * 0.62), -side * PI / 2, "7A4A6E")
		chair("DiningEndChair%d" % side, Vector3(-1.55, 0, side * 1.43), PI if side == 1 else 0.0, "7A4A6E")
	var sideboard := cabinet("Sideboard", Vector3(1.80, 0, -2.60), 1.85, 0.86, 0.60, "6A3A2A")
	for i in 3:
		cylinder(sideboard, 0.16, 0.018, Vector3(-0.54, 0.874 + i * 0.021, 0), CREAM)
	cylinder(sideboard, 0.095, 0.25, Vector3(0.54, 0.985, 0), "B6BFB0")
	var china := group("ChinaCabinet", Vector3(2.60, 0, 1.9), -PI / 2)
	box(china, Vector3(1.35, 1.95, 0.06), Vector3(0, 0.975, -0.20), "6A3A2A")
	for x in [-0.64, 0.64]:
		box(china, Vector3(0.09, 1.95, 0.48), Vector3(x, 0.975, 0), "6A3A2A")
	for y in [0.10, 0.65, 1.25, 1.92]:
		box(china, Vector3(1.20, 0.06, 0.48), Vector3(0, y, 0), "6A3A2A")
	for x in [-0.37, 0, 0.37]:
		bowl(china, Vector3(x, 1.28, 0.025), 0.125, 0.075)
	solid(china, Vector3(1.44, 1.95, 0.48), Vector3(0, 0.975, 0))
	table("ServingTable", Vector3(-1.60, 0, 2.56), 1.30, 0.48, 0.90, "6A3A2A")

func foyer() -> void:
	var bench := table("EntryBench", Vector3(1.85, 0, -2.50), 1.70, 0.65, 0.43)
	box(bench, Vector3(1.56, 0.08, 0.54), Vector3(0, 0.47, 0), "87958C")
	box(bench, Vector3(1.70, 0.33, 0.08), Vector3(0, 0.65, -0.28), WOOD)
	for x in [-0.80, 0.80]:
		box(bench, Vector3(0.07, 0.26, 0.65), Vector3(x, 0.55, 0), WOOD)
	var rack := group("CoatStand", Vector3(2.40, 0, 2.45))
	cylinder(rack, 0.045, 1.82, Vector3(0, 0.91, 0), WOOD)
	for i in 3:
		var direction := Vector3(cos(i * TAU / 3), 0, sin(i * TAU / 3))
		rod(rack, Vector3.UP * 0.25, direction * 0.36 + Vector3.UP * 0.035, 0.035, WOOD)
		rod(rack, Vector3.UP * 1.55, direction * 0.28 + Vector3.UP * 1.78, 0.025, WOOD)
		globe(rack, 0.045, direction * 0.28 + Vector3.UP * 1.78, BRASS)
	solid(rack, Vector3(0.72, 1.82, 0.72), Vector3(0, 0.91, 0))
	var entry := table("HallConsole", Vector3(-1.85, 0, 2.65), 1.42, 0.48, 0.76)
	entry.rotation.y = PI
	mirror(entry, Vector3(0, 1.60, -0.26), 0.86, 1.12)
	basin(entry, Vector3(0.44, 0.76, 0), 0.22, 0.22, 0.045)
	var umbrellas := group("UmbrellaStand", Vector3(1.55, 0, 2.45))
	basin(umbrellas, Vector3.ZERO, 0.45, 0.45, 0.52)
	for x in [-0.09, 0.10]:
		rod(umbrellas, Vector3(x, 0.12, 0), Vector3(x * 1.5, 0.95, 0.03), 0.018, WOOD)
		box(umbrellas, Vector3(0.08, 0.50, 0.09), Vector3(x, 0.40, 0), "5F7891" if x < 0 else "83927C")
		rod(umbrellas, Vector3(x * 1.5, 0.95, 0.03), Vector3(x * 1.5 + 0.08, 0.95, 0.03), 0.025, WOOD)
	solid(umbrellas, Vector3(0.48, 0.96, 0.48), Vector3(0, 0.48, 0))

func laundry() -> void:
	for i in 2:
		var machine := group("Washer" if i == 0 else "Dryer", Vector3(-2.25 + i * 0.84, 0, -2.48))
		box(machine, Vector3(0.76, 0.85, 0.72), Vector3(0, 0.425, 0), "F1EFEA")
		box(machine, Vector3(0.68, 0.12, 0.025), Vector3(0, 0.75, 0.378), "B2BBB9")
		cylinder(machine, 0.045, 0.035, Vector3(0.21, 0.75, 0.41), "5F7891").rotation.x = PI / 2
		cylinder(machine, 0.235, 0.025, Vector3(0, 0.39, 0.378), "42515B").rotation.x = PI / 2
		ring(machine, 0.22, 0.27, Vector3(0, 0.39, 0.40), "9DAAAE").rotation.x = PI / 2
		box(machine, Vector3(0.035, 0.11, 0.035), Vector3(0.20, 0.40, 0.45), CREAM, 0.002)
		solid(machine, Vector3(0.76, 0.85, 0.82), Vector3(0, 0.425, 0.05))
		if i == 1:
			for towel in 2:
				box(machine, Vector3(0.44, 0.075, 0.36), Vector3(0, 0.89 + towel * 0.077, 0), "A6B9B5" if towel == 0 else CREAM)
	var sink := table("UtilitySink", Vector3(2.48, 0, -1.85), 0.88, 0.65, 0.65)
	sink.rotation.y = -PI / 2
	basin(sink, Vector3(0, 0.64, 0), 0.89, 0.66, 0.22)
	tap(sink, Vector3(0, 0.84, -0.30))
	var boots := table("BootRack", Vector3(-2.55, 0, 1.85), 1.65, 0.58, 0.47)
	boots.rotation.y = PI / 2
	box(boots, Vector3(1.50, 0.05, 0.52), Vector3(0, 0.14, 0), WOOD)
	for x in [-0.50, -0.23, 0.23, 0.50]:
		box(boots, Vector3(0.18, 0.10, 0.35), Vector3(x, 0.215, -0.01), "645F49")
		box(boots, Vector3(0.18, 0.20, 0.16), Vector3(x, 0.29, 0.08), "645F49")
	var coats := group("CoatHooks", Vector3(-2.88, 0, 1.85), PI / 2)
	box(coats, Vector3(1.40, 0.14, 0.06), Vector3(0, 1.85, 0), WOOD)
	for i in 2:
		var x := -0.38 + i * 0.76
		rod(coats, Vector3(x, 1.84, 0.03), Vector3(x, 1.86, 0.17), 0.02, BRASS)
		var color := "A99679" if i == 0 else "7B8F83"
		box(coats, Vector3(0.32, 0.65, 0.055), Vector3(x, 1.535, 0.16), color)
		for side in [-1, 1]:
			var sleeve := box(coats, Vector3(0.10, 0.45, 0.05), Vector3(x + side * 0.20, 1.58, 0.16), color)
			sleeve.rotation.z = side * 0.25
		box(coats, Vector3(0.018, 0.57, 0.008), Vector3(x, 1.535, 0.193), "656B62", 0.0)
	var folding := table("FoldingTable", Vector3(1.95, 0, 2.55), 1.35, 0.65, 0.75)
	for towel in 3:
		box(folding, Vector3(0.52, 0.065, 0.38), Vector3(-0.25, 0.784 + towel * 0.067, 0), CREAM if towel % 2 == 0 else "A6B9B5")
