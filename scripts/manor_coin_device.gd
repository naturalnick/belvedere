class_name ManorCoinDevice
extends Node3D

signal coin_inserted

var manor: Manor
var remaining_label: Label3D
var trophy: Node3D
var prize_tray: Node3D
var glass: MeshInstance3D
var token: Node3D
var busy := false
var releasing := false
var animation: Tween

func _ready() -> void:
	var wood := ManorGeometry.material("634632", 0.005)
	var brass := ManorGeometry.material("C9A04A", 0.003)
	var dark := ManorGeometry.material("34494C", 0.004)
	ManorGeometry.box(self, Vector3(0.86, 0.88, 0.56), Vector3(0, 0.48, 0), wood)
	ManorGeometry.box(self, Vector3(0.96, 0.10, 0.64), Vector3(0, 0.10, 0), dark)
	ManorGeometry.box(self, Vector3(0.96, 0.06, 0.64), Vector3(0, 1.02, 0), brass)
	ManorGeometry.box(self, Vector3(0.86, 0.86, 0.045), Vector3(0, 1.48, -0.26), dark)
	for x in [-0.41, 0.41]:
		for z in [-0.25, 0.25]:
			ManorGeometry.box(self, Vector3(0.045, 0.86, 0.045), Vector3(x, 1.48, z), brass)
	ManorGeometry.box(self, Vector3(0.96, 0.09, 0.64), Vector3(0, 1.92, 0), wood)
	ManorGeometry.box(self, Vector3(0.88, 0.025, 0.58), Vector3(0, 1.98, 0), brass)
	glass = ManorGeometry.box(self, Vector3(0.77, 0.77, 0.012), Vector3(0, 1.48, 0.256), ManorGeometry.glass())
	prize_tray = Node3D.new()
	add_child(prize_tray)
	prize_tray.position.y = 1.065
	ManorGeometry.box(prize_tray, Vector3(0.68, 0.03, 0.46), Vector3.ZERO, brass)
	trophy = ManorPrizeArt.trophy(prize_tray)
	trophy.position.y = 0.015
	var plate := ManorGeometry.box(self, Vector3(0.64, 0.48, 0.018), Vector3(0, 0.73, 0.29), dark)
	plate.name = "CoinSlot"
	ManorGeometry.box(self, Vector3(0.07, 0.21, 0.012), Vector3(0, 0.84, 0.305), ManorGeometry.material("6F9FC8", 0.003))
	ManorGeometry.box(self, Vector3(0.018, 0.15, 0.006), Vector3(0, 0.84, 0.314), ManorGeometry.material("211C18", 0.0))
	remaining_label = Label3D.new()
	remaining_label.font = preload("res://assets/fonts/Fondamento-Regular.ttf")
	remaining_label.font_size = 48
	remaining_label.pixel_size = 0.0021
	remaining_label.modulate = Color("F3D697")
	remaining_label.outline_size = 0
	remaining_label.no_depth_test = false
	remaining_label.position = Vector3(0, 0.61, 0.307)
	add_child(remaining_label)
	var body := ManorGeometry.barrier(self, Vector3(0.96, 1.98, 0.65), Vector3(0, 0.99, 0))
	body.set_meta("coin_device", self)
	token = ManorPrizeArt.coin(self)
	token.hide()
	manor.coins.changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	remaining_label.text = str(manor.coins.remaining())

func interact() -> bool:
	if busy or manor.controls_locked() or not manor.coins.insert_one():
		return false
	busy = true
	releasing = manor.coins.remaining() == 0
	token.position = Vector3(0, 0.84, 0.68)
	token.rotation = Vector3(0, 0.3, 0)
	token.show()
	animation = create_tween()
	animation.tween_property(token, "rotation:y", PI / 2, 0.18)
	animation.tween_property(token, "position:z", 0.26, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	animation.tween_callback(func() -> void:
		token.hide()
		coin_inserted.emit())
	animation.tween_interval(0.18)
	if releasing:
		animation.tween_property(glass, "position:y", 2.26, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		animation.parallel().tween_property(prize_tray, "position:z", 0.28, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		animation.tween_interval(0.35)
		animation.tween_callback(func() -> void:
			releasing = false
			manor.show_coin_ending())
	animation.tween_callback(func() -> void: busy = false)
	return true

func _process(_delta: float) -> void:
	if not busy or animation == null:
		return
	if manor.play_gate.visible or manor.recovering or manor.sliding or manor.in_finale or manor.at_title:
		animation.pause()
	elif not animation.is_running():
		animation.play()
