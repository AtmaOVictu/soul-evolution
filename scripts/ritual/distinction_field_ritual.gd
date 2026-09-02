# distinction_field_ritual.gd — Ritual Distinction Field (REFACTORED)
#
# No longer creates flat ColorRect markers. Creates DistinctionNodes —
# living objects with their own clarity, visual state, and reactivity.
#
# Two distinction qualities:
#   CUT     — first click: a single distinction appears (κ_local 0.05→0.15)
#   BOUNDED — second click: second distinction + boundary auto-spawns between them

extends Control

const DistinctionNode = preload("res://scripts/ritual/distinction_node.gd")
const BoundaryNode = preload("res://scripts/ritual/boundary_node.gd")

const QUALITY_CUT := &"CUT"
const QUALITY_BOUNDED := &"BOUNDED"

@export var clarity_per_cut: float = 0.10
@export var clarity_per_bounded: float = 0.15
@export var pair_bonus: float = 0.05

var _click_count: int = 0
var _first_node: Node2D = null
var _input_enabled: bool = false
var _all_distinctions: Array[Node2D] = []
var _all_boundaries: Array[Line2D] = []

func _ready() -> void:
	Events.ritual_state_changed.connect(_on_state_changed)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _on_state_changed(state_name: StringName) -> void:
	_input_enabled = (state_name == &"QUESTION")

func _gui_input(event: InputEvent) -> void:
	if not _input_enabled:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_field_click(event.position)

func _on_field_click(pos: Vector2) -> void:
	_click_count += 1
	
	if _click_count == 1:
		# First click — spawn a distinction with CUT quality
		_first_node = _spawn_distinction(pos, QUALITY_CUT)
		_first_node.gain_clarity(clarity_per_cut)
		_emit_distinction(QUALITY_CUT, pos)
	
	elif _click_count == 2:
		# Second click — spawn distinction + boundary
		var second_node := _spawn_distinction(pos, QUALITY_BOUNDED)
		second_node.gain_clarity(clarity_per_bounded)
		
		# The world creates the boundary — not the player
		if _first_node:
			_spawn_boundary(_first_node, second_node)
			# Both endpoints gain the pair bonus
			_first_node.gain_clarity(pair_bonus)
			second_node.gain_clarity(pair_bonus)
		
		_emit_distinction(QUALITY_BOUNDED, pos)
		
		# Reset cycle
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
	
	# Spawn animation — scale from nothing
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
	
	# Consequence card content
	var agg_kappa := Events.get_aggregate_clarity()
	var count := Events.get_distinction_count()
	
	var title := "A distinction was made" if quality == QUALITY_CUT else "A boundary exists"
	var body := "You cut the field. Something is now separate." if quality == QUALITY_CUT \
		else "A boundary exists between two distinctions. The world has related them."
	var stage := "ONE" if quality == QUALITY_CUT else "POLARITY"
	var metric_text := "%.2f (%d distinctions)" % [agg_kappa, count]
	
	Events.consequence_shown.emit(title, body, "kappa | Stage: %s" % stage, metric_text)

func clear_all() -> void:
	for d in _all_distinctions:
		if is_instance_valid(d):
			d.queue_free()
	for b in _all_boundaries:
		if is_instance_valid(b):
			b.queue_free()
	_all_distinctions.clear()
	_all_boundaries.clear()
	_click_count = 0
	_first_node = null