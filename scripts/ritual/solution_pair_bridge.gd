# solution_pair_bridge.gd — Turn a resolved Problem Knot into repair (CL-042)
#
# A Solution Pair Bridge connects a Problem Knot to a RES Material Card.
# When the player has both a knot and a sealed RES card, they can bridge
# them: the RES material addresses what the knot is missing.
#
# The bridge is a visible arc between the knot and the RES card.
# When bridged:
#   - The knot dissolves (it was addressed, not erased)
#   - The RES card gains a "resolved" marker
#   - A consequence card: "A bridge forms. The knot loosens."
#
# Ontological grounding:
#   ∴ — the bridge operator (povezava)
#   Repair is not erasure. The knot was real. It happened. The bridge
#   acknowledges it and moves forward.
#   "Resničnost je proces, ne končna točka."

extends Node2D

signal bridge_formed(knot: Node2D, res_card: Node2D)
signal bridge_broken

var _knot: Node2D = null
var _res_card: Node2D = null
var _is_bridged: bool = false
var _breath_time: float = 0.0
var _bridge_progress: float = 0.0  # 0..1 animation
var _dissolve_time: float = 0.0

func _ready() -> void:
  visible = false
  set_process(false)

func setup(knot: Node2D, res_card: Node2D) -> void:
  _knot = knot
  _res_card = res_card
  visible = true
  set_process(true)
  
  # Animate the bridge forming
  _bridge_progress = 0.0
  var tween := create_tween()
  tween.tween_property(self, "_bridge_progress", 1.0, 0.8)
  tween.set_trans(Tween.TRANS_SINE)
  tween.set_ease(Tween.EASE_IN_OUT)
  tween.tween_callback(func(): _on_bridge_complete())

func _process(delta: float) -> void:
  _breath_time += delta
  if _is_bridged and _knot and is_instance_valid(_knot):
    _dissolve_time += delta
    # Slowly dissolve the knot
    if _dissolve_time > 2.0:
      _knot.modulate.a = lerpf(_knot.modulate.a, 0.0, delta * 0.5)
      if _knot.modulate.a < 0.05:
        _knot.queue_free()
        _knot = null
        set_process(false)
  queue_redraw()

func _on_bridge_complete() -> void:
  _is_bridged = true
  bridge_formed.emit(_knot, _res_card)

func _draw() -> void:
  if not _knot or not is_instance_valid(_knot) or not _res_card or not is_instance_valid(_res_card):
    return
  
  var knot_pos := _knot.global_position - global_position
  var card_pos := _res_card.global_position - global_position
  
  var breath := sin(_breath_time * 0.8) * 0.1 + 0.9
  
  # Draw the bridge arc
  var mid := (knot_pos + card_pos) / 2
  var perp := Vector2(-(card_pos.y - knot_pos.y), card_pos.x - knot_pos.x).normalized() * 20.0
  var control := mid + perp
  
  # Draw curved line with progress
  var segments := 20
  var prev := knot_pos
  for i in range(1, segments + 1):
    var t := float(i) / segments
    if t > _bridge_progress:
      break
    var point := knot_pos.bezier_interpolate(control, control, card_pos, t)
    draw_line(prev, point, Color(0.5, 0.7, 0.9, 0.4 * breath * _bridge_progress), 2.0)
    prev = point
  
  # Draw ∴ at midpoint when complete
  if _is_bridged:
    draw_string(get_theme_default_font(), mid + Vector2(-4, 5),
      "∴", 0, -1, 14, Color(0.6, 0.8, 1.0, 0.6 * breath))

func is_bridged() -> bool:
  return _is_bridged

func _set_bridge_progress(value: float) -> void:
  _bridge_progress = value
