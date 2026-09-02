# distinction_field_ritual.gd — Ritual Distinction Field (CL-037)
#
# PRESENCE: clicks check for presence node
# QUESTION: clicks create distinctions
# CONTEXT: clicks pass through to Ref frame
# EVIDENCE: clicks on distinctions attach ⟡
# GUARD_CHECK: no field interaction (guard panel handles it)
# RESIDUAL: no field interaction (residual input handles it)

extends Control

const DistinctionNode = preload("res://scripts/ritual/distinction_node.gd")
const BoundaryNode = preload("res://scripts/ritual/boundary_node.gd")
const PresenceNode = preload("res://scripts/ritual/presence_node.gd")
const EvidenceSpark = preload("res://scripts/ritual/evidence_spark.gd")

const QUALITY_CUT := &"CUT"
const QUALITY_BOUNDED := &"BOUNDED"

@export var clarity_per_cut: float = 0.10
@export var clarity_per_bounded: float = 0.15
@export var pair_bonus: float = 0.05

var _click_count: int = 0
var _first_node: Node2D = null
var _input_enabled: bool = false
var _presence_input_enabled: bool = false
var _evidence_input_enabled: bool = false
var _all_distinctions: Array[Node2D] = []
var _all_boundaries: Array[Line2D] = []
var _all_evidence_sparks: Array[Node2D] = []

func _ready() -> void:
  Events.ritual_state_changed.connect(_on_state_changed)
  mouse_filter = Control.MOUSE_FILTER_STOP

func _on_state_changed(state_name: StringName) -> void:
  _input_enabled = (state_name == &"QUESTION")
  _presence_input_enabled = (state_name == &"PRESENCE")
  _evidence_input_enabled = (state_name == &"EVIDENCE")

func _gui_input(event: InputEvent) -> void:
  if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
    if _presence_input_enabled:
      _on_presence_click(event.position)
    elif _input_enabled:
      _on_field_click(event.position)
    elif _evidence_input_enabled:
      _on_evidence_click(event.position)

func _on_presence_click(pos: Vector2) -> void:
  var layer := get_parent().get_node_or_null("DistinctionLayer")
  if not layer: return
  for child in layer.get_children():
    if child.get_script() == PresenceNode:
      if child.has_method("try_notice"):
        if child.try_notice(pos): return
  _void_flicker(pos)

func _void_flicker(pos: Vector2) -> void:
  var flicker := ColorRect.new()
  flicker.size = Vector2(4, 4)
  flicker.position = pos - Vector2(2, 2)
  flicker.color = Color(0.3, 0.4, 0.6, 0.3)
  add_child(flicker)
  var tween := create_tween()
  tween.tween_property(flicker, "color:a", 0.0, 0.3)
  tween.tween_callback(flicker.queue_free)

func _on_evidence_click(pos: Vector2) -> void:
  var layer := get_parent().get_node_or_null("DistinctionLayer")
  if not layer: return
  for child in layer.get_children():
    if child.get_script() == DistinctionNode:
      var d := child as Node2D
      if d.is_sealed or d.is_witnessed: continue
      if pos.distance_to(d.position) < 30.0:
        _witness_distinction(d)
        return
  Events.evidence_skipped.emit()

func _witness_distinction(d: Node2D) -> void:
  d.set_witnessed()
  var spark := Node2D.new()
  spark.set_script(EvidenceSpark)
  spark.position = d.position + Vector2(12, -12)
  var layer := get_parent().get_node_or_null("DistinctionLayer")
  if layer: layer.add_child(spark)
  else: add_child(spark)
  _all_evidence_sparks.append(spark)
  Events.evidence_attached.emit(d)

func _on_field_click(pos: Vector2) -> void:
  _click_count += 1
  if _click_count == 1:
    _first_node = _spawn_distinction(pos, QUALITY_CUT)
    _first_node.gain_clarity(clarity_per_cut)
    _emit_distinction(QUALITY_CUT, pos)
  elif _click_count == 2:
    var second_node := _spawn_distinction(pos, QUALITY_BOUNDED)
    second_node.gain_clarity(clarity_per_bounded)
    if _first_node:
      _spawn_boundary(_first_node, second_node)
      _first_node.gain_clarity(pair_bonus)
      second_node.gain_clarity(pair_bonus)
    _emit_distinction(QUALITY_BOUNDED, pos)
    _click_count = 0
    _first_node = null

func _spawn_distinction(pos: Vector2, quality: StringName) -> Node2D:
  var node := Node2D.new()
  node.set_script(DistinctionNode)
  node.position = pos
  node.quality = quality
  add_child(node)
  _all_distinctions.append(node)
  Events.register_distinction(node)
  var tween := create_tween()
  node.scale = Vector2(0.01, 0.01)
  tween.tween_property(node, "scale", Vector2(1.0, 1.0), 0.3)
  tween.set_trans(Tween.TRANS_BACK)
  tween.set_ease(Tween.EASE_OUT)
  return node

func _spawn_boundary(a: Node2D, b: Node2D) -> Line2D:
  var boundary := Line2D.new()
  boundary.set_script(BoundaryNode)
  boundary.add_point(a.position)
  boundary.add_point(b.position)
  add_child(boundary)
  boundary.setup(a, b)
  _all_boundaries.append(boundary)
  Events.boundary_formed.emit(boundary)
  return boundary

func _emit_distinction(quality: StringName, pos: Vector2) -> void:
  Events.distinction_made.emit(quality, pos)
  var agg_kappa := Events.get_aggregate_clarity()
  var count := Events.get_distinction_count()
  var title := "A distinction was made" if quality == QUALITY_CUT else "A boundary exists"
  var body := "You cut the field. Something is now separate." if quality == QUALITY_CUT \
    else "A boundary exists between two distinctions. The world has related them."
  var stage := "ONE" if quality == QUALITY_CUT else "POLARITY"
  var metric_text := "%.2f (%d distinctions)" % [agg_kappa, count]
  Events.consequence_shown.emit(title, body, "κ | Stage: %s" % stage, metric_text)

func clear_all() -> void:
  for d in _all_distinctions:
    if is_instance_valid(d): d.queue_free()
  for b in _all_boundaries:
    if is_instance_valid(b): b.queue_free()
  for s in _all_evidence_sparks:
    if is_instance_valid(s): s.queue_free()
  _all_distinctions.clear()
  _all_boundaries.clear()
  _all_evidence_sparks.clear()
  _click_count = 0
  _first_node = null
