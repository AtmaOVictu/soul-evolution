# events.gd — Ontomatika Event Bus (Autoload Singleton)
# Register as Autoload named "Events" in Project Settings.
#
# CL-033: Presence
# CL-034: Ref Context / Scope
# CL-035: Evidence
# CL-036: Guard
# CL-037: Residual
# CL-038: Problem Knot
# CL-039: Wholeness
# CL-040: SEAL
# CL-041: RES Material
# CL-042: Solution Pair Bridge
# CL-043: Agent Routing

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

# CL-035: Evidence
signal evidence_attached(node: Node2D)
signal evidence_skipped

# CL-036: Guard
signal guard_result(result: Dictionary)

# CL-037: Residual
signal residual_named(name: String)
signal residual_seed_created(node: Node2D)

# CL-038: Problem Knot
signal knot_created(knot: Node2D, description: String)
signal knot_examined(knot: Node2D, description: String)

# CL-039: Wholeness
signal wholeness_evaluated(complete: bool, missing: Array)

# CL-040: SEAL
signal seal_available
signal seal_completed(distinctions: Array)
signal seal_cancelled

# CL-041: RES Material
signal res_card_created(card: Node2D, info: Dictionary)
signal res_card_inspected(card: Node2D, info: Dictionary)

# CL-042: Solution Pair Bridge
signal bridge_formed(knot: Node2D, res_card: Node2D)

# CL-043: Agent Routing
signal agent_routed(agent_type: StringName, res_card: Node2D, result: Dictionary)

var _distinction_registry: Array[Node2D] = []
var _residual_name: String = ""
var _res_cards: Array[Node2D] = []
var _knots: Array[Node2D] = []
var _bridges: Array[Node2D] = []

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

func get_witnessed_count() -> int:
  var count := 0
  for d in _distinction_registry:
    if is_instance_valid(d) and d.is_witnessed:
      count += 1
  return count

func get_scoped_count() -> int:
  var count := 0
  for d in _distinction_registry:
    if is_instance_valid(d) and d.is_scoped:
      count += 1
  return count

func get_sealed_count() -> int:
  var count := 0
  for d in _distinction_registry:
    if is_instance_valid(d) and d.is_sealed:
      count += 1
  return count

func has_residual() -> bool:
  return _residual_name != ""

func set_residual_name(name: String) -> void:
  _residual_name = name

func get_residual_name() -> String:
  return _residual_name

# RES Card registry
func register_res_card(card: Node2D) -> void:
  _res_cards.append(card)

func get_all_res_cards() -> Array[Node2D]:
  return _res_cards.deduplicate()

# Knot registry
func register_knot(knot: Node2D) -> void:
  _knots.append(knot)

func get_all_knots() -> Array[Node2D]:
  return _knots.deduplicate()

# Bridge registry
func register_bridge(bridge: Node2D) -> void:
  _bridges.append(bridge)
