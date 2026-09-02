# question_prompt.gd — Ritual Question Display
#
# Displays the ritual question text with a typewriter reveal effect.
# Listens to Events.question_shown — fully decoupled from the state machine.
#
# The question breathes: a subtle sine-wave alpha modulation while visible.

extends RichTextLabel

@export var typewriter_speed: float = 25.0  # characters per second
@export var fade_in_duration: float = 0.6
@export var breath_depth: float = 0.08      # alpha oscillation amplitude
@export var breath_speed: float = 0.4       # breaths per second

var _is_revealing: bool = false
var _total_chars: int = 0
var _breath_time: float = 0.0

func _ready() -> void:
	Events.question_shown.connect(_on_question_shown)
	visible_characters = 0
	modulate.a = 0.0
	# Ritual text styling
	bbcode_enabled = true
	fit_content = true
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _process(delta: float) -> void:
	if _is_revealing:
		visible_characters = int(minf(visible_characters + typewriter_speed * delta, float(_total_chars)))
		if visible_characters >= _total_chars:
			_is_revealing = false
	
	# Breathing effect when fully visible
	if not _is_revealing and modulate.a > 0.9:
		_breath_time += delta
		var breath := sin(_breath_time * breath_speed * TAU) * breath_depth
		modulate.a = 1.0 + breath

func _on_question_shown(text: String) -> void:
	# Format as ritual text — subtle, weighted, not decorative
	var formatted := "[color=#a0a8c8][i]" + text + "[/i][/color]"
	text = formatted
	_total_chars = get_total_character_count()
	visible_characters = 0
	
	# Fade in
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_in_duration)
	tween.tween_callback(func(): _is_revealing = true)