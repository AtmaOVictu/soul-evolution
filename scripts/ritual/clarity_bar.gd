# clarity_bar.gd — Aggregate Clarity Display (REFACTORED)
#
# No longer reads a single global float. Reads the AGGREGATE of all
# distinction clarities. The bar reacts to any individual distinction
# changing — because the aggregate shifts when any part shifts.
#
# Also shows distinction count — the world is not just clearer, it is fuller.

extends ProgressBar

@export var glow_duration: float = 0.4
@export var glow_intensity: float = 0.3

@onready var count_label: Label = get_node_or_null("ClarityLabel")

var _resting_modulate: Color = Color(1, 1, 1, 1)
var _glow_tween: Tween = null

func _ready() -> void:
	Events.local_clarity_changed.connect(_on_any_clarity_changed)
	Events.distinction_spawned.connect(_on_distinction_spawned)
	min_value = 0.0
	max_value = 1.0
	value = 0.0
	_resting_modulate = modulate
	_update_display()

func _on_any_clarity_changed(_node: Node, _new_value: float, delta: float) -> void:
	_update_display(delta)

func _on_distinction_spawned(_node: Node2D) -> void:
	_update_display(0.05)  # small pulse on new distinction

func _update_display(delta: float = 0.0) -> void:
	var agg := Events.get_aggregate_clarity()
	var count := Events.get_distinction_count()
	
	# Animate the bar fill
	var fill_tween := create_tween()
	fill_tween.tween_property(self, "value", agg, 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Update label with count
	if count_label:
		count_label.text = "kappa %.2f | %d" % [agg, count]
	
	# Glow pulse
	if delta != 0.0 and _glow_tween:
		_glow_tween.kill()
		var warm := delta > 0
		_glow_tween = create_tween()
		_glow_tween.tween_property(self, "modulate",
			_resting_modulate + Color(glow_intensity, glow_intensity, glow_intensity, 0.0),
			glow_duration * 0.5)
		_glow_tween.tween_property(self, "modulate", _resting_modulate, glow_duration * 0.5)