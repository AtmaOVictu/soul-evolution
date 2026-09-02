# residual_input.gd — Text input for naming the residual (ℜ)
#
# CL-037: When Guard blocks SEAL, the player types what remains unresolved.
# This is a simple LineEdit + submit button. The player types a name,
# presses Enter, and the residual is born.
#
# The input appears in the center-bottom of the screen, with the question
# "What remains unresolved?" above it.

extends Control

@onready var _line_edit: LineEdit = $LineEdit
@onready var _submit_button: Button = $SubmitButton
@onready var _hint_label: Label = $HintLabel

var _is_active: bool = false

func _ready() -> void:
  visible = false
  _submit_button.pressed.connect(_on_submit)
  _line_edit.text_submitted.connect(func(_t): _on_submit())

func activate() -> void:
  _is_active = = true
  visible = true
  _line_edit.text = ""
  _line_edit.grab_focus()
  
  modulate.a = 0.0
  var tween := create_tween()
  tween.tween_property(self, "modulate:a", 1.0, 0.3)

func deactivate() -> void:
  _is_active = false
  var tween := create_tween()
  tween.tween_property(self, "modulate:a", 0.0, 0.2)
  tween.tween_callback(func(): visible = false)

func _on_submit() -> void:
  if not _is_active:
    return
  var text := _line_edit.text.strip_edges()
  if text.is_empty():
    _hint_label.text = "Name what remains. Even a single word."
    return
  
  Events.residual_named.emit(text)
  deactivate()

func _input(event: InputEvent) -> void:
  if not _is_active:
    return
  # Allow Escape to skip (with a default name)
  if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
    Events.residual_named.emit("unnamed")
    deactivate()
