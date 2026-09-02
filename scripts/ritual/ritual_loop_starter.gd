# ritual_loop_starter.gd — Scene root script
# Attaches to the RitualLoop root node in ritual_loop.tscn.
# Waits briefly for the void to settle, then starts the ritual.
#
# CL-033: No change — the starter still calls start_ritual(),
# but start_ritual() now transitions to PRESENCE instead of QUESTION.

extends Control

@export var start_delay: float = 0.8

func _ready() -> void:
  await get_tree().create_timer(start_delay).timeout
  $StateMachine.start_ritual()
