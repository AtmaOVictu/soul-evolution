# ref_region.gd — Ref Context Frame
#
# A spatial region where distinctions are scoped (hold, are stable).
# Distinctions outside the frame are unscoped (flicker, fade, lose coherence).
#
# This is the first spatial differentiation: the world gains inside/outside.
# The player draws or moves the frame to answer "Where is this true?"

extends Node2D

var frame_rect: Rect2 = Rect2(0, 0, 400, 300)
var is_active: bool = false
var is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _breath_time: float = 0.0

signal ref_activated(region: Node2D)
signal ref_moved(region: Node2D)
signal ref_resized(region: Node2D)

func _draw() -> void:
	if not is_active:
		return
	
	var rect := frame_rect
	
	# Frame border — subtle, breathing
	var breath := sin(_breath_time * 0.8) * 0.05
	var border_color := Color(0.4, 0.5, 0.7, 0.3 + breath)
	draw_rect(rect, border_color, false, 1.5)
	
	# Inner glow — distinctions inside are brighter
	var inner_color := Color(0.3, 0.4, 0.6, 0.03 + breath * 0.5)
	draw_rect(rect, inner_color, true)
	
	# Corner marks — the frame is a question, not a wall
	var corner_len := 12.0
	var corners := [
		rect.position,
		rect.position + Vector2(rect.size.x, 0),
		rect.position + Vector2(0, rect.size.y),
		rect.position + rect.size,
	]
	for corner in corners:
		draw_circle(corner, 3.0, Color(0.5, 0.6, 0.8, 0.6))

func _process(delta: float) -> void:
	if is_active:
		_breath_time += delta
		queue_redraw()

func activate(center_pos: Vector2) -> void:
	frame_rect = Rect2(center_pos - Vector2(200, 150), Vector2(400, 300))
	is_active = true
	ref_activated.emit(self)
	Events.ref_activated.emit(frame_rect)

func contains(point: Vector2) -> bool:
	return frame_rect.has_point(point)

func update_distinction_scope(distinction: Node2D) -> void:
	if not is_active:
		return
	var was_scoped := distinction.is_scoped
	var now_scoped := contains(distinction.position)
	if was_scoped != now_scoped:
		distinction.set_scoped(now_scoped)

func _input(event: InputEvent) -> void:
	if not is_active:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if frame_rect.has_point(event.position):
			is_dragging = true
			_drag_offset = event.position - frame_rect.position
	elif event is InputEventMouseButton and not event.pressed:
		is_dragging = false
	elif event is InputEventMouseMotion and is_dragging:
		frame_rect.position = event.position - _drag_offset
		ref_moved.emit(self)
		Events.ref_moved.emit(frame_rect)