extends Node

const MUSIC_PATH := "res://music/FesliyanStudios.com.mp3"
const FADE_TIME := 1.0

var _player: AudioStreamPlayer

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = &"Master"
	add_child(_player)
	_player.stream = load(MUSIC_PATH)
	_player.volume_db = 0.0
	_player.finished.connect(_on_music_finished)
	play()

func _on_music_finished() -> void:
	play()

func play() -> void:
	if _player and not _player.playing:
		_player.play()

func stop() -> void:
	if _player and _player.playing:
		_player.stop()

func fade_out() -> Tween:
	if not _player or not _player.playing:
		return create_tween()
	var tween := create_tween()
	tween.tween_property(_player, "volume_db", -80.0, FADE_TIME)
	tween.tween_callback(stop)
	return tween

func reset() -> void:
	if _player:
		_player.stop()
		_player.volume_db = 0.0
	play()
