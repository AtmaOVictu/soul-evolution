# distinction_node.gd — A single distinction in the world
#
# This IS the world-building unit. Each distinction is a Node2D with:
# - Its own clarity (κ_local) — NOT the global clarity
# - A clarity stage that determines its visual and interactive state
# - A visual representation that changes as ITS clarity changes
# - Capacity to react: hover, examine, witness, guard, seal
#
# The world is not pre-authored. It is grown, one DistinctionNode at a time.
# Each node has its own life — its own breath, its own stability.

extends Node2D

# ── Clarity stages (the life of a distinction) ──
enum Stage {
	TENTATIVE,     # κ 0.05 — just born, flickering, barely visible
	DISTINGUISHED, # κ 0.15 — solid point, own glow, pulses
	SCOPED,        # κ 0.30 — brightens inside Ref, dims outside
	WITNESSED,     # κ 0.55 — stops flickering, holds steady
	GUARDED,       # κ 0.75 — aura appears (green=pass, red=fail)
	SEALED,        # κ 1.00 — all animation stops, permanent
}

const STAGE_KAPPA := {
	Stage.TENTATIVE: 0.05,
	Stage.DISTINGUISHED: 0.15,
	Stage.SCOPED: 0.30,
	Stage.WITNESSED: 0.55,
	Stage.GUARDED: 0.75,
	Stage.SEALED: 1.00,
}

const STAGE_NAMES := {
	Stage.TENTATIVE: "tentative",
	Stage.DISTINGUISHED: "distinguished",
	Stage.SCOPED: "scoped",
	Stage.WITNESSED: "witnessed",
	Stage.GUARDED: "guarded",
	Stage.SEALED: "sealed",
}

# ── State ──
var local_clarity: float = 0.0
var stage: Stage = Stage.TENTATIVE
var quality: StringName = &"CUT"  # CUT or BOUNDED
var is_scoped: bool = false  # inside a Ref frame?
var is_witnessed: bool = false
var guard_result: Dictionary = {}
var is_sealed: bool = false
var creation_time: float = 0.0

# ── Visual state ──
var _breath_time: float = 0.0
var _glow_radius: float = 8.0
var _core_color: Color = Color(0.4, 0.5, 0.8, 0.8)
var _aura_color: Color = Color(0.3, 0.4, 0.7, 0.0)
var _flicker_amount: float = 0.3

# ── Signals ──
signal clarity_changed(node: Node2D, new_value: float)
signal stage_changed(node: Node2D, new_stage: Stage)
signal distinction_hovered(node: Node2D)
signal distinction_examined(node: Node2D)

# ── Drawing ──
func _draw() -> void:
	var kappa := local_clarity
	
	# Aura (guard result) — drawn behind everything
	if stage >= Stage.GUARDED:
		var aura_r := _glow_radius * 3.0
		draw_circle(Vector2.ZERO, aura_r, _aura_color)
	
	# Glow — radius grows with clarity
	var glow_r := _glow_radius * (1.0 + kappa * 2.0)
	var glow_alpha := 0.3 + kappa * 0.4
	draw_circle(Vector2.ZERO, glow_r, Color(_core_color.r, _core_color.g, _core_color.b, glow_alpha * 0.3))
	
	# Core — the distinction point itself
	var core_r := 4.0 + kappa * 4.0
	var core_alpha := 0.6 + kappa * 0.4
	
	if stage == Stage.SEALED:
		# Sealed: solid, no flicker, permanent
		draw_circle(Vector2.ZERO, core_r, Color(_core_color.r, _core_color.g, _core_color.b, 1.0))
		draw_arc(Vector2.ZERO, core_r * 1.5, 0, TAU, 32, Color(_core_color.r * 1.2, _core_color.g * 1.2, _core_color.b * 1.2, 0.5), 1.5)
	elif stage >= Stage.WITNESSED:
		# Witnessed: steady glow, no flicker
		draw_circle(Vector2.ZERO, core_r, Color(_core_color.r, _core_color.g, _core_color.b, core_alpha))
	else:
		# Tentative/Distinguished/Scoped: breathing flicker
		var breath := sin(_breath_time * 2.0) * _flicker_amount
		draw_circle(Vector2.ZERO, core_r, Color(_core_color.r, _core_color.g, _core_color.b, core_alpha + breath))
	
	# Scoped indicator — ring if inside Ref frame
	if is_scoped and stage < Stage.WITNESSED:
		draw_arc(Vector2.ZERO, glow_r * 1.2, 0, TAU, 24, Color(0.5, 0.6, 0.9, 0.4), 1.0)

func _process(delta: float) -> void:
	if stage == Stage.SEALED:
		return  # Sealed things do not animate
	
	_breath_time += delta
	
	# Flicker decreases as clarity rises
	_flicker_amount = 0.3 * (1.0 - local_clarity)
	
	# Color shifts from cool blue (tentative) to warm violet (stable)
	_core_color = Color(
		lerpf(0.4, 0.6, local_clarity),
		lerpf(0.5, 0.4, local_clarity),
		lerpf(0.8, 0.7, local_clarity),
		0.8
	)
	
	# Aura color from guard result
	if guard_result.has("pass"):
		if guard_result["pass"]:
			_aura_color = Color(0.3, 0.6, 0.3, 0.3)
		else:
			_aura_color = Color(0.6, 0.2, 0.2, 0.4)
	
	queue_redraw()

# ── Interaction ──
func _input(event: InputEvent) -> void:
	if stage == Stage.SEALED:
		return
	
	if event is InputEventMouseMotion:
		var local_pos := make_input_local(event).position
		var dist := local_pos.distance_to(Vector2.ZERO)
		if dist < _glow_radius * 2.0:
			distinction_hovered.emit(self)
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos := make_input_local(event).position
		if local_pos.distance_to(Vector2.ZERO) < _glow_radius * 2.0:
			distinction_examined.emit(self)

# ── Clarity mutation ──
func set_clarity(value: float) -> void:
	var old_clarity := local_clarity
	local_clarity = clampf(value, 0.0, 1.0)
	_update_stage()
	if local_clarity != old_clarity:
		clarity_changed.emit(self, local_clarity)
		Events.local_clarity_changed.emit(self, local_clarity, local_clarity - old_clarity)

func gain_clarity(amount: float) -> void:
	set_clarity(local_clarity + amount)

func _update_stage() -> void:
	var new_stage := stage
	
	# Determine stage from clarity + flags
	if is_sealed:
		new_stage = Stage.SEALED
	elif not guard_result.is_empty():
		new_stage = Stage.GUARDED
	elif is_witnessed:
		new_stage = Stage.WITNESSED
	elif is_scoped:
		new_stage = Stage.SCOPED
	elif local_clarity >= 0.15:
		new_stage = Stage.DISTINGUISHED
	else:
		new_stage = Stage.TENTATIVE
	
	if new_stage != stage:
		stage = new_stage
		stage_changed.emit(self, new_stage)
		Events.distinction_stage_changed.emit(self, StringName(STAGE_NAMES[new_stage]))

func set_scoped(in_scope: bool) -> void:
	is_scoped = in_scope
	_update_stage()

func set_witnessed() -> void:
	is_witnessed = true
	gain_clarity(0.25)  # witnessing increases local clarity
	_update_stage()

func set_guard_result(result: Dictionary) -> void:
	guard_result = result
	gain_clarity(0.20)
	_update_stage()

func seal() -> void:
	is_sealed = true
	set_clarity(1.0)

func get_stage_name() -> String:
	return STAGE_NAMES.get(stage, "unknown")

func _init() -> void:
	creation_time = Time.get_ticks_msec() / 1000.0