# events.gd — Ontomatika Event Bus (Autoload Singleton)
# Register as Autoload named "Events" in Project Settings.
#
# This is the nervous system: every ontological event is a signal.
# Systems emit and connect without knowing each other.
#
# CL-032 signals (Question Prompt + Consequence Card):
#   - ritual_state_changed : when the FSM transitions
#   - question_shown       : when a question prompt appears
#   - distinction_made     : when the player makes a distinction in the field
#   - clarity_changed      : when kappa value changes
#   - boundary_formed      : when a distinction creates a boundary
#   - consequence_shown    : when a consequence card is displayed
#   - consequence_dismissed: when the player dismisses the consequence card
#
# Future CL signals are stubbed but commented out for reference.

extends Node

# ── Ritual state machine signals ──
signal ritual_state_changed(new_state: StringName)

# ── CL-032: Question + Consequence ──
signal question_shown(text: String)
signal distinction_made(quality: StringName, position: Vector2)
signal clarity_changed(new_value: float, delta: float)
signal boundary_formed(quality: StringName)
signal consequence_shown(title: String, body: String, metric_label: String, metric_value: String)
signal consequence_dismissed

# ── CL-033: Presence Reveal (stubbed) ──
# signal presence_appeared
# signal presence_noticed

# ── CL-034: Ref Context (stubbed) ──
# signal ref_scoped(in_scope: bool)
# signal ref_question_shown(text: String)

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

# ── Clarity (kappa) state — managed centrally so all systems read the same value ──
var _clarity: float = 0.0

func get_clarity() -> float:
	return _clarity

func set_clarity(value: float) -> void:
	var delta := value - _clarity
	_clarity = clampf(value, 0.0, 1.0)
	clarity_changed.emit(_clarity, delta)