# ritual_audio.gd — The world has a voice
#
# Each distinction emits a tone. Frequency is derived from clarity.
# Multiple distinctions create a chord. The world sings as it grows.
#
# Audio is generated procedurally — no pre-recorded assets needed.
# Uses Godot AudioStreamGenerator for real-time synthesis.

extends Node

const SAMPLE_RATE := 44100
const MIX_RATE := 0.3  # how fast to crossfade tones

@export var base_frequency: float = 110.0  # A2 — the void frequency
@export var max_frequency: float = 440.0   # A4 — sealed clarity
@export var volume_db: float = -12.0

var _stream: AudioStreamGenerator
var _playback: AudioStreamGeneratorPlayback
var _phase: float = 0.0
var _active_tones: Array[float] = []  # frequencies of all distinctions
var _target_volume: float = 0.0
var _current_volume: float = 0.0

func _ready() -> void:
	Events.distinction_spawned.connect(_on_distinction_spawned)
	Events.local_clarity_changed.connect(_on_clarity_changed)
	
	# Setup audio stream
	_stream = AudioStreamGenerator.new()
	_stream.mix_rate = SAMPLE_RATE
	_stream.buffer_length = 0.1
	
	var player := AudioStreamPlayer.new()
	player.stream = _stream
	player.volume_db = volume_db
	add_child(player)
	player.play()
	_playback = player.get_stream_playback()

func _on_distinction_spawned(_node: Node2D) -> void:
	_update_tones()

func _on_clarity_changed(_node: Node, _new_value: float, _delta: float) -> void:
	_update_tones()

func _update_tones() -> void:
	_active_tones.clear()
	var distinctions := Events.get_all_distinctions()
	for d in distinctions:
		if not is_instance_valid(d):
			continue
		# Map clarity 0..1 to frequency base..max
		var freq := lerpf(base_frequency, max_frequency, d.local_clarity)
		# Sealed distinctions sustain at a perfect fifth
		if d.is_sealed:
			freq *= 1.5
		_active_tones.append(freq)
	
	# Volume scales with distinction count (but capped)
	_target_volume = clampf(float(distinctions.size()) / 8.0, 0.0, 1.0)

func _process(delta: float) -> void:
	_current_volume = lerpf(_current_volume, _target_volume, delta * MIX_RATE)
	_fill_audio_buffer()

func _fill_audio_buffer() -> void:
	var frames_available := _playback.get_frames_available()
	var frame_count := _playback.get_frames_available()
	
	for i in frame_count:
		var sample := 0.0
		
		if _active_tones.is_empty() or _current_volume < 0.01:
			# Void drone — barely audible sub-bass
			sample = sin(_phase * base_frequency * 0.25 / SAMPLE_RATE * TAU) * 0.02
		else:
			# Sum of all distinction tones (additive synthesis)
			for freq in _active_tones:
				sample += sin(_phase * freq / SAMPLE_RATE * TAU) / float(_active_tones.size())
			
			# Add a sub-harmonic for warmth
			if _active_tones.size() > 0:
				sample += sin(_phase * _active_tones[0] * 0.5 / SAMPLE_RATE * TAU) * 0.3
			
			sample *= _current_volume * 0.15
		
		# Slight detune for organic feel
		_phase += 1.0 + sin(_phase * 0.0001) * 0.001
		
		# Clamp to prevent clipping
		sample = clampf(sample, -1.0, 1.0)
		
		_playback.push_frame(Vector2(sample, sample))