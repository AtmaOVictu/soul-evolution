# ref_region.gd — The Ref Context Frame (CL-034)
#
# "Where is this true?" — the player drags this frame to define scope.
# Distinctions inside are SCOPED (stable). Outside are unscoped (flickering).
#
# The Ref frame is the ⊘ (meja) — the boundary that gives meaning its "where".
# Without scope, a distinction is just a mark. With scope, it becomes
# a claim: "this is true HERE."

extends Node2D

@export var frame_size: Vector2 = Vector2(240, 180)
@export var handle_size: float = 12.0
@export var frame_color: Color = Color(0.4, 0.5, 0.8, 0.3)
@export var frame_border_color: Color = Color(0.5, 0.6, 0.9, 0.5)

var _is_active: bool = false
var _is_dragging: bool = false
var _is_resizing: bool = false
var _resize_handle: int = -1
var _drag_offset: Vector2 = Vector2.ZERO
var _breath_time: float = 0.0

const DistinctionNode = preload("res://scripts/ritual/distinction_node.gd")

func _ready() -> void:
  visible = false
  set_process(false)

func activate() -> void:
  _is_active = true
  visible = true
  set_process(true)
  
  modulate.a = 0.0
  var tween := create_tween()
  tween.tween_property(self, "modulate:a", 1.0, 0.5)
  tween.set_trans(Tween.TRANS_SINE)
  tween.set_ease(Tween.EASE_IN_OUT)

func deactivate() -> void:
  _is_active = false
  var tween := create_tween()
  tween.tween_property(self, "modulate:a", 0.0, 0.3)
  tween.tween_callback(func(): visible = false; set_process(false))

func _process(delta: float) -> void:
  _breath_time += delta
  _update_scope()
  queue_redraw()

func _get_frame_rect() -> Rect2:
  return Rect2(position - frame_size / 2, frame_size)

func _update_scope() -> void:
  if not _is_active:
    return
  
  var rect := _get_frame_rect()
  var in_scope: Array = []
  var out_of_scope: Array = []
  var changed: bool = false
  
  var distinctions := Events.get_all_distinctions()
  for d in distinctions:
    if not is_instance_valid(d):
      continue
    var was_scoped := d.is_scoped
    var now_scoped := rect.has_point(d.position)
    
    if now_scoped != was_scoped:
      d.set_scoped(now_scoped)
      if now_scoped:
        d.gain_clarity(0.05)
      changed = true
    
    if now_scoped:
      in_scope.append(d)
    else:
      out_of_scope.append(d)
  
  if changed:
    Events.scope_changed.emit(in_scope, out_of_scope)
    Events.ref_moved.emit(rect)

func _draw() -> void:
  if not _is_active:
    return
  
  var rect := Rect2(-frame_size / 2, frame_size)
  
  var dash_alpha := 0.4 + sin(_breath_time * 0.5) * 0.1
  var border := frame_border_color
  border.a = dash_alpha
  
  _draw_dashed_rect(rect, border, 2.0, 8.0, _breath_time * 0.3)
  
  var handle_color := frame_color
  handle_color.a = 0.6
  var corners := [
    rect.position,
    Vector2(rect.end.x, rect.position.y),
    Vector2(rect.position.x, rect.end.y),
    rect.end,
  ]
  for corner in corners:
    draw_rect(Rect2(corner - Vector2(handle_size / 2, handle_size / 2),
      Vector2(handle_size, handle_size)), handle_color, true)
  
  draw_string(get_theme_default_font(), rect.position + Vector2(4, -4),
    "Ref", 0, -1, 16, Color(0.5, 0.6, 0.9, 0.5))

func _draw_dashed_rect(rect: Rect2, color: Color, width: float, dash_length: float, offset: float) -> void:
  _draw_dashed_line(rect.position, Vector2(rect.end.x, rect.position.y), color, width, dash_length, offset)
  _draw_dashed_line(Vector2(rect.end.x, rect.position.y), rect.end, color, width, dash_length, offset)
  _draw_dashed_line(rect.end, Vector2(rect.position.x, rect.end.y), color, width, dash_length, offset)
  _draw_dashed_line(Vector2(rect.position.x, rect.end.y), rect.position, color, width, dash_length, offset)

func _draw_dashed_line(from: Vector2, to: Vector2, color: Color, width: float, dash_length: float, offset: float) -> void:
  var total_length := from.distance_to(to)
  var dir := (to - from).normalized()
  var pos := fmod(offset, dash_length * 2)
  
  while pos < total_length:
    var dash_start := from + dir * pos
    var dash_end := from + dir * minf(pos + dash_length, total_length)
    draw_line(dash_start, dash_end, color, width)
    pos += dash_length * 2

func _input(event: InputEvent) -> void:
  if not _is_active:
    return
  
  if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
    var local_pos := make_input_local(event).position
    
    if event.pressed:
      var rect := Rect2(-frame_size / 2, frame_size)
      var corners := [
        rect.position,
        Vector2(rect.end.x, rect.position.y),
        Vector2(rect.position.x, rect.end.y),
        rect.end,
      ]
      
      for i in corners.size():
        if local_pos.distance_to(corners[i]) < handle_size:
          _is_resizing = true
          _resize_handle = i
          return
      
      if rect.has_point(local_pos):
        _is_dragging = true
        _drag_offset = local_pos
    else:
      _is_dragging = false
      _is_resizing = false
      _resize_handle = -1
  
  elif event is InputEventMouseMotion:
    var local_pos := make_input_local(event).position
    
    if _is_dragging:
      var delta_pos := local_pos - _drag_offset
      position += delta_pos
      _drag_offset = local_pos
    elif _is_resizing:
      _resize_frame(local_pos, _resize_handle)

func _resize_frame(local_pos: Vector2, handle: int) -> void:
  var center := position
  var half := frame_size / 2
  
  match handle:
    0:
      var new_tl := center - half + local_pos
      frame_size = Vector2(
        maxf(80, (center.x + half.x) - new_tl.x),
        maxf(60, (center.y + half.y) - new_tl.y)
      )
      position = new_tl + frame_size / 2
    1:
      frame_size = Vector2(
        maxf(80, local_pos.x - (center.x - half.x)),
        maxf(60, (center.y + half.y) - local_pos.y)
      )
      position.y = local_pos.y + frame_size.y / 2
    2:
      frame_size = Vector2(
        maxf(80, (center.x + half.x) - local_pos.x),
        maxf(60, local_pos.y - (center.y - half.y))
      )
      position.x = local_pos.x + frame_size.x / 2
    3:
      frame_size = Vector2(
        maxf(80, local_pos.x - (center.x - half.x)),
        maxf(60, local_pos.y - (center.y - half.y))
      )
