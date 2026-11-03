class_name ManorPreferences
extends RefCounted

signal changed
const PATH := "user://settings.cfg"
var fov := 75.0
var sensitivity := 0.0022
var invert_y := false
var master := 1.0
var effects := 1.0
var music := 0.35
var muted := false
var storage_path := PATH

func load_file(path: String = PATH) -> void:
	storage_path = path
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return
	fov = clampf(float(config.get_value("view", "fov", fov)), 60, 100)
	sensitivity = clampf(float(config.get_value("view", "sensitivity", sensitivity)), 0.0005, 0.006)
	invert_y = bool(config.get_value("view", "invert_y", invert_y))
	master = clampf(float(config.get_value("audio", "master", master)), 0, 1)
	effects = clampf(float(config.get_value("audio", "effects", effects)), 0, 1)
	music = clampf(float(config.get_value("audio", "music", music)), 0, 1)
	muted = bool(config.get_value("audio", "muted", muted))

func save() -> void:
	var config := ConfigFile.new()
	config.load(storage_path)
	for key in ["fov", "sensitivity", "invert_y"]:
		config.set_value("view", key, get(key))
	# Older saves carry the removed camera-shake toggle.
	if config.has_section_key("view", "camera_shake"):
		config.erase_section_key("view", "camera_shake")
	for key in ["master", "effects", "music", "muted"]:
		config.set_value("audio", key, get(key))
	var error := config.save(storage_path)
	if error != OK:
		push_warning("Could not save settings: %s" % error_string(error))

func update(key: String, value: Variant) -> void:
	match key:
		"fov": fov = clampf(float(value), 60, 100)
		"sensitivity": sensitivity = clampf(float(value), 0.0005, 0.006)
		"invert_y": invert_y = bool(value)
		"master", "effects", "music": set(key, clampf(float(value), 0, 1))
		"muted": muted = bool(value)
		_: return
	changed.emit()
	save()

func apply(player: ManorPlayer) -> void:
	player.camera.fov = fov
	player.sensitivity = sensitivity
	player.invert_y = invert_y
	for bus_name in ["Effects", "Music"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, "Master")
	for bus_name in ["Master", "Effects", "Music"]:
		var index := AudioServer.get_bus_index(bus_name)
		var level := master if bus_name == "Master" else (effects if bus_name == "Effects" else music)
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(level, 0.0001)))
	AudioServer.set_bus_mute(0, muted)
