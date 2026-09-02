# evidence_spark.gd — The ⟡ that marks a distinction as witnessed
#
# A small animated ⟡ that appears on a DistinctionNode when the player
# witnesses it. It rotates slowly, like a star that has been named.
#
# The spark is the visual proof that the player was here — that this
# distinction was not just made, but noticed and held.

extends Node2D

var _breath_time: float = 0.0
var _rotation: float = 0.0
var _scale: float = 0.01
var _color: Color = Color(0.7, 0.8, 1.0, 0.8)

func _ready() -> void:
  scale = Vector2(_scale, _scale)
  
  # Spawn animation — grow from nothing
  var tween := create_tween()
  tween.tween_property(self, "_scale", 1.0, 0.4)
  tween.set_trans(Tween.TRANS_ELASTIC)
  tween.set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
  _breath_time += delta
  _rotation += delta * 0.3  # slow rotation
  scale = Vector2(_scale, _scale)
  rotation = _rotation
  queue_redraw()

func _draw() -> void:
  var breath := sin(_breath_time * 1.5) * 0.15 + 0.85
  
  # Draw a 4-pointed star (⟡ shape)
  var r := 6.0 * breath
  var points := PackedVector2Array([
    Vector2(0, -r * 1.5),      # top
    Vector2(r * 0.4, -r * 0.4), # upper right
    Vector2(r * 1.5, 0),        # right
    Vector2(r * 0.4, r * 0.4),  # lower right
    Vector2(0, r * 1.5),        # bottom
    Vector2(-r * 0.4, r * 0.4), # lower left
    Vector2(-r * 1.5, 0),       # left
    Vector2(-r * 0.4, -r * 0.4) # upper left
  ])
  
  draw_colored_polygon(points, _color)
  
  # Center dot
  draw_circle(Vector2.ZERO, 1.5, Color(_color.r, _color.g, _color.b, 1.0))

# Setter for tween
func _set_scale(value: float) -> void:
  _scale = value
