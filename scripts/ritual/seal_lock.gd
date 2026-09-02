# seal_lock.gd — The SEAL lock (CL-040)
#
# SEAL is the irreversible lock. Once sealed, a distinction is permanent.
# It stops all animation. Its glyph becomes ◉. It cannot be changed.
#
# SEAL requires:
#   - Guard PASS (stable, scoped, witnessed)
#   - Ω Wholeness complete
#   - Residual named
#
# SEAL is rare and consequential. The player must choose to seal.
# A confirmation prompt appears: "Seal this? This cannot be undone."
# If the player confirms, all distinctions in the current cycle are sealed.
#
# Ontological grounding:
#   SEAL = the 1 in R-7 protocol (dejanje/SEAL). The act that cannot be taken back.
#   "Names permanent only through SEAL."
#   A sealed distinction becomes part of the world's permanent memory.

extends Node2D

signal seal_completed(distinctions: Array)
signal seal_cancelled

var _is_active: bool = false
var _breath_time: float = 0.0
var _seal_anim_time: float = 0.0
var _is_sealing: bool = false
var _sealing_complete: bool = false

func _ready() -> void:
  visible = false
  set_process(false)

func activate() -> void:
  _is_active = true
  visible = true
  set_process(true)
  
  modulate.a = 0.0
  var tween := create_tween()
  tween.tween_property(self, "modulate:a", 1.0, 0.4)

func deactivate() -> void:
  _is_active = false
  var tween := create_tween()
  tween.tween_property(self, "modulate:a", 0.0, 0.3)
  tween.tween_callback(func(): visible = false; set_process(false))

func _process(delta: float) -> void:
  _breath_time += delta
  if _is_sealing:
    _seal_anim_time += delta
    if _seal_anim_time > 1.5 and not _sealing_complete:
      _sealing_complete = true
      _execute_seal()
  queue_redraw()

func _draw() -> void:
  if not _is_active:
    return
  
  var breath := sin(_breath_time * 0.8) * 0.2 + 0.8
  
  if _is_sealing:
    # Sealing animation: expanding ring that contracts to a point
    var t := clampf(_seal_anim_time / 1.5, 0.0, 1.0)
    var ring_r := lerpf(60.0, 5.0, t)
    var alpha := 1.0 - t
    
    # Multiple concentric rings
    for i in 3:
      var offset := i * 0.2
      var r := ring_r + offset * 20.0
      draw_arc(Vector2.ZERO, r, 0, TAU, 32,
        Color(0.7, 0.8, 1.0, alpha * (1.0 - float(i) / 3.0)), 2.0)
    
    # Central ◉ forming
    var core_alpha := clampf(t * 2.0, 0.0, 1.0)
    draw_circle(Vector2.ZERO, 4.0, Color(0.8, 0.9, 1.0, core_alpha))
    draw_arc(Vector2.ZERO, 6.0, 0, TAU, 16, Color(0.8, 0.9, 1.0, core_alpha), 1.5)

func begin_seal() -> void:
  _is_sealing = true
  _seal_anim_time = 0.0
  _sealing_complete = false

func _execute_seal() -> void:
  var distinctions := Events.get_all_distinctions()
  var sealed := []
  
  for d in distinctions:
    if is_instance_valid(d) and not d.is_sealed:
      d.seal()
      sealed.append(d)
  
  seal_completed.emit(sealed)

func cancel() -> void:
  _is_sealing = false
  _seal_anim_time = 0.0
  seal_cancelled.emit()
  deactivate()

func is_sealing() -> bool:
  return _is_sealing

func is_complete() -> bool:
  return _sealing_complete
