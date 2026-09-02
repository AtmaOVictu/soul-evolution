# ritual_state_machine.gd — Ontomatika Ritual State Machine
#
# CL-033: VOID -> PRESENCE -> QUESTION
# CL-034: -> CONTEXT (Ref frame, scope)
# CL-035: -> EVIDENCE (witness)
# CL-036: -> GUARD_CHECK (organism's immune system)
# CL-037: -> RESIDUAL (name what remains)
#
# After evidence, the Guard evaluates. If SEAL is blocked (residual
# unnamed), the player names what remains. A ℜ seed appears.

extends Node

const GuardCheck = preload("res://scripts/ritual/guard_check.gd")

enum State {
  VOID,
  PRESENCE,
  QUESTION,
  DISTINCTION,
  BOUNDARY,
  CONTEXT,
  EVIDENCE,
  GUARD_CHECK,  # CL-036: NOW IMPLEMENTED
  RESIDUAL,     # CL-037: NOW IMPLEMENTED
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
  State.EVIDENCE: true,
  State.GUARD_CHECK: true,  # CL-036
  State.RESIDUAL: true,     # CL-037
  State.KNOT: false,        # CL-038
}

const FIRST_QUESTION := "What is different here?"
const NEXT_QUESTION_AFTER_BOUNDARY := "Where is this true?"
const EVIDENCE_QUESTION := "What have you witnessed?"
const GUARD_QUESTION := "Is this ready to hold?"
const RESIDUAL_QUESTION := "What remains unresolved?"
const PRESENCE_HINT := "Something stirs in the void..."

const CONTEXT_CONSEQUENCE_TITLE := "Scope defined"
const CONTEXT_CONSEQUENCE_BODY := "Meaning holds where the frame encompasses it."
const EVIDENCE_CONSEQUENCE_TITLE := "Witnessed"
const EVIDENCE_CONSEQUENCE_BODY := "The distinction holds. It will not flicker. ⟡"
const GUARD_PASS_TITLE := "Stable"
const GUARD_PASS_BODY := "The distinction is stable, scoped, witnessed. It may be sealed."
const GUARD_BLOCK_TITLE := "SEAL blocked"
const GUARD_BLOCK_BODY := "Name what remains unresolved before sealing."
const RESIDUAL_TITLE := "Residual named"
const RESIDUAL_BODY := "ℜ remains. Not every good answer is sealable. Some are valuable because they name what remains."

var _question_shown: bool = false
var _presence_node: Node2D = null
var _presence_seed_position: Vector2 = Vector2.ZERO
var _ref_region: Node2D = null
var _scope_changed_count: int = 0
var _evidence_count: int = 0
var _guard_evaluated: bool = false

func _ready() -> void:
  Events.ritual_state_changed.connect(_on_state_changed)
  Events.distinction_made.connect(_on_distinction_made)
  Events.consequence_dismissed.connect(_on_consequence_dismissed)
  Events.presence_noticed.connect(_on_presence_noticed)
  Events.scope_changed.connect(_on_scope_changed)
  Events.evidence_attached.connect(_on_evidence_attached)
  Events.evidence_skipped.connect(_on_evidence_skipped)
  Events.residual_named.connect(_on_residual_named)

func start_ritual() -> void:
  transition_to(State.PRESENCE)

func transition_to(new_state: State) -> void:
  if new_state == current_state:
    return
  if not _is_implemented.get(new_state, false):
    push_warning("State %s is not yet implemented" % State.keys()[new_state])
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
    State.GUARD_CHECK:
      _evaluate_guard()
    State.RESIDUAL:
      Events.question_shown.emit(RESIDUAL_QUESTION)

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
  if layer: layer.add_child(node)
  else: get_parent().add_child(node)
  _presence_node = node
  node.activate(pos)
  Events.presence_activated.emit(pos)

func _on_presence_noticed(pos: Vector2) -> void:
  _presence_seed_position = pos
  await get_tree().create_timer(1.2).timeout
  transition_to(State.QUESTION)

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
      for d in distinctions: center += d.position
      center /= distinctions.size()
      _ref_region.position = center + Vector2(-60, -40)
    else:
      _ref_region.position = get_viewport().get_visible_rect().size / 2
    var layer := get_parent().get_node_or_null("DistinctionLayer")
    if layer: layer.add_child(_ref_region)
    else: get_parent().add_child(_ref_region)
  _ref_region.activate()
  Events.ref_activated.emit(_ref_region._get_frame_rect())

func _on_scope_changed(in_scope: Array, out_of_scope: Array) -> void:
  if current_state != State.CONTEXT: return
  _scope_changed_count += 1
  if _scope_changed_count == 1:
    var body := CONTEXT_CONSEQUENCE_BODY
    if in_scope.is_empty(): body = "No scope. Meaning unbound is meaning dissolved."
    var agg_kappa := Events.get_aggregate_clarity()
    Events.consequence_shown.emit(CONTEXT_CONSEQUENCE_TITLE, body,
      "κ | Scoped: %d/%d" % [in_scope.size(), in_scope.size() + out_of_scope.size()],
      "%.2f (%d scoped)" % [agg_kappa, in_scope.size()])
    transition_to(State.BOUNDARY)

# ── CL-035: Evidence ──
func _on_evidence_attached(node: Node2D) -> void:
  if current_state != State.EVIDENCE: return
  _evidence_count += 1
  var agg_kappa := Events.get_aggregate_clarity()
  var witnessed := Events.get_witnessed_count()
  var total := Events.get_distinction_count()
  Events.consequence_shown.emit(EVIDENCE_CONSEQUENCE_TITLE, EVIDENCE_CONSEQUENCE_BODY,
    "κ | Witnessed: %d/%d" % [witnessed, total], "%.2f (%d ⟡)" % [agg_kappa, witnessed])
  transition_to(State.BOUNDARY)

func _on_evidence_skipped() -> void:
  if current_state != State.EVIDENCE: return
  Events.consequence_shown.emit("Unwitnessed",
    "Unwitnessed distinctions remain effects, not consequences.",
    "κ | Witnessed: 0/%d" % Events.get_distinction_count(), "What remains unheld?")
  transition_to(State.BOUNDARY)

# ── CL-036: Guard Check ──
func _evaluate_guard() -> void:
  _guard_evaluated = true
  var has_residual := Events.has_residual()
  var result := GuardCheck.check_seal_eligibility(has_residual)
  
  Events.guard_result.emit(result)
  
  if result["can_seal"]:
    Events.consequence_shown.emit(GUARD_PASS_TITLE, GUARD_PASS_BODY,
      "κ | Guard: stable", "%.2f (ready to seal)" % Events.get_aggregate_clarity())
    # In future CL: allow SEAL here
    # For now, transition back to QUESTION
    transition_to(State.BOUNDARY)
  else:
    Events.consequence_shown.emit(GUARD_BLOCK_TITLE, GUARD_BLOCK_BODY,
      "κ | Guard: %s" % result["reason"], "What remains?")
    # Go to RESIDUAL (CL-037)
    transition_to(State.RESIDUAL)

# ── CL-037: Residual ──
func _on_residual_named(name: String) -> void:
  if current_state != State.RESIDUAL: return
  Events.set_residual_name(name)
  
  # Create residual seed visual
  var ResidualScript = preload("res://scripts/ritual/residual_seed.gd")
  var seed := Node2D.new()
  seed.set_script(ResidualScript)
  seed.setup(name)
  
  # Position near the distinctions
  var distinctions := Events.get_all_distinctions()
  if distinctions.size() > 0:
    seed.position = distinctions[0].position + Vector2(40, 40)
  else:
    seed.position = get_viewport().get_visible_rect().size / 2
  
  var layer := get_parent().get_node_or_null("DistinctionLayer")
  if layer: layer.add_child(seed)
  else: get_parent().add_child(seed)
  
  Events.residual_seed_created.emit(seed)
  
  Events.consequence_shown.emit(RESIDUAL_TITLE, RESIDUAL_BODY,
    "ℜ: %s" % name, "%.2f (residual held)" % Events.get_aggregate_clarity())
  transition_to(State.BOUNDARY)

# ── Distinction / Consequence handlers ──
func _on_distinction_made(quality: StringName, _position: Vector2) -> void:
  if current_state == State.QUESTION or current_state == State.DISTINCTION:
    Events.boundary_formed.emit(null)
    transition_to(State.BOUNDARY)

func _on_consequence_dismissed() -> void:
  if current_state == State.BOUNDARY:
    # Flow tracking:
    # 1. After distinction: -> CONTEXT
    # 2. After scope: -> EVIDENCE
    # 3. After evidence: -> GUARD_CHECK
    # 4. After guard pass: -> QUESTION (next cycle)
    # 5. After guard block: -> RESIDUAL
    # 6. After residual: -> QUESTION (cycle complete)
    
    if _evidence_count > 0 and not _guard_evaluated:
      # After evidence, go to guard
      transition_to(State.GUARD_CHECK)
    elif _guard_evaluated and Events.has_residual():
      # After residual named, cycle complete
      _guard_evaluated = false
      _evidence_count = 0
      _scope_changed_count = 0
      Events.question_shown.emit(FIRST_QUESTION)
      transition_to(State.QUESTION)
    elif _guard_evaluated and not Events.has_residual():
      # Guard passed without needing residual
      _guard_evaluated = false
      _evidence_count = 0
      _scope_changed_count = 0
      Events.question_shown.emit(FIRST_QUESTION)
      transition_to(State.QUESTION)
    elif _scope_changed_count > 0 and _evidence_count == 0:
      # After scope, go to evidence
      transition_to(State.EVIDENCE)
    else:
      # First cycle: after boundary, go to context
      Events.question_shown.emit(NEXT_QUESTION_AFTER_BOUNDARY)
      transition_to(State.CONTEXT)
