## AudioManager - Centralized audio handling with pooling
## Manages SFX, music, and audio buses for the game
extends Node

# Audio bus names
const MASTER_BUS: String = "Master"
const MUSIC_BUS: String = "Music"
const SFX_BUS: String = "SFX"

# Audio pool for SFX
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_2d_pool: Array[AudioStreamPlayer2D] = []
const SFX_POOL_SIZE: int = 16
const SFX_2D_POOL_SIZE: int = 32

# Music player
var _music_player: AudioStreamPlayer

# Volume settings (in linear scale, 0.0 to 1.0)
var master_volume: float = 1.0:
	set(value):
		master_volume = clampf(value, 0.0, 1.0)
		_update_bus_volume(MASTER_BUS, master_volume)

var music_volume: float = 0.7:
	set(value):
		music_volume = clampf(value, 0.0, 1.0)
		_update_bus_volume(MUSIC_BUS, music_volume)

var sfx_volume: float = 1.0:
	set(value):
		sfx_volume = clampf(value, 0.0, 1.0)
		_update_bus_volume(SFX_BUS, sfx_volume)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_buses()
	_create_audio_pools()
	_create_music_player()


func _setup_audio_buses() -> void:
	# Create audio buses if they don't exist
	# Note: In a full project, these would be set up in the AudioBusLayout resource
	pass


func _create_audio_pools() -> void:
	# Create SFX pool (non-positional)
	for i in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = SFX_BUS if AudioServer.get_bus_index(SFX_BUS) >= 0 else MASTER_BUS
		add_child(player)
		_sfx_pool.append(player)

	# Create 2D SFX pool (positional)
	for i in range(SFX_2D_POOL_SIZE):
		var player := AudioStreamPlayer2D.new()
		player.bus = SFX_BUS if AudioServer.get_bus_index(SFX_BUS) >= 0 else MASTER_BUS
		player.max_distance = 2000.0
		add_child(player)
		_sfx_2d_pool.append(player)


func _create_music_player() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = MUSIC_BUS if AudioServer.get_bus_index(MUSIC_BUS) >= 0 else MASTER_BUS
	add_child(_music_player)


## Play a non-positional sound effect
func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if stream == null:
		return

	var player := _get_available_sfx_player()
	if player:
		player.stream = stream
		player.volume_db = volume_db
		player.pitch_scale = pitch_scale
		player.play()


## Play a positional 2D sound effect
func play_sfx_2d(stream: AudioStream, position: Vector2, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if stream == null:
		return

	var player := _get_available_sfx_2d_player()
	if player:
		player.global_position = position
		player.stream = stream
		player.volume_db = volume_db
		player.pitch_scale = pitch_scale
		player.play()


## Play a sound with random pitch variation
func play_sfx_varied(stream: AudioStream, volume_db: float = 0.0, pitch_variance: float = 0.1) -> void:
	var pitch := randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
	play_sfx(stream, volume_db, pitch)


## Play a positional sound with random pitch variation
func play_sfx_2d_varied(stream: AudioStream, position: Vector2, volume_db: float = 0.0, pitch_variance: float = 0.1) -> void:
	var pitch := randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
	play_sfx_2d(stream, position, volume_db, pitch)


## Play background music with optional crossfade
func play_music(stream: AudioStream, fade_duration: float = 1.0) -> void:
	if stream == null:
		return

	if fade_duration > 0.0 and _music_player.playing:
		# Crossfade
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -80.0, fade_duration)
		await tween.finished

	_music_player.stream = stream
	_music_player.volume_db = 0.0
	_music_player.play()


## Stop music with optional fade out
func stop_music(fade_duration: float = 1.0) -> void:
	if not _music_player.playing:
		return

	if fade_duration > 0.0:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -80.0, fade_duration)
		await tween.finished

	_music_player.stop()


func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_pool:
		if not player.playing:
			return player
	# If all are busy, return the first one (will interrupt)
	return _sfx_pool[0]


func _get_available_sfx_2d_player() -> AudioStreamPlayer2D:
	for player in _sfx_2d_pool:
		if not player.playing:
			return player
	# If all are busy, return the first one (will interrupt)
	return _sfx_2d_pool[0]


func _update_bus_volume(bus_name: String, linear_volume: float) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		# Convert linear to decibels
		var db := linear_to_db(linear_volume) if linear_volume > 0.0 else -80.0
		AudioServer.set_bus_volume_db(bus_idx, db)
