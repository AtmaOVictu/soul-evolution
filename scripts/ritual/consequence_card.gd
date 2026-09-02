# consequence_card.gd — Consequence Card Panel
#
# Slides in from the right when a distinction is made.
# Shows: title, body text, and a metric (kappa value).
# Player clicks or presses Space to dismiss -> Events.consequence_dismissed
#
# Vocabulary: never uses "correct" or "wrong".
# Uses: "stable", "witnessed", "scoped", "responsible".

extends Panel

@onready var title_label: Label = %TitleLabel
@onready var body_label: Label = %BodyLabel
@onready var metric_label: Label = %MetricLabel
@onready var metric_value: Label = %MetricValue
@onready var dismiss_hint: Label = %DismissHint

@export var slide_distance: float = 300.0
@export var slide_duration: float = 0.5
@export var auto_dismiss_delay: float = 4.0

var _is_showing: bool = false
var _resting_x: float = 0.0

func _ready() -> void:
	Events.consequence_shown.connect(_on_consequence_shown)
	_resting_x = position.x
	position.x = _resting_x + slide_distance
	modulate.a = 0.0
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if _is_showing and event is InputEventMouseButton and event.pressed:
		dismiss()
	elif _is_showing and event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		dismiss()

func _unhandled_input(event: InputEvent) -> void:
	if _is_showing and event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		dismiss()

func _on_consequence_shown(title: String, body: String, m_label: String, m_value: String) -> void:
	title_label.text = title
	body_label.text = body
	metric_label.text = m_label
	metric_value.text = m_value
	dismiss_hint.text = "[ click or Space to continue ]"
	
	_is_showing = true
	visible = true
	
	# Slide in + fade in
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:x", _resting_x, slide_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, slide_duration * 0.7)
	
	# Auto-dismiss timer
	get_tree().create_timer(auto_dismiss_delay).timeout.connect(dismiss)

func dismiss() -> void:
	if not _is_showing:
		return
	_is_showing = false
	
	# Slide out + fade out
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:x", _resting_x + slide_distance, slide_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, slide_duration * 0.7)
	tween.chain().tween_callback(func():
		visible = false
		Events.consequence_dismissed.emit()
	)