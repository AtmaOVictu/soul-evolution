# ritual_state_machine.gd — Ontomatika Ritual State Machine
#
# CL-033: VOID → PRESENCE → QUESTION
# CL-034: → CONTEXT (Ref frame, scope)
# CL-035: → EVIDENCE (witness)
# CL-036: → GUARD_CHECK (immune system)
# CL-037: → RESIDUAL (name what remains)
# CL-038: → KNOT (failure becomes material)
# CL-039: → WHOLENESS (Ω checks completeness)
# CL-040: → SEAL (irreversible lock)
# CL-041: → MATERIAL (RES Material Cards)
# CL-042: → BRIDGE (Solution Pair Bridge)
# CL-043: → ROUTING (Agent Routing Deck)
#
# ALL 15 STATES IMPLEMENTED. Full Playable Slice Ladder complete.

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
  GUARD_CHECK,
  RESIDUAL,
  KNOT,
  WHOLENESS,
  SEAL,
  MATERIAL,
  BRIDGE,
  ROUTING,
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
  State.GUARD_CHECK: true,
  State.RESIDUAL: true,
  State.KNOT: true,
  State.WHOLENESS: true,
  State.SEAL: true,
  State.MATERIAL: true,
  State.BRIDGE: true,
  State.ROUTING: true,
}

const FIRST_QUESTION := "What is different here?"
const NEXT_QUESTION_AFTER_BOUNDARY := "Where is this true?"
const EVIDENCE_QUESTION := "What have you witnessed?"
const RESIDUAL_QUESTION := "What remains unresolved?"
const SEAL_QUESTION := "Seal this? This cannot be undone."
const ROUTING_QUESTION := "Route material to an agent."

const CONTEXT_TITLE := "Scope defined"
const CONTEXT_BODY := "Meaning holds where the frame encompasses it."
const EVIDENCE_TITLE := "Witnessed"
const EVIDENCE_BODY := "The distinction holds. It will not flicker. ⟡"
const GUARD_PASS_TITLE := "Stable"
const GUARD_PASS_BODY := "The distinction is stable, scoped, witnessed. It may proceed to wholeness."
const GUARD_BLOCK_TITLE := "SEAL blocked"
const GUARD_BLOCK_BODY := "Name what remains unresolved before sealing."
const RESIDUAL_TITLE := "Residual named"
const RESIDUAL_BODY := "ℜ remains. Not every good answer is sealable. Some are valuable because they name what remains."
const KNOT_TITLE := "A Problem Knot forms"
const KNOT_BODY := "It carries what was missing. It remains. Failure has become material."
const WHOLENESS_COMPLETE_TITLE := "Whole"
const WHOLENESS_COMPLETE_BODY := "The pattern is complete. Ω closes. SEAL is available."
const WHOLENESS_INCOMPLETE_TITLE := "Incomplete"
const WHOLENESS_INCOMPLETE_BODY := "The pattern lacks: %s. Ω reveals the gaps."
const SEAL_TITLE := "Sealed"
const SEAL_BODY := "◉ The distinction is permanent. It will not change. It is part of the world now."
const MATERIAL_TITLE := "Material formed"
const MATERIAL_BODY := "Meaning has become material. RES cards carry what you built."
const BRIDGE_TITLE := "Bridge formed"
const BRIDGE_BODY := "∴ The knot loosens. The material addresses what was missing. Repair is not erasure."

var _question_shown: bool = false
var _presence_node: Node2D = null
var _presence_seed_position: Vector2 = Vector2.ZERO
var _ref_region: Node2D = null
var _wholeness_boundary: Node2D = null
var _seal_lock: Node2D = null
var _agent_deck: Control = null
var _scope_changed_count: int = 0
var _evidence_count: int = 0
var _guard_evaluated: bool = false
var _wholeness_evaluated: bool = false
var _seal_completed: bool = false
var _material_created: bool = false
var _bridge_attempted: bool = false
var _routing_done: bool = false

func _ready() -> void:
  Events.ritual_state_changed.connect(_on_state_changed)
  Events.presence_noticed.connect(_on_presence_noticed)
  Events.distinction_made.connect(_on_distinction_made)
  Events.scope_changed.connect(_on_scope_changed)
  Events.evidence_attached.connect(_on_evidence_attached)
  Events.evidence_skipped.connect(_on_evidence_skipped)
  Events.residual_named.connect(_on_residual_named)
  Events.wholeness_evaluated.connect(_on_wholeness_evaluated)
  Events.seal_completed.connect(_on_seal_completed)
  Events.seal_cancelled.connect(_on_seal_cancelled)

func start_ritual() -> void:
  transition_to(State.PRESENCE)

func transition_to(new_state: State) -> void:
  if not _is_implemented.get(new_state, false):
    return
  current_state = new_state
  Events.ritual_state_changed.emit(StringName(State.keys()[new_state].to_lower()))

func _on_state_changed(_state_name: StringName) -> void:
  match current_state:
    State.VOID: pass
    State.PRESENCE: _spawn_presence()
    State.QUESTION: _show_question()
    State.DISTINCTION: pass
    State.BOUNDARY: pass
    State.CONTEXT: _activate_ref_frame()
    State.EVIDENCE: Events.question_shown.emit(EVIDENCE_QUESTION)
    State.GUARD_CHECK: _evaluate_guard()
    State.RESIDUAL: Events.question_shown.emit(RESIDUAL_QUESTION)
    State.KNOT: _create_knot()
    State.WHOLENESS: _evaluate_wholeness()
    State.SEAL: _activate_seal()
    State.MATERIAL: _create_material_cards()
    State.BRIDGE: _activate_bridge()
    State.ROUTING: _activate_routing()

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
  if _presence_node and is_instance_valid(_presence_node):
    _presence_node.deactivate()
  await get_tree().create_timer(1.2).timeout
  transition_to(State.QUESTION)

# ── CL-034: Question / Distinction ──
func _show_question() -> void:
  if _question_shown:
    return
  Events.question_shown.emit(FIRST_QUESTION)
  _question_shown = true

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
  Events.ref_activated.emit(_ref_region.get_rect())

func _on_scope_changed(in_scope: Array, out_of_scope: Array) -> void:
  _scope_changed_count += 1
  for d in in_scope:
    d.set_scoped(true)
  for d in out_of_scope:
    d.set_scoped(false)
  Events.consequence_shown.emit(CONTEXT_TITLE, CONTEXT_BODY,
    "κ | Scoped: %d/%d" % [Events.get_scoped_count(), Events.get_distinction_count()],
    "%.2f (context defined)" % Events.get_aggregate_clarity())
  transition_to(State.BOUNDARY)

# ── CL-035: Evidence ──
func _on_evidence_attached(node: Node2D) -> void:
  _evidence_count += 1
  Events.consequence_shown.emit(EVIDENCE_TITLE, EVIDENCE_BODY,
    "κ | Witnessed: %d/%d" % [_evidence_count, Events.get_distinction_count()],
    "%.2f (witnessed)" % Events.get_aggregate_clarity())
  transition_to(State.BOUNDARY)

func _on_evidence_skipped() -> void:
  Events.consequence_shown.emit("Unwitnessed",
    "What remains unheld will flicker. The field remembers.",
    "κ | Witnessed: 0/%d" % Events.get_distinction_count(),
    "What remains unheld?")
  transition_to(State.BOUNDARY)

# ── CL-036: Guard Check ──
func _evaluate_guard() -> void:
  _guard_evaluated = true
  var has_residual := Events.has_residual()
  var result := GuardCheck.check_seal_eligibility(has_residual)
  Events.guard_result.emit(result)
  if result["can_seal"]:
    Events.consequence_shown.emit(GUARD_PASS_TITLE, GUARD_PASS_BODY,
      "κ | Guard: stable", "%.2f (ready)" % Events.get_aggregate_clarity())
    transition_to(State.BOUNDARY)
  else:
    Events.consequence_shown.emit(GUARD_BLOCK_TITLE, GUARD_BLOCK_BODY,
      "κ | Guard: %s" % result["reason"], "What remains?")
    transition_to(State.RESIDUAL)

# ── CL-037: Residual ──
func _on_residual_named(name: String) -> void:
  if current_state != State.RESIDUAL: return
  Events.set_residual_name(name)
  var ResidualScript = preload("res://scripts/ritual/residual_seed.gd")
  var seed := Node2D.new()
  seed.set_script(ResidualScript)
  seed.setup(name)
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

# ── CL-038: Problem Knot ──
func _create_knot() -> void:
  var result := GuardCheck.evaluate()
  var missing := []
  if not result["has_scoped"]: missing.append("scope")
  if not result["has_witnessed"]: missing.append("witness")
  if not Events.has_residual(): missing.append("residual")
  var desc := "This answer lacks " + ", ".join(missing) + "." if missing.size() > 0 else "This answer is unresolved."
  var KnotScript = preload("res://scripts/ritual/problem_knot.gd")
  var knot := Node2D.new()
  knot.set_script(KnotScript)
  knot.setup(desc, not result["has_scoped"], not result["has_witnessed"], not Events.has_residual())
  var viewport_size := get_viewport().get_visible_rect().size
  knot.position = Vector2(viewport_size.x * 0.15 + randf() * 40, viewport_size.y * 0.75 + randf() * 30)
  var layer := get_parent().get_node_or_null("DistinctionLayer")
  if layer: layer.add_child(knot)
  else: get_parent().add_child(knot)
  Events.register_knot(knot)
  Events.knot_created.emit(knot, desc)
  Events.consequence_shown.emit(KNOT_TITLE, KNOT_BODY,
    "⊗ | Missing: %s" % (", ".join(missing) if missing.size() > 0 else "none"),
    "%.2f (knot persists)" % Events.get_aggregate_clarity())
  transition_to(State.BOUNDARY)

# ── CL-039: Wholeness ──
func _evaluate_wholeness() -> void:
  _wholeness_evaluated = true
  if not _wholeness_boundary or not is_instance_valid(_wholeness_boundary):
    var OmegaScript = preload("res://scripts/ritual/wholeness_boundary.gd")
    _wholeness_boundary = Node2D.new()
    _wholeness_boundary.set_script(OmegaScript)
    var layer := get_parent().get_node_or_null("DistinctionLayer")
    if layer: layer.add_child(_wholeness_boundary)
    else: get_parent().add_child(_wholeness_boundary)
  _wholeness_boundary.activate()
  await get_tree().create_timer(1.5).timeout
  var omega := _wholeness_boundary
  var is_complete: bool = omega.is_complete()
  var missing: Array = omega.get_missing()
  # FIX: deactivate the boundary after evaluation so it doesn't persist visually
  omega.deactivate()
  if is_complete:
    Events.consequence_shown.emit(WHOLENESS_COMPLETE_TITLE, WHOLENESS_COMPLETE_BODY,
      "Ω | Complete", "%.2f (whole)" % Events.get_aggregate_clarity())
    Events.seal_available.emit()
    transition_to(State.BOUNDARY)
  else:
    Events.consequence_shown.emit(WHOLENESS_INCOMPLETE_TITLE,
      WHOLENESS_INCOMPLETE_BODY % ", ".join(missing),
      "Ω | Missing: %s" % ", ".join(missing), "%.2f (incomplete)" % Events.get_aggregate_clarity())
    transition_to(State.BOUNDARY)

func _on_wholeness_evaluated(_complete: bool, _missing: Array) -> void:
  pass

# ── CL-040: SEAL ──
func _activate_seal() -> void:
  if not _seal_lock or not is_instance_valid(_seal_lock):
    var SealScript = preload("res://scripts/ritual/seal_lock.gd")
    _seal_lock = Node2D.new()
    _seal_lock.set_script(SealScript)
    _seal_lock.position = get_viewport().get_visible_rect().size / 2
    var layer := get_parent().get_node_or_null("DistinctionLayer")
    if layer: layer.add_child(_seal_lock)
    else: get_parent().add_child(_seal_lock)
  _seal_lock.activate()
  Events.question_shown.emit(SEAL_QUESTION)
  await get_tree().create_timer(2.0).timeout
  if current_state == State.SEAL:
    _seal_lock.begin_seal()

func _on_seal_completed(distinctions: Array) -> void:
  if current_state != State.SEAL: return
  _seal_completed = true
  var sealed_count := distinctions.size()
  Events.consequence_shown.emit(SEAL_TITLE, SEAL_BODY,
    "◉ | Sealed: %d" % sealed_count, "%.2f (permanent)" % Events.get_aggregate_clarity())
  if _seal_lock and is_instance_valid(_seal_lock):
    _seal_lock.deactivate()
  transition_to(State.BOUNDARY)

func _on_seal_cancelled() -> void:
  if current_state != State.SEAL: return
  if _seal_lock and is_instance_valid(_seal_lock):
    _seal_lock.deactivate()
  transition_to(State.BOUNDARY)

# ── CL-041: RES Material Cards ──
func _create_material_cards() -> void:
  _material_created = true
  var distinctions := Events.get_all_distinctions()
  var layer := get_parent().get_node_or_null("DistinctionLayer")
  var card_count := 0
  for d in distinctions:
    if not is_instance_valid(d) or not d.is_sealed:
      continue
    var RESScript = preload("res://scripts/ritual/res_material_card.gd")
    var card := Node2D.new()
    card.set_script(RESScript)
    card.setup(
      Events.get_residual_name(),
      d.local_clarity,
      String(d.quality),
      Events.get_residual_name()
    )
    var viewport_size := get_viewport().get_visible_rect().size
    card.position = Vector2(
      viewport_size.x * 0.2 + card_count * 100,
      viewport_size.y * 0.85
    )
    if layer: layer.add_child(card)
    else: get_parent().add_child(card)
    Events.register_res_card(card)
    Events.res_card_created.emit(card, {
      "name": Events.get_residual_name(),
      "clarity": d.local_clarity,
      "quality": String(d.quality)
    })
    card_count += 1
  Events.consequence_shown.emit(MATERIAL_TITLE, MATERIAL_BODY,
    "RES | Cards: %d" % card_count, "%.2f (%d material)" % [Events.get_aggregate_clarity(), card_count])
  transition_to(State.BOUNDARY)

# ── CL-042: Solution Pair Bridge ──
func _activate_bridge() -> void:
  _bridge_attempted = true
  var knots := Events.get_all_knots()
  var cards := Events.get_all_res_cards()
  if knots.is_empty() or cards.is_empty():
    Events.consequence_shown.emit("No bridge possible",
      "Bridging requires both a Problem Knot and a RES Material Card.",
      "∴ | Knots: %d, Cards: %d" % [knots.size(), cards.size()], "Need both")
    transition_to(State.BOUNDARY)
    return
  var knot := knots[0]
  var card := cards[0]
  if is_instance_valid(knot) and is_instance_valid(card):
    var BridgeScript = preload("res://scripts/ritual/solution_pair_bridge.gd")
    var bridge := Node2D.new()
    bridge.set_script(BridgeScript)
    bridge.position = Vector2.ZERO
    var layer := get_parent().get_node_or_null("DistinctionLayer")
    if layer: layer.add_child(bridge)
    else: get_parent().add_child(bridge)
    bridge.setup(knot, card)
    Events.register_bridge(bridge)
    await get_tree().create_timer(1.0).timeout
    Events.consequence_shown.emit(BRIDGE_TITLE, BRIDGE_BODY,
      "∴ | Bridge: 1", "%.2f (repaired)" % Events.get_aggregate_clarity())
  transition_to(State.BOUNDARY)

# ── CL-043: Agent Routing ──
func _activate_routing() -> void:
  _routing_done = true
  if not _agent_deck or not is_instance_valid(_agent_deck):
    var DeckScript = preload("res://scripts/ritual/agent_routing_deck.gd")
    _agent_deck = Control.new()
    _agent_deck.set_script(DeckScript)
    _agent_deck.anchors_preset = Control.PRESET_FULL_RECT
    _agent_deck.offset_top = get_viewport().get_visible_rect().size.y - 120
    _agent_deck.offset_bottom = 0
    get_parent().add_child(_agent_deck)
  _agent_deck.activate()
  Events.question_shown.emit(ROUTING_QUESTION)
  await get_tree().create_timer(5.0).timeout
  if current_state == State.ROUTING:
    Events.consequence_shown.emit("Routing complete",
      "Agents have processed the material. The cycle is done.",
      "κ | Agents ready", "%.2f (routed)" % Events.get_aggregate_clarity())
    _agent_deck.deactivate()
    transition_to(State.BOUNDARY)

# ── Distinction / Consequence handlers ──
func _on_distinction_made(quality: StringName, _position: Vector2) -> void:
  if current_state == State.QUESTION or current_state == State.DISTINCTION:
    transition_to(State.DISTINCTION)
    await get_tree().create_timer(0.5).timeout
    transition_to(State.BOUNDARY)

func _on_consequence_dismissed() -> void:
  if current_state == State.BOUNDARY:
    # Flow:
    # 1. After distinction → CONTEXT
    # 2. After scope → EVIDENCE
    # 3. After evidence → GUARD_CHECK
    # 4a. Guard pass (with residual) → WHOLENESS
    # 4b. Guard block → RESIDUAL
    # 5. After residual → BOUNDARY → (guard re-eval) → WHOLENESS
    # If residual skipped → KNOT → BOUNDARY → QUESTION
    # 6. Wholeness complete → SEAL
    # 6b. Wholeness incomplete → QUESTION (new cycle)
    # 7. After seal → MATERIAL
    # 8. After material → BRIDGE
    # 9. After bridge → ROUTING
    # 10. After routing → QUESTION (new cycle)
    
    if _routing_done:
      _routing_done = false
      _reset_cycle()
    elif _bridge_attempted:
      _bridge_attempted = false
      transition_to(State.ROUTING)
    elif _material_created:
      _material_created = false
      transition_to(State.BRIDGE)
    elif _seal_completed:
      _seal_completed = false
      transition_to(State.MATERIAL)
    elif _wholeness_evaluated:
      var omega := _wholeness_boundary
      if omega and is_instance_valid(omega) and omega.is_complete():
        _wholeness_evaluated = false
        transition_to(State.SEAL)
      else:
        _wholeness_evaluated = false
        _reset_cycle()
    elif _guard_evaluated and not Events.has_residual():
      _guard_evaluated = false
      _evidence_count = 0
      _scope_changed_count = 0
      transition_to(State.KNOT)
    elif _evidence_count > 0 and not _guard_evaluated:
      transition_to(State.GUARD_CHECK)
    elif _guard_evaluated and Events.has_residual():
      _guard_evaluated = false
      transition_to(State.WHOLENESS)
    elif _scope_changed_count > 0 and _evidence_count == 0:
      transition_to(State.EVIDENCE)
    else:
      Events.question_shown.emit(NEXT_QUESTION_AFTER_BOUNDARY)
      transition_to(State.CONTEXT)

func _reset_cycle() -> void:
  _evidence_count = 0
  _scope_changed_count = 0
  _guard_evaluated = false
  _wholeness_evaluated = false
  Events.question_shown.emit(FIRST_QUESTION)
  transition_to(State.QUESTION)