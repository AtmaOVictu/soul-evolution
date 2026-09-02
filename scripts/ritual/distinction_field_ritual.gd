# distinction_field_ritual.gd — Ritual Distinction Field
#
# This is the CL-032 interaction layer for the Distinction Field.
# It translates player clicks into ritual distinction_made events.
#
# For CL-032, we implement two distinction qualities:
#   CUT     — player clicks on a single point (a simple distinction)
#   BOUNDED — player clicks two points creating a boundary between them
#
# After each distinction, kappa (clarity) increases and a consequence card appears.
#
# The field is input-enabled only during State.QUESTION (managed by FSM).

extends Control

# ── Distinction qualities ──
const QUALITY_CUT := &"CUT"
const QUALITY_BOUNDED := &"BOUNDED"

# ── Clarity increments per distinction type ──
@export var clarity_per_cut: float = 0.10
@export var clarity_per_bounded: float = 0.15

# ── State ──
var _click_count: int = 0
var _first_click_pos: Vector2 = Vector2.ZERO
var _input_enabled: bool = false
var _markers: Array = []

func _ready() -> void:
	Events.ritual_state_changed.connect(_on_state_changed)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _on_state_changed(state_name: StringName) -> void:
	# Input enabled only during QUESTION state
	_input_enabled = (state_name == &"QUESTION")

func _gui_input(event: InputEvent) -> void:
	if not _input_enabled:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_field_click(event.position)

func _on_field_click(pos: Vector2) -> void:
	_click_count += 1
	
	if _click_count == 1:
		# First click — CUT distinction
		_first_click_pos = pos
		_create_marker(pos, QUALITY_CUT)
		_emit_distinction(QUALITY_CUT, pos, clarity_per_cut)
	elif _click_count == 2:
		# Second click — BOUNDED distinction (boundary between two points)
		_create_marker(pos, QUALITY_BOUNDED)
		_create_boundary_line(_first_click_pos, pos)
		_emit_distinction(QUALITY_BOUNDED, pos, clarity_per_bounded)
		_click_count = 0  # reset for next cycle
		_first_click_pos = Vector2.ZERO

func _emit_distinction(quality: StringName, pos: Vector2, clarity_gain: float) -> void:
	# Update clarity
	var new_clarity := Events.get_clarity() + clarity_gain
	Events.set_clarity(new_clarity)
	
	# Emit the distinction event
	Events.distinction_made.emit(quality, pos)
	
	# Show consequence card
	var title := "A distinction was made" if quality == QUALITY_CUT else "A boundary exists"
	var body := "You cut the field. Something is now separate." if quality == QUALITY_CUT else "A boundary exists between two distinctions."
	var stage := "ONE" if quality == QUALITY_CUT else "POLARITY"
	var metric_text := "%.2f" % new_clarity
	
	Events.consequence_shown.emit(title, body, "kappa | Stage: %s" % stage, metric_text)

func _create_marker(pos: Vector2, _quality: StringName) -> void:
	# Simple visual marker — a small glowing dot
	var marker := ColorRect.new()
	marker.size = Vector2(12, 12)
	marker.position = pos - Vector2(6, 6)
	marker.color = Color(0.4, 0.5, 0.8, 0.8)
	add_child(marker)
	_markers.append(marker)
	
	# Brief scale-in animation
	var tween := create_tween()
	marker.scale = Vector2(0.1, 0.1)
	tween.tween_property(marker, "scale", Vector2(1.0, 1.0), 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _create_boundary_line(from: Vector2, to: Vector2) -> void:
	# Simple line between two distinction points
	var line := Line2D.new()
	line.add_point(from)
	line.add_point(to)
	line.width = 2.0
	line.default_color = Color(0.4, 0.5, 0.8, 0.6)
	add_child(line)
	
	# Animate the line appearing
	var tween := create_tween()
	line.modulate.a = 0.0
	tween.tween_property(line, "modulate:a", 1.0, 0.4)

func clear_markers() -> void:
	for marker in _markers:
		marker.queue_free()
	_markers.clear()
	_click_count = 0