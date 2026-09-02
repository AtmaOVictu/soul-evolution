# ritual_state_machine.gd — Ontomatika Ritual State Machine
#
# The logic spine of the ritual loop. Each OntologyStage is a state.
# CL-033 implements: VOID -> PRESENCE -> QUESTION -> DISTINCTION -> BOUNDARY
#
# Future states (CL-034 onward) are defined but guarded with _is_implemented flags.
#
# The state machine owns the SEQUENCE. The event bus owns the PROPAGATION.
#
# CL-033 CHANGES:
#   - PRESENCE state activated
#   - start_ritual() now goes VOID -> PRESENCE (not straight to QUESTION)
#   - A PresenceNode is spawned at a random position
#   - Player must notice it before the question appears
#   - On presence_noticed, transition PRESENCE -> QUESTION

extends Node

# ── Ritual states ──
enum State {
  VOID,         # Nothing yet — black screen, waiting to begin
  PRESENCE,     # CL-033: Something appeared, player must notice
  QUESTION,     # "What is different here?" — prompt shown, input enabled
  DISTINCTION,  # Player is making a distinction (clicking the field)
  BOUNDARY,     # Distinction made, boundary forming, consequence shown
  # ── Future states (CL-034 -> CL-038) ──
  CONTEXT,      # CL-034: "Where is this true?" — Ref scope
  EVIDENCE,     # CL-035: Player attaches evidence
  GUARD_CHECK,  # CL-036: Guard evaluates
  RESIDUAL,     # CL-037: "What remains unresolved?"
  KNOT,         # CL-038: Problem Knot created
}

var current_state: State = State.VOID
var _is_implemented: Dictionary = {
  State.VOID: true,
  State.PRESENCE: true,   # CL-033: NOW IMPLEMENTED
  State.QUESTION: true,
  State.DISTINCTION: true,
  State.BOUNDARY: true,
  State.CONTEXT: false,
  State.EVIDENCE: false,
  State.GUARD_CHECK: false,
  State.RESIDUAL: false,
  State.KNOT: false,
}

# ── Ritual content ──
const FIRST_QUESTION := "What is different here?"
const NEXT_QUESTION_AFTER_BOUNDARY := "Where is this true?"
const PRESENCE_HINT := "Something stirs in the void..."

# ── Internal ──
var _question_shown: bool = false
var _presence_node: Node2D = null
var _presence_seed_position: Vector2 = Vector2.ZERO

# ── Scene references (set by parent or found by path) ──
@onready var _distinction_field: Control = get_parent().get_node_or_null("DistinctionField")

func _ready() -> void:
  Events.ritual_state_changed.connect(_on_state_changed)
  Events.distinction_made.connect(_on_distinction_made)
  Events.consequence_dismissed.connect(_on_consequence_dismissed)
  Events.presence_noticed.connect(_on_presence_noticed)

func start_ritual() -> void:
  # CL-033: Start with PRESENCE, not QUESTION
  transition_to(State.PRESENCE)

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
    State.PRESENCE:
      _spawn_presence()
    State.QUESTION:
      if not _question_shown:
        _question_shown = true
        Events.question_shown.emit(FIRST_QUESTION)
    State.BOUNDARY:
      pass

# ── CL-033: Presence ──
func _spawn_presence() -> void:
  # Pick a position in the upper-center area of the screen
  # Not center — the presence should require the player to look
  var viewport_size := get_viewport().get_visible_rect().size
  var margin := viewport_size * 0.2
  
  var rng := RandomNumberGenerator.new()
  rng.randomize()
  
  var x := rng.randf_range(margin.x, viewport_size.x - margin.x)
  var y := rng.randf_range(margin.y, viewport_size.y * 0.6)  # upper portion
  
  var pos := Vector2(x, y)
  
  # Create the PresenceNode
  var PresenceNodeScript = preload("res://scripts/ritual/presence_node.gd")
  var node := Node2D.new()
  node.set_script(PresenceNodeScript)
  node.position = pos
  
  # Add to the distinction layer (same parent as distinctions)
  var layer := get_parent().get_node_or_null("DistinctionLayer")
  if layer:
    layer.add_child(node)
  else:
    get_parent().add_child(node)
  
  _presence_node = node
  node.activate(pos)
  Events.presence_activated.emit(pos)

func _on_presence_noticed(pos: Vector2) -> void:
  _presence_seed_position = pos
  # After the presence is noticed, transition to QUESTION
  # Small delay to let the noticed animation play
  await get_tree().create_timer(1.2).timeout
  transition_to(State.QUESTION)

func get_presence_seed() -> Vector2:
  return _presence_seed_position

# ── Existing handlers ──
func _on_distinction_made(quality: StringName, _position: Vector2) -> void:
  if current_state == State.QUESTION or current_state == State.DISTINCTION:
    Events.boundary_formed.emit(null)  # boundary_formed now takes Line2D, but FSM just needs to transition
    transition_to(State.BOUNDARY)

func _on_consequence_dismissed() -> void:
  if current_state == State.BOUNDARY:
    Events.question_shown.emit(NEXT_QUESTION_AFTER_BOUNDARY)
    transition_to(State.QUESTION)
