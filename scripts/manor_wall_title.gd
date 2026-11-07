class_name ManorWallTitle
extends Node3D

const SPAWN := Vector3(-0.95, 0.02, 0)
const PLAY_CENTER := Vector3(0, 1.15, 0.03)
const INK := Color("352D28")
const TILE_COLOR := "877D6D"
var tiles: Array[MeshInstance3D] = []
var lettering: Label3D

func _ready() -> void:
	position = Vector3(-2.97, 0, 0)
	rotation.y = PI / 2
	for i in 9:
		var at := Vector3((1 - i / 3) * 0.235, 2.18 + (1 - i % 3) * 0.235, 0)
		tiles.append(ManorGeometry.box(self, Vector3(0.19, 0.19, 0.025), at, ManorGeometry.material(TILE_COLOR, 0.0)))
	lettering = Label3D.new()
	lettering.text = "Belvedere"
	lettering.font = preload("res://assets/fonts/Fondamento-Regular.ttf")
	lettering.font_size = 192
	lettering.pixel_size = 1.58 / lettering.font.get_string_size(lettering.text, HORIZONTAL_ALIGNMENT_LEFT, -1, lettering.font_size).x
	lettering.outline_size = 0
	lettering.modulate = INK
	lettering.position = Vector3(0, 1.61, 0.02)
	lettering.no_depth_test = false
	add_child(lettering)
	lettering.hide()

func frame_player(player: ManorPlayer) -> void:
	player.global_position = get_parent().to_global(SPAWN)
	player.velocity = Vector3.ZERO
	player.bot_drive = Vector3.ZERO
	player.rotation.y = PI / 2
	player.camera.rotation.x = 0
