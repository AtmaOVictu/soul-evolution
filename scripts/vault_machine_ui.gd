extends Control
## The Soul Vault gumball machine — the interactive/visual layer.
## Backend (the roll, the odds, the record) lives in scripts/soul_vault.gd;
## this file is only lever pull -> shake -> capsule drop -> reveal. The
## outcome can't be pre-rendered (Blender) because it's decided by the LUCK
## roll at the moment of the pull, not known in advance — same reason the
## souls themselves are a rendered shell (shading) plus a live procedural
## fill (the part that actually changes), not a single baked image.

signal draw_finished

const MACHINE_TOP_Y := -60.0
const CHUTE_Y := 70.0

var _capsule_y: float = 0.0
var _shake: float = 0.0
var _revealed: bool = false
var _quality_col: Color = Color.WHITE
var _playing: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_CENTER_TOP)
	custom_minimum_size = Vector2(160.0, 220.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func play_draw(quality: String) -> void:
	visible = true
	_revealed = false
	_playing = true
	_quality_col = _color_for_quality(quality)
	_capsule_y = MACHINE_TOP_Y
	queue_redraw()

	var tw := create_tween()
	tw.tween_method(_set_shake, 0.0, 1.0, 0.5)
	tw.tween_method(_set_shake, 1.0, 0.0, 0.3)
	tw.tween_method(_set_capsule_y, MACHINE_TOP_Y, CHUTE_Y, 0.6) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(_reveal)
	tw.tween_interval(2.0)
	tw.tween_callback(_hide)


func play_empty() -> void:
	visible = true
	_revealed = false
	_playing = false
	queue_redraw()
	var tw := create_tween()
	tw.tween_method(_set_shake, 0.0, 0.4, 0.15)
	tw.tween_method(_set_shake, 0.4, 0.0, 0.15)
	tw.tween_interval(1.0)
	tw.tween_callback(_hide)


func _set_shake(v: float) -> void:
	_shake = v
	queue_redraw()


func _set_capsule_y(v: float) -> void:
	_capsule_y = v
	queue_redraw()


func _reveal() -> void:
	_revealed = true
	_playing = false
	queue_redraw()
	draw_finished.emit()


func _hide() -> void:
	visible = false


func _color_for_quality(quality: String) -> Color:
	match quality:
		"good":
			return Color(0.85, 0.75, 0.4)
		"common":
			return Color(0.6, 0.6, 0.65)
		"poor":
			return Color(0.4, 0.35, 0.4)
		_:
			return Color(0.5, 0.5, 0.5)


func _draw() -> void:
	var center := Vector2(size.x * 0.5, 90.0)
	var shake_off := Vector2(sin(_shake * TAU * 4.0) * _shake * 3.0, 0.0)

	# Machine body: a glass dome on a base — shading only, no color of its own,
	# same rule as the soul shells (blender/generate_souls.py).
	var dome_center := center + Vector2(0.0, MACHINE_TOP_Y) + shake_off
	draw_circle(dome_center, 34.0, Color(0.15, 0.15, 0.18, 0.25))
	draw_arc(dome_center, 34.0, PI, TAU, 24, Color(0.5, 0.5, 0.55, 0.5), 2.0, false)
	var base_rect := Rect2(center.x - 26.0, center.y + 20.0, 52.0, 24.0)
	draw_rect(base_rect, Color(0.12, 0.12, 0.15, 0.7))

	# Lever — swings with the shake
	var lever_swing: float = sin(_shake * PI) * 0.6
	var lever_base := center + Vector2(30.0, 24.0)
	var lever_tip := lever_base + Vector2(cos(-PI * 0.3 - lever_swing), sin(-PI * 0.3 - lever_swing)) * 18.0
	draw_line(lever_base, lever_tip, Color(0.55, 0.5, 0.4, 0.8), 3.0, false)
	draw_circle(lever_tip, 3.0, Color(0.6, 0.55, 0.45, 0.9))

	# Chute
	draw_line(center + Vector2(0.0, 44.0), center + Vector2(0.0, CHUTE_Y), Color(0.3, 0.3, 0.35, 0.4), 6.0, false)

	if _playing or _revealed:
		var capsule_pos := center + Vector2(0.0, _capsule_y) + shake_off
		if not _revealed:
			# Falling capsule — colorless, matching the shell-first aesthetic
			draw_circle(capsule_pos, 8.0, Color(0.5, 0.5, 0.5, 0.9))
			draw_arc(capsule_pos, 8.0, 0.0, TAU, 16, Color(0.7, 0.7, 0.72, 0.6), 1.0, false)
		else:
			# Revealed: quality shows as color the machine itself never held —
			# the fill only appears once the roll resolves.
			draw_circle(capsule_pos, 10.0, _quality_col)
			draw_arc(capsule_pos, 13.0, 0.0, TAU, 20, _quality_col, 1.5, false)
