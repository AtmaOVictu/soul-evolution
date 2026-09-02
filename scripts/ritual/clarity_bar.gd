# clarity_bar.gd — kappa (Clarity) Metric Display
#
# A vertical bar that fills as kappa (clarity) increases.
# Listens to Events.clarity_changed — fully decoupled.
#
# The bar glows when clarity changes — a brief pulse on each delta.

extends ProgressBar

@export var glow_duration: float = 0.4
@export var glow_intensity: float = 0.3

var _resting_modulate: Color = Color(1, 1, 1, 1)
var _glow_tween: Tween = null

func _ready() -> void:
	Events.clarity_changed.connect(_on_clarity_changed)
	min_value = 0.0
	max_value = 1.0
	value = 0.0
	_resting_modulate = modulate

func _on_clarity_changed(new_value: float, delta: float) -> void:
	# Animate the bar fill
	var fill_tween := create_tween()
	fill_tween.tween_property(self, "value", new_value, 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Glow pulse on the bar
	if _glow_tween:
		_glow_tween.kill()
	
	var glow_color := Color(0.5, 0.6, 0.9, 1.0) if delta > 0 else Color(0.7, 0.5, 0.5, 1.0)
	_glow_tween = create_tween()
	_glow_tween.tween_property(self, "modulate", \
		_resting_modulate + Color(glow_intensity, glow_intensity, glow_intensity, 0.0), \
		glow_duration * 0.5)
	_glow_tween.tween_property(self, "modulate", _resting_modulate, glow_duration * 0.5)