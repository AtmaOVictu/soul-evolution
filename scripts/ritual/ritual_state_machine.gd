# ritual_state_machine.gd — Ontomatika Ritual State Machine
#
# CL-033: VOID -> PRESENCE -> QUESTION
# CL-034: -> CONTEXT (Ref frame, scope)
# CL-035: -> EVIDENCE (witness distinctions)
#
# After scope is defined, the game asks the player to witness what they
# have distinguished. Evidence is the ⟡ that turns an event into a
# traceable consequence.

extends Node

enum State {
  VOID,
  PRESENCE,
  QUESTION,
  DISTINCTION,
  BOUNDARY,
  CONTEXT,
  EVIDENCE,     # CL-035: NOW IMPLEMENTED
  GUARD_CHECK,
  RESIDUAL,
  KNOT,
}

var current_state: State = State.VOID
var _is_implemented: Dictionary = {
  State.VOID: true,
  State.PRESENCE: true,
  State.QUESTION: true,
  State.DISTINCTION: true,
  State.BOUNDARY: true,
  State.CONTEXT: true,
  State.EVIDENCE: true,   # CL-035: NOW IMPLEMENTED
  State.GUARD_CHECK: false,
  State.RESIDUAL: false,
  State.KNOT: false,
}

const FIRST_QUESTION := "What is different here?"
const NEXT_QUESTION_AFTER_BOUNDARY := "Where is this true?"
const EVIDENCE_QUESTION := "What have you witnessed?"
const PRESENCE_HINT := "Something stirs in the void..."

const CONTEXT_CONSEQUENCE_TITLE := "Scope defined"
const CONTEXT_CONSEQUENCE_BODY := "Meaning holds where the frame encompasses it. Distinctions outside remain unbound."
const CONTEXT_CONSEQUENCE_ALL_OUTSIDE_BODY := "No scope. Meaning unbound is meaning dissolved."

const EVIDENCE_CONSEQUENCE_TITLE := "Witnessed"
const EVIDENCE_CONSEQUENCE_BODY := "The distinction holds. It will not flicker. ⟡"
const EVIDENCE_CONSEQUENCE_SKIP_BODY := "Unwitnessed distinctions remain effects, not consequences."

var _question_shown: bool = false
var _presence_node: Node2D = null
var _presence_seed_position: Vector2 = Vector2.ZERO
var _ref_region: Node2D = null
var _scope_changed_count: int = 0
var _evidence_count: int = 0

@onready var _distinction_field: Control = get_parent().get_node_or_null("DistinctionField")

func _ready() -> void:
  Events.ritual_state_changed.connect(_on_state_changed)
  Events.distinction_made.connect(_on_distinction_made)
  Events.consequence_dismissed.connect(_on_consequence_dismissed)
  Events.presence_noticed.connect(_on_presence_noticed)
  Events.scope_changed.connect(_on_scope_changed)
  Events.evidence_attached.connect(_on_evidence_attached)
  Events.evidence_skipped.connect(_on_evidence_skipped)

func start_ritual() -> void:
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
    State.CONTEXT:
      _activate_ref_frame()
    State.EVIDENCE:
      _evidence_count = 0
      Events.question_shown.emit(EVIDENCE_QUESTION)
    State.BOUNDARY:
      pass

# ── CL-033: Presence ──
func _spawn_presence() -> void:
  var viewport_size := get_viewport().get_visible_rect().size
  var margin := viewport_size * 0.2
  
  var rng := RandomNumberGenerator.new()
  rng.randomize()
  
  var x := rng.randf_range(margin.x, viewport_size.x - margin.x)
  var y := rng.randf_range(margin.y, viewport_size.y * 0.6)
  var pos := Vector2(x, y)
  
  var PresenceNodeScript = preload("res://scripts/ritual/presence_node.gd")
  var node := Node2D.new()
  node.set_script(PresenceNodeScript)
  node.position = pos
  
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
  await get_tree().create_timer(1.2).timeout
  transition_to(State.QUESTION)

func get_presence_seed() -> Vector2:
  return _presence_seed_position

# ── CL-034: Ref Context ──
func _activate_ref_frame() -> void:
  _scope_changed_count = 0
  
  if not _ref_region or not is_instance_valid(_ref_region):
    var RefScript = preload("res://scripts/ritual/ref_region.gd")
    _ref_region = Node2D.new()
    _ref_region.set_script(RefScript)
    
    var distinctions := Events.get_all_distinctions()
    if distinctions.size() > 0:
      var center := Vector2.ZERO
      for d in distinctions:
        center += d.position
      center /= distinctions.size()
      _ref_region.position = center + Vector2(-60, -40)
    else:
      _ref_region.position = get_viewport().get_visible_rect().size / 2
    
    var layer := get_parent().get_node_or_null("DistinctionLayer")
    if layer:
      layer.add_child(_ref_region)
    else:
      get_parent().add_child(_ref_region)
  
  _ref_region.activate()
  Events.ref_activated.emit(_ref_region._get_frame_rect())

func _on_scope_changed(in_scope: Array, out_of_scope: Array) -> void:
  if current_state != State.CONTEXT:
    return
  
  _scope_changed_count += 1
  
  if _scope_changed_count == 1:
    var body := CONTEXT_CONSEQUENCE_BODY
    if in_scope.is_empty():
      body = CONTEXT_CONSEQUENCE_ALL_OUTSIDE_BODY
    
    var agg_kappa := Events.get_aggregate_clarity()
    var scoped_count := in_scope.size()
    var total := in_scope.size() + out_of_scope.size()
    
    Events.consequence_shown.emit(
      CONTEXT_CONSEQUENCE_TITLE,
      body,
      "κ | Scoped: %d/%d" % [scoped_count, total],
      "%.2f (%d scoped)" % [agg_kappa, scoped_count]
    )
    transition_to(State.BOUNDARY)

# ── CL-035: Evidence ──
func _on_evidence_attached(node: Node2D) -> void:
  if current_state != State.EVIDENCE:
    return
  
  _evidence_count += 1
  
  var agg_kappa := Events.get_aggregate_clarity()
  var witnessed := Events.get_witnessed_count()
  var total := Events.get_distinction_count()
  
  Events.consequence_shown.emit(
    EVIDENCE_CONSEQUENCE_TITLE,
    EVIDENCE_CONSEQUENCE_BODY,
    "κ | Witnessed: %d/%d" % [witnessed, total],
    "%.2f (%d ⟡)" % [agg_kappa, witnessed]
  )
  transition_to(State.BOUNDARY)

func _on_evidence_skipped() -> void:
  if current_state != State.EVIDENCE:
    return
  
  Events.consequence_shown.emit(
    "Unwitnessed",
    EVIDENCE_CONSEQUENCE_SKIP_BODY,
    "κ | Witnessed: 0/%d" % Events.get_distinction_count(),
    "What remains unheld?"
  )
  transition_to(State.BOUNDARY)

# ── Distinction / Consequence handlers ──
func _on_distinction_made(quality: StringName, _position: Vector2) -> void:
  if current_state == State.QUESTION or current_state == State.DISTINCTION:
    Events.boundary_formed.emit(null)
    transition_to(State.BOUNDARY)

func _on_consequence_dismissed() -> void:
  if current_state == State.BOUNDARY:
    # Flow: BOUNDARY (after distinction) -> CONTEXT -> BOUNDARY (after scope) -> EVIDENCE
    # We need to track where we came from.
    # After first distinction cycle: go to CONTEXT
    # After scope consequence: go to EVIDENCE
    # After evidence consequence: go to GUARD_CHECK (future) or back to QUESTION
    
    var witnessed := Events.get_witnessed_count()
    var total := Events.get_distinction_count()
    
    if _scope_changed_count > 0 and _evidence_count == 0:
      # We just came from scope, go to evidence
      transition_to(State.EVIDENCE)
    elif _evidence_count > 0:
      # We just witnessed, go back to QUESTION for next cycle
      # (or in future: GUARD_CHECK)
      _evidence_count = 0
      _scope_changed_count = 0
      Events.question_shown.emit(FIRST_QUESTION)
      transition_to(State.QUESTION)
    else:
      # First cycle: after boundary consequence, go to context
      Events.question_shown.emit(NEXT_QUESTION_AFTER_BOUNDARY)
      transition_to(State.CONTEXT)
