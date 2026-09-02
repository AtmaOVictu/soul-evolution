# ritual_audio.gd — The world has a voice
#
# CL-033: Added presence audio — a faint high tone when presence appears.
# When noticed, a brief harmonic chord plays.
#
# Each distinction emits a tone. Frequency is derived from clarity.
# Multiple distinctions create a chord. The world sings as it grows.

extends Node

const SAMPLE_RATE := 44100
const MIX_RATE := 0.3

@export var base_frequency: float = 110.0  # A2 — the void frequency
@export var max_frequency: float = 440.0   # A4 — sealed clarity
@export var volume_db: float = -12.0
@export var presence_frequency: float = 880.0  # A5 — the presence tone

var _stream: AudioStreamGenerator
var _playback: AudioStreamGeneratorPlayback
var _phase: float = 0.0
var _active_tones: Array[float] = []
var _target_volume: float = 0.0
var _current_volume: float = 0.0
var _presence_volume: float = 0.0
var _presence_target_volume: float = 0.0

func _ready() -> void:
  Events.distinction_spawned.connect(_on_distinction_spawned)
  Events.local_clarity_changed.connect(_on_clarity_changed)
  Events.presence_activated.connect(_on_presence_activated)
  Events.presence_noticed.connect(_on_presence_noticed)
  
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

# ── CL-033: Presence audio ──
func _on_presence_activated(_pos: Vector2) -> void:
  _presence_target_volume = 0.15

func _on_presence_noticed(_pos: Vector2) -> void:
  # Brief spike in presence volume — a harmonic recognition
  _presence_target_volume = 0.4
  await get_tree().create_timer(0.5).timeout
  _presence_target_volume = 0.0

func _update_tones() -> void:
  _active_tones.clear()
  var distinctions := Events.get_all_distinctions()
  for d in distinctions:
    if not is_instance_valid(d):
      continue
    var freq := lerpf(base_frequency, max_frequency, d.local_clarity)
    if d.is_sealed:
      freq *= 1.5
    _active_tones.append(freq)
  
  _target_volume = clampf(float(distinctions.size()) / 8.0, 0.0, 1.0)

func _process(delta: float) -> void:
  _current_volume = lerpf(_current_volume, _target_volume, delta * MIX_RATE)
  _presence_volume = lerpf(_presence_volume, _presence_target_volume, delta * 1.5)
  _fill_audio_buffer()

func _fill_audio_buffer() -> void:
  var frame_count := _playback.get_frames_available()
  
  for i in frame_count:
    var sample := 0.0
    
    if _active_tones.is_empty() and _presence_volume < 0.01 and _current_volume < 0.01:
      # Void drone — barely audible sub-bass
      sample = sin(_phase * base_frequency * 0.25 / SAMPLE_RATE * TAU) * 0.02
    else:
      # Presence tone — high, faint, like a distant bell
      if _presence_volume > 0.01:
        sample += sin(_phase * presence_frequency / SAMPLE_RATE * TAU) * _presence_volume * 0.2
        # Add a perfect fifth for the "noticed" chord
        if _presence_volume > 0.3:
          sample += sin(_phase * presence_frequency * 1.5 / SAMPLE_RATE * TAU) * _presence_volume * 0.15
      
      # Distinction tones
      if not _active_tones.is_empty():
        for freq in _active_tones:
          sample += sin(_phase * freq / SAMPLE_RATE * TAU) / float(_active_tones.size())
        
        if _active_tones.size() > 0:
          sample += sin(_phase * _active_tones[0] * 0.5 / SAMPLE_RATE * TAU) * 0.3
        
        sample *= _current_volume * 0.15
      
      # Void drone underneath
      sample += sin(_phase * base_frequency * 0.25 / SAMPLE_RATE * TAU) * 0.015
    
    _phase += 1.0 + sin(_phase * 0.0001) * 0.001
    sample = clampf(sample, -1.0, 1.0)
    
    _playback.push_frame(Vector2(sample, sample))
