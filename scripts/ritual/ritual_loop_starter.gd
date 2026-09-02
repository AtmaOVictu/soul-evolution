# ritual_loop_starter.gd — Scene root script
# Attaches to the RitualLoop root node in ritual_loop.tscn.
# Waits briefly for the void to settle, then starts the ritual.

extends Control

@export var start_delay: float = 0.8

func _ready() -> void:
	# Let the void breathing shader settle before beginning
	await get_tree().create_timer(start_delay).timeout
	$StateMachine.start_ritual()