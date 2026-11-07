class_name ManorPlayerPiano
extends Node3D

signal coin_inserted

const WALL_Z := 3.0
var manor: Manor
var art: ManorPianoArt
var token: Node3D
var busy := false
var animation: Tween
var next_replay := 0

func _ready() -> void:
	art = ManorPianoArt.new()
	add_child(art)
	var body := ManorGeometry.barrier(self, Vector3(ManorPianoArt.WIDTH, ManorPianoArt.HEIGHT, ManorPianoArt.DEPTH), Vector3(0, ManorPianoArt.HEIGHT / 2, 0))
	body.set_meta("piano", self)
	token = ManorPrizeArt.coin(self)
	token.hide()

func interact() -> bool:
	if busy or manor.controls_locked():
		return false
	if manor.coins.insert_one():
		_insert(manor.coins.inserted - 1)
		return true
	if manor.coins.inserted == 0:
		# Nothing paid for yet: the mechanism catches instead of playing.
		manor.audio.play_at("lever_blocked", global_position + Vector3.UP, -12.0)
		return true
	if manor.audio.song_playing():
		return false
	manor.audio.play_song(next_replay)
	next_replay = (next_replay + 1) % manor.coins.inserted
	return true

func _insert(song: int) -> void:
	busy = true
	token.position = ManorPianoArt.SLOT_POSITION + Vector3(0, 0, 0.40)
	token.rotation = Vector3(0, 0.3, 0)
	token.show()
	animation = create_tween()
	animation.tween_property(token, "rotation:y", PI / 2, 0.18)
	animation.tween_property(token, "position:z", ManorPianoArt.SLOT_POSITION.z - 0.03, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	animation.tween_callback(func() -> void:
		token.hide()
		coin_inserted.emit())
	animation.tween_interval(0.35)
	animation.tween_callback(func() -> void:
		busy = false
		manor.audio.play_song(song))

func _process(_delta: float) -> void:
	if art.playing != _should_play():
		art.set_playing(_should_play())
	if not busy or animation == null:
		return
	if _paused():
		animation.pause()
	elif not animation.is_running():
		animation.play()

func _should_play() -> bool:
	return manor.audio.song_playing() and not _paused()

func _paused() -> bool:
	return manor.play_gate.visible or manor.recovering or manor.in_finale or manor.at_title
