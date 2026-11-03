class_name ManorAudio
extends Node

const DIR := "res://assets/audio/"
const STRIDE := 1.05
const DOOR_RANGE := 7.5
const TILE_ROOMS: Array[int] = [1, 3, 7, 8]
# Room-local rug rectangles (centre, size) matching the furnishing geometry.
const RUGS := {
	0: [Vector2(-1.75, -1.45), Vector2(2.0, 2.9)],
	5: [Vector2(-1.86, -1.83), Vector2(2.1, 2.1)],
}
const MUSIC_DUCK_DB := -6.0
const BIRDS_DB := -9.0

signal cued(group: String)

var manor: Manor
# Headless runs use the dummy driver, which never reclaims playbacks still active at quit and
# reports them as leaks; cues still fire so tests can check every hook.
var audible := DisplayServer.get_name() != "headless"
var streams: Dictionary[String, Array] = {}
var last_variant: Dictionary[String, int] = {}
var voices: Array[AudioStreamPlayer] = []
var music: AudioStreamPlayer
var birds: AudioStreamPlayer
var birds_on := false
var birds_fade: Tween
var music_fade: Tween
var stride := STRIDE * 0.6
var door_events: Array[Array] = []

func _ready() -> void:
	for group in ["step_wood", "step_tile", "step_grass", "step_carpet", "lever_grab", "lever_blocked", "door_rattle", "door_open", "door_close", "slide"]:
		var variants: Array = []
		while ResourceLoader.exists(DIR + "%s_%d.wav" % [group, variants.size()]):
			variants.append(load(DIR + "%s_%d.wav" % [group, variants.size()]))
		streams[group] = variants
	streams["wake"] = [load(DIR + "wake.wav")]
	for i in 6:
		var voice := AudioStreamPlayer.new()
		voice.bus = "Effects"
		add_child(voice)
		voices.append(voice)
	# The forest recording's own stereo image supplies direction, so the bed is not positional.
	birds = AudioStreamPlayer.new()
	birds.stream = load(DIR + "birds_loop.ogg")
	birds.bus = "Effects"
	add_child(birds)
	music = AudioStreamPlayer.new()
	# Looping is set in the .import so a replacement track only needs the same setting.
	music.stream = load(DIR + "manor_theme.ogg")
	music.bus = "Music"
	add_child(music)
	if audible:
		music.play()
	for id in manor.rooms:
		for door in manor.rooms[id].doors:
			door.swung.connect(func(opening: bool) -> void: door_events.append([door, opening]))
			door.rattled.connect(func() -> void: play_at("door_rattle", door.gate.global_position, -2.0))
	manor.player.lever_grabbed.connect(func() -> void: play("lever_grab", -3.0))
	manor.player.lever_returned.connect(func() -> void: play("lever_grab", -9.0, 0.88))
	manor.slide_refused.connect(func() -> void: play("lever_blocked", -1.0))
	manor.slide_started.connect(_on_slide_started)
	manor.slide_finished.connect(func() -> void: _duck_music(0.0, 1.4))
	manor.fall_recovery.woke.connect(func() -> void: play("wake", -4.0))

func play(group: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var stream := _pick(group)
	cued.emit(group)
	if stream == null or not audible:
		return
	var voice := voices[0]
	for candidate in voices:
		if not candidate.playing:
			voice = candidate
			break
	voices.erase(voice)
	voices.append(voice)
	voice.stream = stream
	voice.volume_db = volume_db + randf_range(-0.8, 0.8)
	voice.pitch_scale = pitch * randf_range(0.97, 1.03)
	voice.play()

func play_at(group: String, where: Vector3, volume_db: float = 0.0) -> void:
	var stream := _pick(group)
	cued.emit(group)
	if stream == null or not audible:
		return
	var voice := AudioStreamPlayer3D.new()
	voice.bus = "Effects"
	voice.stream = stream
	voice.unit_size = 4.0
	voice.max_distance = 30.0
	voice.volume_db = volume_db + randf_range(-0.8, 0.8)
	voice.pitch_scale = randf_range(0.97, 1.03)
	add_child(voice)
	voice.global_position = where
	voice.finished.connect(voice.queue_free)
	voice.play()

func _pick(group: String) -> AudioStream:
	var variants: Array = streams.get(group, [])
	if variants.is_empty():
		return null
	var index := randi() % variants.size()
	# Never repeat the previous variant back to back; repetition is what makes foley sound canned.
	if variants.size() > 1 and index == last_variant.get(group, -1):
		index = (index + 1 + randi() % (variants.size() - 1)) % variants.size()
	last_variant[group] = index
	return variants[index]

func _physics_process(delta: float) -> void:
	var player := manor.player
	var speed := Vector2(player.velocity.x, player.velocity.z).length()
	if manor.controls_locked() or not player.is_on_floor() or speed < 0.4:
		stride = STRIDE * 0.6
		return
	stride += speed * delta
	if stride >= STRIDE:
		stride -= STRIDE
		play(surface(), -5.0)

func surface() -> String:
	var position := manor.player.global_position
	var id := manor.rules.player
	if id >= 0 and manor.rooms.has(id):
		var local := manor.rooms[id].to_local(position)
		if RUGS.has(id):
			var rug: Array = RUGS[id]
			# Per-axis test: Vector2 comparison operators are lexicographic, not component-wise.
			var offset: Vector2 = (Vector2(local.x, local.z) - rug[0]).abs()
			var half: Vector2 = rug[1] / 2.0
			if offset.x <= half.x and offset.y <= half.y:
				return "step_carpet"
		return "step_tile" if id in TILE_ROOMS else "step_wood"
	if manor.carpet.visible and absf(position.x) < 0.9 and position.z > 9.3 and position.z < 22.3:
		return "step_carpet"
	var half := ManorGeometry.PITCH * 1.5
	if absf(position.x) < half and absf(position.z) < half:
		return "step_tile"
	return "step_grass"

func _process(_delta: float) -> void:
	_flush_doors()
	_set_birds(manor.rules.player < 0 and not manor.at_title and not manor.play_gate.visible)

func _set_birds(on: bool) -> void:
	if on == birds_on:
		return
	birds_on = on
	if birds_fade != null:
		birds_fade.kill()
	birds_fade = create_tween()
	if on:
		cued.emit("birds")
		if audible and not birds.playing:
			birds.volume_db = -40.0
			# Start anywhere in the loop so each trip outside doesn't open on the same call.
			birds.play(randf() * birds.stream.get_length())
		birds_fade.tween_property(birds, "volume_db", BIRDS_DB, 1.2)
	else:
		# Entering a room silences the birds at once; the short fade only avoids a click.
		birds_fade.tween_property(birds, "volume_db", -40.0, 0.25)
		birds_fade.tween_callback(birds.stop)

func _flush_doors() -> void:
	if door_events.is_empty():
		return
	# Every slide opens or closes several doors at once; voice only the nearest swing of each kind.
	var listener := manor.player.camera.global_position
	for opening in [true, false]:
		var nearest: ManorDoor = null
		var best := DOOR_RANGE
		for event in door_events:
			var door: ManorDoor = event[0]
			var distance := door.gate.global_position.distance_to(listener)
			if event[1] == opening and distance < best:
				nearest = door
				best = distance
		if nearest != null:
			play_at("door_open" if opening else "door_close", nearest.gate.global_position, -1.0 if opening else -3.0)
	door_events.clear()

func _on_slide_started() -> void:
	play("slide", -1.0)
	_duck_music(MUSIC_DUCK_DB, 0.3)

func _duck_music(target_db: float, seconds: float) -> void:
	if music_fade != null:
		music_fade.kill()
	music_fade = create_tween()
	music_fade.tween_property(music, "volume_db", target_db, seconds).set_trans(Tween.TRANS_SINE)
