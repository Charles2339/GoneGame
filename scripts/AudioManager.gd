extends Node

class_name AudioManager

# Audio buses
var master_bus: int = -1
var sfx_bus: int = -1
var music_bus: int = -1

# Cached audio streams (we'll use a simple system without actual audio files for now)
var sound_effects: Dictionary = {}

func _ready() -> void:
	master_bus = AudioServer.get_bus_index("Master")
	sfx_bus = AudioServer.get_bus_index("SFX") if "SFX" in AudioServer.get_bus_index("SFX") else 0
	music_bus = AudioServer.get_bus_index("Music") if "Music" in AudioServer.get_bus_index("Music") else 0

func play_jump() -> void:
	_play_sound("jump", 0.3, 1.0)

func play_double_jump() -> void:
	_play_sound("double_jump", 0.25, 1.2)

func play_land_soft() -> void:
	_play_sound("land_soft", 0.2, 0.9)

func play_land_hard() -> void:
	_play_sound("land_hard", 0.3, 0.8)

func play_slide() -> void:
	_play_sound("slide", 0.25, 1.0)

func play_coin_collect() -> void:
	_play_sound("coin", 0.15, 1.0)

func play_obstacle_hit() -> void:
	_play_sound("hit", 0.4, 0.8)

func play_death() -> void:
	_play_sound("death", 0.5, 0.7)

func play_ui_click() -> void:
	_play_sound("click", 0.1, 1.1)

func play_ui_confirm() -> void:
	_play_sound("confirm", 0.2, 1.0)

# Internal sound playing (using simple beep tones as placeholder)
func _play_sound(sound_name: str, volume: float, pitch: float) -> void:
	# Create audio stream player
	var player = AudioStreamPlayer.new()
	add_child(player)
	
	# Set volume and pitch
	player.volume_db = linear2db(volume)
	player.pitch_scale = pitch
	player.bus = sfx_bus
	
	# Generate a simple tone (placeholder - in real game would load audio files)
	var frequency = _get_frequency_for_sound(sound_name)
	player.stream = _generate_beep(frequency, 0.1)
	player.play()
	
	# Clean up after playing
	await player.finished
	player.queue_free()

func _get_frequency_for_sound(sound_name: str) -> float:
	match sound_name:
		"jump": return 440.0
		"double_jump": return 550.0
		"land_soft": return 220.0
		"land_hard": return 180.0
		"slide": return 330.0
		"coin": return 880.0
		"hit": return 150.0
		"death": return 100.0
		"click": return 600.0
		"confirm": return 700.0
		_: return 440.0

func _generate_beep(frequency: float, duration: float) -> AudioStream:
	# Generate simple sine wave
	var sample_rate = 44100
	var samples = int(sample_rate * duration)
	var audio_data = PackedFloat32Array()
	
	for i in range(samples):
		var t = float(i) / sample_rate
		var sample = sin(2.0 * PI * frequency * t)
		audio_data.append(sample)
	
	var audio_stream = AudioStreamWAV.new()
	audio_stream.data = audio_data
	audio_stream.format = AudioStreamWAV.FORMAT_32
	audio_stream.mix_rate = sample_rate
	audio_stream.stereo = false
	
	return audio_stream
