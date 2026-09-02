# events.gd — Ontomatika Event Bus (Autoload Singleton)
# Register as Autoload named "Events" in Project Settings.
#
# CL-033: Presence signals
# CL-034: Scope/signal added

extends Node

signal ritual_state_changed(new_state: StringName)

signal question_shown(text: String)
signal distinction_made(quality: StringName, position: Vector2)
signal boundary_formed(boundary: Line2D)
signal consequence_shown(title: String, body: String, metric_label: String, metric_value: String)
signal consequence_dismissed

signal local_clarity_changed(node: Node, new_value: float, delta: float)
signal distinction_stage_changed(node: Node2D, stage_name: StringName)
signal distinction_spawned(node: Node2D)
signal distinction_examined(node: Node2D)

# CL-033: Presence
signal presence_activated(position: Vector2)
signal presence_noticed(position: Vector2)

# CL-034: Ref Context
signal ref_activated(frame_rect: Rect2)
signal ref_moved(frame_rect: Rect2)
signal scope_changed(in_scope: Array, out_of_scope: Array)

# CL-035: Evidence Spark (stubbed)
# signal evidence_attached(event_id: String)

# CL-036: Guard Check (stubbed)
# signal guard_check_requested
# signal guard_result(passed: bool, reasons: Array)

# CL-037: Residual Naming (stubbed)
# signal residual_named(name: String)

# CL-038: Problem Knot (stubbed)
# signal knot_created(knot_id: String, description: String)

# SEAL (future)
# signal seal_attempted
# signal seal_blocked(reasons: Array)

var _distinction_registry: Array[Node2D] = []

func register_distinction(node: Node2D) -> void:
  if node not in _distinction_registry:
    _distinction_registry.append(node)
    distinction_spawned.emit(node)

func unregister_distinction(node: Node2D) -> void:
  _distinction_registry.erase(node)

func get_all_distinctions() -> Array[Node2D]:
  return _distinction_registry.deduplicate()

func get_aggregate_clarity() -> float:
  if _distinction_registry.is_empty():
    return 0.0
  var total := 0.0
  for d in _distinction_registry:
    if is_instance_valid(d):
      total += d.local_clarity
  return total / _distinction_registry.size()

func get_distinction_count() -> int:
  return _distinction_registry.size()

func get_max_clarity() -> float:
  var max_c := 0.0
  for d in _distinction_registry:
    if is_instance_valid(d) and d.local_clarity > max_c:
      max_c = d.local_clarity
  return max_c
