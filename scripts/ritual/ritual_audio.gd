# ritual_audio.gd — The world has a voice
#
# CL-033: Presence audio
# CL-038: Problem Knot creates a dissonant drone — the world groans

extends Node

const SAMPLE_RATE := 44100
const MIX_RATE := 0.3

@export var base_frequency: float = 110.0
@export var max_frequency: float = 440.0
@export var volume_db: float = -12.0
@export var presence_frequency: float = 880.0

var _stream: AudioStreamGenerator
var _playback: AudioStreamGeneratorPlayback
var _phase: float = 0.0
var _active_tones: Array[float] = []
var _target_volume: float = 0.0
var _current_volume: float = 0.0
var _presence_volume: float = 0.0
var _presence_target_volume: float = 0.0
var _knot_volume: float = 0.0
var _knot_target_volume: float = 0.0

func _ready() -> void:
  Events.distinction_spawned.connect(_on_distinction_spawned)
  Events.local_clarity_changed.connect(_on_clarity_changed)
  Events.presence_activated.connect(_on_presence_activated)
  Events.presence_noticed.connect(_on_presence_noticed)
  Events.knot_created.connect(_on_knot_created)
  
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

func _on_presence_activated(_pos: Vector2) -> void:
  _presence_target_volume = 0.15

func _on_presence_noticed(_pos: Vector2) -> void:
  _presence_target_volume = 0.4
  await get_tree().create_timer(0.5).timeout
  _presence_target_volume = 0.0

func _on_knot_created(_knot: Node2D, _desc: String) -> void:
  _knot_target_volume = 0.3

func _update_tones() -> void:
  _active_tones.clear()
  var distinctions := Events.get_all_distinctions()
  for d in distinctions:
    if not is_instance_valid(d): continue
    var freq := lerpf(base_frequency, max_frequency, d.local_clarity)
    if d.is_sealed: freq *= 1.5
    _active_tones.append(freq)
  _target_volume = clampf(float(distinctions.size()) / 8.0, 0.0, 1.0)

func _process(delta: float) -> void:
  _current_volume = lerpf(_current_volume, _target_volume, delta * MIX_RATE)
  _presence_volume = lerpf(_presence_volume, _presence_target_volume, delta * 1.5)
  _knot_volume = lerpf(_knot_volume, _knot_target_volume, delta * 0.5)
  # Knot drone fades slowly
  if _knot_volume < 0.02:
    _knot_target_volume = 0.0
  _fill_audio_buffer()

func _fill_audio_buffer() -> void:
  var frame_count := _playback.get_frames_available()
  
  for i in frame_count:
    var sample := 0.0
    
    # Void drone
    sample += sin(_phase * base_frequency * 0.25 / SAMPLE_RATE * TAU) * 0.02
    
    # Presence tone
    if _presence_volume > 0.01:
      sample += sin(_phase * presence_frequency / SAMPLE_RATE * TAU) * _presence_volume * 0.2
      if _presence_volume > 0.3:
        sample += sin(_phase * presence_frequency * 1.5 / SAMPLE_RATE * TAU) * _presence_volume * 0.15
    
    # Distinction tones
    if not _active_tones.is_empty():
      for freq in _active_tones:
        sample += sin(_phase * freq / SAMPLE_RATE * TAU) / float(_active_tones.size())
      if _active_tones.size() > 0:
        sample += sin(_phase * _active_tones[0] * 0.5 / SAMPLE_RATE * TAU) * 0.3
      sample *= _current_volume * 0.15
    
    # CL-038: Problem Knot — dissonant drone (tritone, the devil's interval)
    if _knot_volume > 0.01:
      var knot_freq := base_frequency * 1.414  # tritone of base
      sample += sin(_phase * knot_freq / SAMPLE_RATE * TAU) * _knot_volume * 0.15
      sample += sin(_phase * knot_freq * 1.0595 / SAMPLE_RATE * TAU) * _knot_volume * 0.1  # slightly detuned
    
    _phase += 1.0 + sin(_phase * 0.0001) * 0.001
    sample = clampf(sample, -1.0, 1.0)
    _playback.push_frame(Vector2(sample, sample))
