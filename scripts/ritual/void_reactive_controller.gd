# void_reactive_controller.gd — Feeds distinction positions to the void shader
#
# CL-033: Also animates presence_intensity when a presence appears.
# The void stirs when something enters it.

extends ColorRect

const MAX_DISTINCTIONS := 16

@onready var _material: ShaderMaterial = material

func _ready() -> void:
  Events.local_clarity_changed.connect(_on_clarity_changed)
  Events.distinction_spawned.connect(_on_distinction_spawned)
  Events.presence_activated.connect(_on_presence_activated)
  Events.presence_noticed.connect(_on_presence_noticed)
  
  # Initialize shader arrays
  var positions: PackedVector2Array = []
  var clarities: PackedFloat32Array = []
  for i in MAX_DISTINCTIONS:
    positions.append(Vector2(0.5, 0.5))
    clarities.append(0.0)
  _material.set_shader_parameter("distinction_positions", positions)
  _material.set_shader_parameter("distinction_clarities", clarities)
  _material.set_shader_parameter("distinction_count", 0)
  _material.set_shader_parameter("presence_intensity", 0.0)

func _process(_delta: float) -> void:
  _update_shader()

func _update_shader() -> void:
  var distinctions := Events.get_all_distinctions()
  var count := mini(distinctions.size(), MAX_DISTINCTIONS)
  
  var positions: PackedVector2Array = []
  var clarities: PackedFloat32Array = []
  
  for i in count:
    var d := distinctions[i] as Node2D
    if not is_instance_valid(d):
      positions.append(Vector2(0.5, 0.5))
      clarities.append(0.0)
      continue
    
    var screen_pos := d.global_position / get_viewport_rect().size
    positions.append(Vector2(screen_pos.x, screen_pos.y))
    clarities.append(d.local_clarity)
  
  for i in range(count, MAX_DISTINCTIONS):
    positions.append(Vector2(0.5, 0.5))
    clarities.append(0.0)
  
  _material.set_shader_parameter("distinction_positions", positions)
  _material.set_shader_parameter("distinction_clarities", clarities)
  _material.set_shader_parameter("distinction_count", count)

# ── CL-033: Presence ──
func _on_presence_activated(_pos: Vector2) -> void:
  # Animate presence_intensity from 0 to 0.5 (subtle stir)
  var tween := create_tween()
  tween.tween_method(_set_presence_intensity, 0.0, 0.5, 1.5)
  tween.set_trans(Tween.TRANS_SINE)
  tween.set_ease(Tween.EASE_IN_OUT)

func _on_presence_noticed(_pos: Vector2) -> void:
  # Presence noticed — intensity spikes briefly, then fades
  var tween := create_tween()
  tween.tween_method(_set_presence_intensity, 0.5, 1.0, 0.3)
  tween.tween_method(_set_presence_intensity, 1.0, 0.0, 2.0)
  tween.set_trans(Tween.TRANS_SINE)
  tween.set_ease(Tween.EASE_IN_OUT)

func _set_presence_intensity(value: float) -> void:
  _material.set_shader_parameter("presence_intensity", value)

func _on_clarity_changed(_node: Node, _new_value: float, _delta: float) -> void:
  _update_shader()

func _on_distinction_spawned(_node: Node2D) -> void:
  _update_shader()
