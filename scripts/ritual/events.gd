# events.gd — Ontomatika Event Bus (Autoload Singleton)
# REFACTORED: clarity is per-distinction, not global.
# Aggregate clarity is queried, not stored.

extends Node

# ── Ritual state machine ──
signal ritual_state_changed(new_state: StringName)

# ── CL-032: Question + Consequence ──
signal question_shown(text: String)
signal distinction_made(quality: StringName, position: Vector2)
signal boundary_formed(boundary: Line2D)
signal consequence_shown(title: String, body: String, metric_label: String, metric_value: String)
signal consequence_dismissed

# ── Per-node clarity (NEW — replaces global clarity) ──
signal local_clarity_changed(node: Node, new_value: float, delta: float)
signal distinction_stage_changed(node: Node2D, stage_name: StringName)
signal distinction_spawned(node: Node2D)
signal distinction_examined(node: Node2D)

# ── CL-033: Presence Reveal (stubbed) ──
# signal presence_appeared
# signal presence_noticed

# ── CL-034: Ref Context ──
signal ref_activated(frame_rect: Rect2)
signal ref_moved(frame_rect: Rect2)

# ── CL-035: Evidence Spark (stubbed) ──
# signal evidence_attached(event_id: String)
# signal evidence_requested

# ── CL-036: Guard Check (stubbed) ──
# signal guard_evaluated(result: Dictionary)
# signal guard_requested

# ── CL-037: Residual Naming (stubbed) ──
# signal residual_named(name: String)
# signal residual_requested

# ── CL-038: Problem Knot (stubbed) ──
# signal problem_knot_created(knot_data: Dictionary)
# signal seal_attempted
# signal seal_blocked(reasons: Array)

# ── Aggregate clarity query ──
# Clarity is NOT a stored value. It is computed from all distinction nodes.
# The clarity bar calls this to get the aggregate.

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