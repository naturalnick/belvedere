class_name ManorAudio
extends Node

const DIR := "res://assets/audio/"
const STRIDE := 1.05
const DOOR_RANGE := 7.5
const MUSIC_DUCK_DB := -6.0
const BIRDS_DB := -33.0
const MUSIC_DELAY := 3.0
# Silence between plays of the theme, so it doesn't run back to back.
const MUSIC_REST := 30.0
# Menu press sound: "ui_click" (brass latch) or "ui_tap" (muted wooden tap).
const MENU_CLICK := "ui_click"
const MENU_CLICK_DB := -4.0
const BELL_DB := -6.0
const PEAL_DB := -3.0
# Wider than an ordinary ring, so the far rooms of the house still carry.
const PEAL_UNIT_SIZE := 9.0
const SONG_FADE_DB := -60.0

signal cued(group: String)
signal song_ended

var manor: Manor
# Headless runs use the dummy driver, which never reclaims playbacks still active at quit and
# reports them as leaks; cues still fire so tests can check every hook.
var audible := DisplayServer.get_name() != "headless"
# Static so the scene reload behind Play keeps the streams and their decoded web samples.
static var streams: Dictionary[String, Array] = {}
var last_variant: Dictionary[String, int] = {}
var voices: Array[AudioStreamPlayer] = []
var music: AudioStreamPlayer
var birds: AudioStreamPlayer
var birds_on := false
var birds_fade: Tween
var music_fade: Tween
var music_rest: Tween
var music_duck_db := 0.0
var song_duck_db := 0.0
var song_fade: Tween
var song_voice: AudioStreamPlayer3D
var song_active := false
var stride := STRIDE * 0.6
var door_events: Array[Array] = []

func _ready() -> void:
	if streams.is_empty():
		_load_streams()
	add_to_group("menu_audio")
	for i in 6:
		var voice := AudioStreamPlayer.new()
		voice.bus = "Effects"
		add_child(voice)
		voices.append(voice)
	# The forest recording's own stereo image supplies direction, so the bed is not positional.
	birds = AudioStreamPlayer.new()
	birds.stream = streams["birds"][0]
	birds.bus = "Effects"
	add_child(birds)
	music = AudioStreamPlayer.new()
	# Looping is off in the .import; the theme plays through, then rests before the next play.
	music.stream = streams["theme"][0]
	music.bus = "Music"
	add_child(music)
	music.finished.connect(func() -> void:
		music_rest = create_tween()
		music_rest.tween_interval(MUSIC_REST)
		music_rest.tween_callback(_play_theme))
	var intro := create_tween()
	intro.tween_interval(MUSIC_DELAY)
	intro.tween_callback(_play_theme)
	if manor.coins != null:
		manor.coins.received.connect(func() -> void: play("coin_acquired", -4.0))
	for id in manor.rooms:
		for door in manor.rooms[id].doors:
			door.swung.connect(func(opening: bool) -> void: door_events.append([door, opening]))
			door.rattled.connect(func() -> void: play_at("door_rattle", door.gate.global_position, -2.0))
	var piano := manor.player_piano
	piano.coin_inserted.connect(func() -> void: play_at("coin_insert", piano.global_position + Vector3.UP, -3.0))
	# Parented to the piano, so a song in progress rides along when the Living room shifts.
	song_voice = AudioStreamPlayer3D.new()
	song_voice.bus = "Music"
	song_voice.unit_size = 5.0
	song_voice.max_distance = 40.0
	song_voice.position.y = 1.0
	piano.add_child(song_voice)
	song_voice.finished.connect(end_song)
	for bell: ManorBell in manor.bell_mounts.values():
		# No random pitch here: the only clue a ring gives is its tone.
		bell.rung.connect(func(counted: bool) -> void: play_at("bell_clear" if counted else "bell_off", bell.global_position, BELL_DB, false))
		bell.pealed.connect(func() -> void:
			var voice := play_at("bell_clear", bell.global_position, PEAL_DB, false)
			if voice != null:
				voice.unit_size = PEAL_UNIT_SIZE
				voice.max_distance = 50.0)
	if manor.study_safe != null:
		manor.study_safe.button_pressed.connect(func() -> void: play_at("lever_grab", manor.study_safe.global_position, -12.0))
		manor.study_safe.handle_tried.connect(func(success: bool) -> void: play_at("door_open" if success else "door_rattle", manor.study_safe.global_position, -8.0))
	manor.player.lever_grabbed.connect(func() -> void: play("lever_grab", -3.0))
	manor.player.lever_returned.connect(func() -> void: play("lever_grab", -9.0, 0.88))
	manor.slide_refused.connect(func() -> void: play("lever_blocked", -1.0))
	manor.slide_started.connect(_on_slide_started)
	manor.slide_finished.connect(func() -> void: _duck_music(0.0, 1.4))
	manor.fall_recovery.woke.connect(func() -> void: play("wake", -4.0))

func _load_streams() -> void:
	for group in ["step_tile", "step_grass", "lever_grab", "lever_blocked", "door_rattle", "door_open", "door_close", "slide", "gap_retract", "conservatory_rise", "coin_insert", "coin_acquired", "drawer_unlock", "ui_click", "ui_tap"]:
		var variants: Array = []
		while ResourceLoader.exists(DIR + "%s_%d.wav" % [group, variants.size()]):
			variants.append(load(DIR + "%s_%d.wav" % [group, variants.size()]))
		streams[group] = variants
	var songs: Array = []
	while ResourceLoader.exists(DIR + "piano_song_%d.ogg" % songs.size()):
		songs.append(load(DIR + "piano_song_%d.ogg" % songs.size()))
	streams["piano_song"] = songs
	for bell_sound in ["bell_clear", "bell_off"]:
		streams[bell_sound] = [load(DIR + bell_sound + ".ogg")]
	streams["wake"] = [load(DIR + "wake.wav")]
	streams["birds"] = [load(DIR + "birds_loop.ogg")]
	streams["theme"] = [load(DIR + "main_theme.ogg")]
	if OS.has_feature("web"):
		# Web playback uses decoded samples, and a stream's first play() would decode all of it
		# on the only thread. A 96 s theme alone took over 100 ms, so pay for it during load.
		# Piano songs are left to decode on their first play: about 17 MB each once decoded, and
		# most players unlock only a few, so paying for all seven up front would waste memory.
		for group in streams:
			if group == "piano_song":
				continue
			for stream: AudioStream in streams[group]:
				AudioServer.register_stream_as_sample(stream)

# Called deferred through the "menu_audio" group, so a Sound: On press is heard after unmuting.
func menu_click() -> void:
	play(MENU_CLICK, MENU_CLICK_DB)

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

func play_at(group: String, where: Vector3, volume_db: float = 0.0, vary_pitch: bool = true) -> AudioStreamPlayer3D:
	var stream := _pick(group)
	cued.emit(group)
	if stream == null or not audible:
		return null
	var voice := AudioStreamPlayer3D.new()
	voice.bus = "Effects"
	voice.stream = stream
	voice.unit_size = 4.0
	voice.max_distance = 30.0
	voice.volume_db = volume_db + randf_range(-0.8, 0.8)
	voice.pitch_scale = randf_range(0.97, 1.03) if vary_pitch else 1.0
	add_child(voice)
	voice.global_position = where
	voice.finished.connect(voice.queue_free)
	voice.play()
	return voice

# Songs beyond the supplied recordings repeat them, so all seven coins always play something.
func play_song(index: int) -> void:
	var songs: Array = streams["piano_song"]
	song_active = true
	cued.emit("piano_song")
	_fade_theme(SONG_FADE_DB, 2.0)
	if audible:
		song_voice.stream = songs[index % songs.size()]
		song_voice.play()

func song_playing() -> bool:
	return song_active

func end_song() -> void:
	if not song_active:
		return
	song_active = false
	song_voice.stop()
	_fade_theme(0.0, 3.0)
	song_ended.emit()

# The theme swells in on its own, so it needs no fade-in; on the web it also stays at its start
# while the browser holds audio until the first click.
func _play_theme() -> void:
	# A theme due during a piano song would start buried under it, so it waits for the song to end.
	if song_active:
		if not song_ended.is_connected(_play_theme):
			song_ended.connect(_play_theme, CONNECT_ONE_SHOT)
		return
	cued.emit("theme")
	if audible:
		music.play()

func _fade_theme(target_db: float, seconds: float) -> void:
	if song_fade != null:
		song_fade.kill()
	song_fade = create_tween()
	song_fade.tween_property(self, "song_duck_db", target_db, seconds).set_trans(Tween.TRANS_SINE)

# Godot's web samples restart from the beginning on every unpause, even an unpause of a playing
# sound, so a pause state assigned each frame turns the sound into noise. Only send changes.
static func hold(player: Node, paused: bool) -> void:
	if player.stream_paused != paused:
		player.stream_paused = paused

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
		return "step_tile"
	# The exit carpet uses the same indoor step instead of the surrounding grass sound.
	if manor.carpet.visible and absf(position.x) < 0.9 and position.z > 9.3 and position.z < 22.3:
		return "step_tile"
	var half := ManorGeometry.PITCH * 1.5
	if absf(position.x) < half and absf(position.z) < half:
		return "step_tile"
	return "step_grass"

func _process(delta: float) -> void:
	music.volume_db = music_duck_db + song_duck_db
	var paused := manor.play_gate.visible or manor.at_title
	if song_active:
		hold(song_voice, paused)
	_flush_doors()
	var in_conservatory := manor.conservatory != null and manor.conservatory.accessible() and manor.rules.slot() == 4
	_set_birds(manor.rules.player < 0 and not in_conservatory and not manor.at_title and not manor.play_gate.visible)

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
			birds.volume_db = -60.0
			# Start anywhere in the loop so each trip outside doesn't open on the same call.
			birds.play(randf() * birds.stream.get_length())
		birds_fade.tween_property(birds, "volume_db", BIRDS_DB, 1.2)
	else:
		# Entering a room silences the birds at once; the short fade only avoids a click.
		birds_fade.tween_property(birds, "volume_db", -60.0, 0.25)
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
	music_fade.tween_property(self, "music_duck_db", target_db, seconds).set_trans(Tween.TRANS_SINE)
