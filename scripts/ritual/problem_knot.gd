# problem_knot.gd — A Problem Knot from unresolved answer (CL-038)
#
# When SEAL is blocked and the player cannot (or does not) name what
# remains, a Problem Knot forms. It is a MATERIAL object — not a
# game-over screen, not a fail popup. It persists in the world.
#
# The knot spirals slowly. It is dark, tangled, but not hostile.
# It says: "This answer lacked [X]." The player can examine it.
#
# Visual: a cluster of tangled lines that rotate slowly, like
# thread that got knotted. Dark amber/brown color. It breathes
# but does not grow. It does not flicker — it is too dense for that.
# It just... sits. Waiting to be addressed.
#
# Ontological grounding:
#   ⊗∫ — voice that got tangled
#   ∞↧ — eternal falling made visible
#   Failure becomes a world object, not a game state.

extends Node2D

signal knot_examined(knot: Node2D, description: String)

var knot_description: String = ""
var knot_id: int = -1
var missing_context: bool = false
var missing_evidence: bool = false
var missing_residual: bool = false

var _breath_time: float = 0.0
var _rotation: float = 0.0
var _scale: float = 0.01
var _tangle_points: PackedVector2Array = []
var _color: Color = Color(0.5, 0.35, 0.15, 0.8)

static var _next_id: int = 0

func _init() -> void:
  knot_id = _next_id
  _next_id += 1

func _ready() -> void:
  scale = Vector2(_scale, _scale)
  _generate_tangle()
  
  # Spawn animation — grow with a slight overshoot
  var tween := create_tween()
  tween.tween_property(self, "_scale", 1.0, 0.6)
  tween.set_trans(Tween.TRANS_BACK)
  tween.set_ease(Tween.EASE_OUT)

func setup(description: String, ctx: bool, ev: bool, res: bool) -> void:
  knot_description = description
  missing_context = ctx
  missing_evidence = ev
  missing_residual = res
  
  # Color shifts based on what's missing
  if missing_residual:
    _color = Color(0.6, 0.4, 0.1, 0.8)  # amber — residual missing
  elif missing_evidence:
    _color = Color(0.5, 0.3, 0.1, 0.8)  # darker — evidence missing
  elif missing_context:
    _color = Color(0.4, 0.25, 0.1, 0.8)  # darkest — context missing

func _generate_tangle() -> void:
  # Generate a set of points that form a tangled knot shape
  _tangle_points.clear()
  var rng := RandomNumberGenerator.new()
  rng.seed = knot_id * 42 + 7
  
  var num_loops := 5
  for i in num_loops:
    var cx := rng.randf_range(-12, 12)
    var cy := rng.randf_range(-12, 12)
    var r := rng.randf_range(8, 16)
    var start_angle := rng.randf_range(0, TAU)
    var arc_len := rng.randf_range(PI * 0.7, PI * 1.5)
    
    var steps := 12
    for j in steps:
      var t := float(j) / steps
      var angle := start_angle + arc_len * t
      var wobble := sin(t * PI * 3) * 2.0
      _tangle_points.append(Vector2(
        cx + cos(angle) * (r + wobble),
        cy + sin(angle) * (r + wobble)
      ))

func _process(delta: float) -> void:
  _breath_time += delta
  _rotation += delta * 0.15  # very slow rotation
  scale = Vector2(_scale, _scale)
  rotation = _rotation
  queue_redraw()

func _draw() -> void:
  var breath := sin(_breath_time * 0.3) * 0.1 + 0.9
  
  # Draw the tangle — connected line segments
  if _tangle_points.size() > 1:
    var line_color := Color(_color.r, _color.g, _color.b, _color.a * breath)
    for i in range(0, _tangle_points.size() - 1):
      draw_line(_tangle_points[i], _tangle_points[i + 1], line_color, 2.0)
  
  # Central dense point
  draw_circle(Vector2.ZERO, 3.0 * breath, Color(_color.r * 0.8, _color.g * 0.8, _color.b * 0.8, 0.9))
  
  # Description label below
  if knot_description.length() > 0:
    var font := get_theme_default_font()
    draw_string(font, Vector2(-60, 28), "⊗: " + knot_description, 0, 120, 11,
      Color(_color.r, _color.g, _color.b, 0.6 * breath))

func _set_scale(value: float) -> void:
  _scale = value

func _input(event: InputEvent) -> void:
  if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
    var local_pos := make_input_local(event).position
    if local_pos.distance_to(Vector2.ZERO) < 25.0:
      knot_examined.emit(self, knot_description)
      Events.distinction_examined.emit(self)
