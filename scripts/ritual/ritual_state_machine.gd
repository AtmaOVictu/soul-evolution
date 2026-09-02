# ritual_state_machine.gd — Ontomatika Ritual State Machine
#
# The logic spine of the ritual loop. Each OntologyStage is a state.
# CL-032 implements: VOID -> QUESTION -> DISTINCTION -> BOUNDARY -> (loop)
#
# Future states (CL-033 onward) are defined but guarded with _is_implemented flags.
#
# Usage: Add as a child of the main ritual scene. Connect to Events bus.
# The state machine owns the SEQUENCE. The event bus owns the PROPAGATION.

extends Node

# ── Ritual states ──
enum State {
	VOID,         # Nothing yet — black screen, waiting to begin
	QUESTION,      # "What is different here?" — prompt shown, input enabled
	DISTINCTION,   # Player is making a distinction (clicking the field)
	BOUNDARY,      # Distinction made, boundary forming, consequence shown
	# ── Future states (CL-033 -> CL-038) ──
	PRESENCE,      # CL-033: Something appeared, player must notice
	CONTEXT,       # CL-034: "Where is this true?" — Ref scope
	EVIDENCE,      # CL-035: Player attaches evidence
	GUARD_CHECK,   # CL-036: Guard evaluates
	RESIDUAL,      # CL-037: "What remains unresolved?"
	KNOT,          # CL-038: Problem Knot created
}

var current_state: State = State.VOID
var _is_implemented: Dictionary = {
	State.VOID: true,
	State.QUESTION: true,
	State.DISTINCTION: true,
	State.BOUNDARY: true,
	State.PRESENCE: false,
	State.CONTEXT: false,
	State.EVIDENCE: false,
	State.GUARD_CHECK: false,
	State.RESIDUAL: false,
	State.KNOT: false,
}

# ── Ritual content ──
const FIRST_QUESTION := "What is different here?"
const NEXT_QUESTION_AFTER_BOUNDARY := "Where is this true?"

# ── Internal ──
var _question_shown: bool = false

func _ready() -> void:
	Events.ritual_state_changed.connect(_on_state_changed)
	Events.distinction_made.connect(_on_distinction_made)
	Events.consequence_dismissed.connect(_on_consequence_dismissed)

func start_ritual() -> void:
	transition_to(State.QUESTION)

func transition_to(new_state: State) -> void:
	if new_state == current_state:
		return
	if not _is_implemented.get(new_state, false):
		push_warning("State %s is not yet implemented (CL future task)" % State.keys()[new_state])
		return
	
	current_state = new_state
	Events.ritual_state_changed.emit(StringName(State.keys()[new_state]))

func _on_state_changed(_state_name: StringName) -> void:
	match current_state:
		State.QUESTION:
			if not _question_shown:
				_question_shown = true
				Events.question_shown.emit(FIRST_QUESTION)
		State.BOUNDARY:
			# After boundary, wait for consequence dismissal before next question
			pass

func _on_distinction_made(quality: StringName, _position: Vector2) -> void:
	# A distinction was made in the field. Transition from QUESTION -> BOUNDARY.
	if current_state == State.QUESTION or current_state == State.DISTINCTION:
		Events.boundary_formed.emit(quality)
		transition_to(State.BOUNDARY)

func _on_consequence_dismissed() -> void:
	# Player dismissed the consequence card. Show next question.
	if current_state == State.BOUNDARY:
		Events.question_shown.emit(NEXT_QUESTION_AFTER_BOUNDARY)
		transition_to(State.QUESTION)