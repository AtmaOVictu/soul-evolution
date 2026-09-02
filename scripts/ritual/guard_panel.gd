# guard_panel.gd — Visual panel showing Guard evaluation
#
# CL-036: A panel that slides in from the left, showing check results.
# Each check has a badge: ✓ (green) or ✗ (amber).
# The panel does not say "correct" or "wrong" — it says "stable" or "unscoped".
#
# When SEAL is blocked, the panel shows why and transitions to RESIDUAL.

extends Panel

@onready var _title_label: Label = $VBox/TitleLabel
@onready var _check_distinction: Label = $VBox/CheckDistinction
@onready var _check_context: Label = $VBox/CheckContext
@onready var _check_evidence: Label = $VBox/CheckEvidence
@onready var _check_residual: Label = $VBox/CheckResidual
@onready var _result_label: Label = $VBox/ResultLabel
@onready var _hint_label: Label = $VBox/HintLabel

const GuardCheck = preload("res://scripts/ritual/guard_check.gd")

var _is_visible: bool = false

func _ready() -> void:
  visible = false
  modulate.a = 0.0

func show_guard(has_residual: bool = false) -> void:
  var result := GuardCheck.evaluate()
  var seal_check := GuardCheck.check_seal_eligibility(has_residual)
  
  # Update labels
  _title_label.text = "GUARD"
  
  # Check badges
  _check_distinction.text = "[color=%s]%s[/color] distinction exists" % [
    "green" if result["has_distinction"] else "amber",
    "✓" if result["has_distinction"] else "✗"
  ]
  _check_context.text = "[color=%s]%s[/color] context scoped" % [
    "green" if result["has_scoped"] else "amber",
    "✓" if result["has_scoped"] else "✗"
  ]
  _check_evidence.text = "[color=%s]%s[/color] evidence witnessed" % [
    "green" if result["has_witnessed"] else "amber",
    "✓" if result["has_witnessed"] else "✗"
  ]
  _check_residual.text = "[color=%s]%s[/color] residual named" % [
    "green" if has_residual else "amber",
    "✓" if has_residual else "✗"
  ]
  
  _check_distinction.bbcode_enabled = true
  _check_context.bbcode_enabled = true
  _check_evidence.bbcode_enabled = true
  _check_residual.bbcode_enabled = true
  
  # Result
  if seal_check["can_seal"]:
    _result_label.text = "[color=green]SEAL available[/color]"
    _hint_label.text = "The distinction is stable, scoped, witnessed. It may be sealed."
  elif result["result"] == GuardCheck.Result.RESIDUAL_UNNAMED:
    _result_label.text = "[color=orange]SEAL blocked[/color]"
    _hint_label.text = "Name what remains unresolved before sealing."
  else:
    _result_label.text = "[color=orange]%s[/color]" % seal_check["reason"]
    _hint_label.text = "The distinction is not yet ready to hold permanently."
  
  _result_label.bbcode_enabled = true
  
  # Slide in
  visible = true
  _is_visible = true
  var tween := create_tween()
  modulate.a = 0.0
  tween.tween_property(self, "modulate:a", 1.0, 0.4)
  tween.set_trans(Tween.TRANS_SINE)
  tween.set_ease(Tween.EASE_IN_OUT)

func hide_guard() -> void:
  _is_visible = false
  var tween := create_tween()
  tween.tween_property(self, "modulate:a", 0.0, 0.3)
  tween.tween_callback(func(): visible = false)
