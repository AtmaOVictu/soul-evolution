# residual_seed.gd — The ℜ (residual) that remains after an answer
#
# CL-037: When the player names what remains unresolved, a ResidualSeed
# appears. It is NOT a failure. It is a continuation — a thread that
# leads to the next question.
#
# Visual: a small amber/orange node that pulses slowly. It has the
# player's name written on it. It does not flicker — it holds, because
# it was named honestly.
#
# "Not every good answer is sealable. Some answers are valuable
#  because they name what remains."

extends Node2D

var residual_name: String = ""
var local_clarity: float = 0.0
var _breath_time: float = 0.0
var _scale: float = 0.01
var _color: Color = Color(0.8, 0.6, 0.2, 0.7)

func _ready() -> void:
  scale = Vector2(_scale, _scale)
  
  # Spawn animation
  var tween := create_tween()
  tween.tween_property(self, "_scale", 1.0, 0.5)
  tween.set_trans(Tween.TRANS_ELASTIC)
  tween.set_ease(Tween.EASE_OUT)

func setup(name: String) -> void:
  residual_name = name
  local_clarity = 0.0

func _process(delta: float) -> void:
  _breath_time += delta
  scale = Vector2(_scale, _scale)
  queue_redraw()

func _draw() -> void:
  var breath := sin(_breath_time * 0.5) * 0.15 + 0.85
  
  # Outer halo
  var halo_r := 15.0 * breath
  draw_circle(Vector2.ZERO, halo_r, Color(_color.r, _color.g, _color.b, 0.1))
  
  # Inner glow
  draw_circle(Vector2.ZERO, 8.0 * breath, Color(_color.r, _color.g, _color.b, 0.3))
  
  # Core — ℜ symbol (draw as a small spiral approximation)
  draw_circle(Vector2.ZERO, 4.0, Color(_color.r, _color.g, _color.b, 0.8))
  
  # Name label below
  if residual_name.length() > 0:
    var font := get_theme_default_font()
    var text := "ℜ: " + residual_name
    draw_string(font, Vector2(-50, 22), text, 0, 100, 12,
      Color(_color.r, _color.g, _color.b, 0.7))

func _set_scale(value: float) -> void:
  _scale = value
