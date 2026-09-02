# wholeness_boundary.gd — Ω checks whether the pattern is complete (CL-039)
#
# After Guard passes, before SEAL, the Ω (Wholeness) Boundary checks:
# Is the pattern complete enough to act?
#
# It draws an enclosing halo around all scoped+witnessed distinctions.
# Missing parts glow as gaps. If complete, a completion pulse plays.
#
# Wholeness is not about having ALL distinctions — it's about having
# enough that the pattern holds. A distinction alone is a cut.
# A distinction + scope + witness + residual = a complete claim.
#
# The Ω boundary is the organism's sense of its own shape.
# It says: "I am this much. I am not yet more."

extends Node2D

signal wholeness_evaluated(complete: bool, missing: Array)

var _is_active: bool = false
var _breath_time: float = 0.0
var _completeness: float = 0.0  # 0..1
var _missing: Array = []
var _halo_points: PackedVector2Array = []
var _gap_points: PackedVector2Array = []
var _pulse_time: float = 0.0
var _is_complete: bool = false

func _ready() -> void:
  visible = false
  set_process(false)

func activate() -> void:
  _is_active = true
  visible = true
  set_process(true)
  _evaluate()
  
  modulate.a = 0.0
  var tween := create_tween()
  tween.tween_property(self, "modulate:a", 1.0, 0.5)

func deactivate() -> void:
  _is_active = false
  var tween := create_tween()
  tween.tween_property(self, "modulate:a", 0.0, 0.3)
  tween.tween_callback(func(): visible = false; set_process(false))

func _evaluate() -> void:
  var distinctions := Events.get_all_distinctions()
  var scoped_count := Events.get_scoped_count()
  var witnessed_count := Events.get_witnessed_count()
  var has_residual := Events.has_residual()
  
  _missing.clear()
  
  if scoped_count == 0: _missing.append("scope")
  if witnessed_count == 0: _missing.append("witness")
  if not has_residual: _missing.append("residual")
  if distinctions.size() < 2: _missing.append("polarity")
  
  # Completeness = fraction of requirements met
  var total_checks := 4
  var passed := total_checks - _missing.size()
  _completeness = float(passed) / float(total_checks)
  _is_complete = _missing.is_empty()
  
  _compute_halo(distinctions)
  wholeness_evaluated.emit(_is_complete, _missing)

func _compute_halo(distinctions: Array) -> void:
  _halo_points.clear()
  _gap_points.clear()
  
  if distinctions.size() < 2:
    return
  
  # Compute convex hull approximation around scoped+witnessed distinctions
  var center := Vector2.ZERO
  var valid_count := 0
  for d in distinctions:
    if is_instance_valid(d) and (d.is_scoped or d.is_witnessed):
      center += d.position
      valid_count += 1
  
  if valid_count == 0:
    return
  
  center /= valid_count
  
  # Compute max radius
  var max_r := 0.0
  for d in distinctions:
    if is_instance_valid(d) and (d.is_scoped or d.is_witnessed):
      max_r = maxf(max_r, center.distance_to(d.position))
  
  max_r += 30.0  # padding
  
  # Generate halo points as a circle
  var steps := 32
  for i in steps:
    var angle := TAU * float(i) / steps
    _halo_points.append(center + Vector2(cos(angle), sin(angle)) * max_r)
  
  # If incomplete, mark gap points at angles corresponding to missing parts
  if not _is_complete:
    var gap_count := _missing.size()
    for g in gap_count:
      var angle := TAU * float(g) / gap_count - PI / 2  # start at top
      _gap_points.append(center + Vector2(cos(angle), sin(angle)) * max_r)

func _process(delta: float) -> void:
  _breath_time += delta
  if _is_complete:
    _pulse_time += delta
  queue_redraw()

func _draw() -> void:
  if not _is_active or _halo_points.size() < 3:
    return
  
  var halo_color := Color(0.5, 0.7, 0.9, 0.3) if _is_complete else Color(0.6, 0.5, 0.3, 0.2)
  var breath := sin(_breath_time * 0.5) * 0.15 + 0.85
  
  # Draw the halo
  if _is_complete:
    # Complete: solid pulsing ring
    var pulse := sin(_pulse_time * 1.5) * 0.1
    var r := 1.0 + pulse
    var scaled := PackedVector2Array()
    for p in _halo_points:
      var center := Vector2.ZERO
      for hp in _halo_points: center += hp
      center /= _halo_points.size()
      scaled.append(center + (p - center) * r)
    
    # Draw filled polygon (the wholeness boundary)
    draw_colored_polygon(scaled, Color(halo_color.r, halo_color.g, halo_color.b, 0.05 * breath))
    
    # Draw the ring
    for i in scaled.size():
      var next_i := (i + 1) % scaled.size()
      draw_line(scaled[i], scaled[next_i], 
        Color(halo_color.r, halo_color.g, halo_color.b, 0.5 * breath), 2.0)
  else:
    # Incomplete: dashed ring with gaps
    for i in _halo_points.size():
      var next_i := (i + 1) % _halo_points.size()
      draw_line(_halo_points[i], _halo_points[next_i],
        Color(halo_color.r, halo_color.g, halo_color.b, 0.2 * breath), 1.0)
    
    # Draw gap markers
    for gp in _gap_points:
      draw_circle(gp, 8.0, Color(0.8, 0.4, 0.2, 0.4 * breath))
      draw_arc(gp, 8.0, 0, TAU, 16, Color(0.8, 0.4, 0.2, 0.6), 1.5)
  
  # Draw Ω label
  if _halo_points.size() > 0:
    var center := Vector2.ZERO
    for p in _halo_points: center += p
    center /= _halo_points.size()
    draw_string(get_theme_default_font(), center + Vector2(-8, 5), "Ω",
      0, -1, 16, Color(0.5, 0.6, 0.8, 0.3 * breath))

func get_completeness() -> float:
  return _completeness

func is_complete() -> bool:
  return _is_complete

func get_missing() -> Array:
  return _missing
