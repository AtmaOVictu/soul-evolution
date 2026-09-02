# res_material_card.gd — RES Material Card (CL-041)
#
# After SEAL, the sealed distinctions become RES Material — usable
# meaning-material that the player can inspect, carry, and apply.
#
# Each sealed distinction yields a RES card with:
#   - The distinction's quality (CUT/BOUNDED)
#   - Its final clarity (κ at seal time)
#   - Its glyph (◉)
#   - The residual name (ℜ) attached to it
#   - A formula: "Δ + ⊘ + ⟡ + ℜ = RES"
#
# The card is a visual object the player can hover over to inspect.
# It says: "This is what you built. This is what it means."
#
# RES cards are the player's inventory of meaning.
# In future CL tasks, they can be applied to Problem Knots.

extends Node2D

signal res_card_inspected(card: Node2D, info: Dictionary)

var res_name: String = ""
var res_formula: String = ""
var res_clarity: float = 0.0
var res_quality: String = ""
var res_residual: String = ""
var _breath_time: float = 0.0
var _scale: float = 0.01
var _hover_intensity: float = 0.0
var _card_color: Color = Color(0.3, 0.4, 0.6, 0.7)

func _ready() -> void:
  scale = Vector2(_scale, _scale)
  
  var tween := create_tween()
  tween.tween_property(self, "_scale", 1.0, 0.5)
  tween.set_trans(Tween.TRANS_ELASTIC)
  tween.set_ease(Tween.EASE_OUT)

func setup(name: String, clarity: float, quality: String, residual: String) -> void:
  res_name = name
  res_clarity = clarity
  res_quality = quality
  res_residual = residual
  res_formula = "Δ + ⊘ + ⟡ + ℜ = RES"
  
  # Color based on quality
  if quality == "CUT":
    _card_color = Color(0.3, 0.5, 0.7, 0.7)
  else:
    _card_color = Color(0.4, 0.4, 0.6, 0.7)

func _process(delta: float) -> void:
  _breath_time += delta
  _hover_intensity = lerpf(_hover_intensity, 0.0, delta * 3.0)
  scale = Vector2(_scale, _scale)
  queue_redraw()

func _draw() -> void:
  var breath := sin(_breath_time * 0.3) * 0.05 + 0.95
  var hover := 1.0 + _hover_intensity * 0.1
  
  # Card background
  var card_rect := Rect2(-40, -25, 80, 50)
  var bg_color := Color(_card_color.r, _card_color.g, _card_color.b, _card_color.a * breath * hover)
  draw_rect(card_rect, bg_color, true)
  
  # Card border
  draw_rect(card_rect, Color(_card_color.r * 1.3, _card_color.g * 1.3, _card_color.b * 1.3, 0.8 * breath), false, 1.5)
  
  # ◉ glyph at top
  draw_circle(Vector2(0, -15), 4.0, Color(0.8, 0.9, 1.0, 0.9 * breath))
  draw_arc(Vector2(0, -15), 6.0, 0, TAU, 16, Color(0.8, 0.9, 1.0, 0.6), 1.0)
  
  # κ value
  draw_string(get_theme_default_font(), Vector2(-20, 0),
    "κ %.2f" % res_clarity, 0, 40, 8, Color(0.8, 0.9, 1.0, 0.7 * breath))
  
  # RES label
  draw_string(get_theme_default_font(), Vector2(-15, 12),
    "RES", 0, 30, 8, Color(0.6, 0.7, 0.9, 0.5 * breath))
  
  # Name below card
  if res_name.length() > 0:
    draw_string(get_theme_default_font(), Vector2(-30, 38),
      res_name, 0, 60, 9, Color(_card_color.r, _card_color.g, _card_color.b, 0.6 * breath))

func _input(event: InputEvent) -> void:
  if event is InputEventMouseMotion:
    var local_pos := make_input_local(event).position
    if local_pos.distance_to(Vector2.ZERO) < 50.0:
      _hover_intensity = 1.0
  elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
    var local_pos := make_input_local(event).position
    if local_pos.distance_to(Vector2.ZERO) < 50.0:
      res_card_inspected.emit(self, {
        "name": res_name,
        "clarity": res_clarity,
        "quality": res_quality,
        "residual": res_residual,
        "formula": res_formula
      })

func _set_scale(value: float) -> void:
  _scale = value
