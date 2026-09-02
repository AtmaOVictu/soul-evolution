# distinction_node.gd — A single distinction in the world (v2: glyphs + identity)
#
# Each distinction is a Node2D with:
# - Its own clarity (local, not global)
# - A GLYPH drawn from the Beseda je Ne system — not a generic dot
# - A visual life that changes with its stage
# - Capacity to react: hover, examine, witness, guard, seal
#
# Glyphs by stage:
#   TENTATIVE    → ∅ (void-origin, barely exists)
#   DISTINGUISHED → Δ (delta — change/cut)
#   SCOPED       → Δ with ring (scope indicator)
#   WITNESSED    → ⟡ (evidence/resonance — the canonical trace operator)
#   GUARDED      → Δ or ⟡ with aura (green=pass, red=knot)
#   SEALED       → ◉ (solid, permanent, self-contained)

extends Node2D

enum Stage {
	TENTATIVE,
	DISTINGUISHED,
	SCOPED,
	WITNESSED,
	GUARDED,
	SEALED,
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

# ── Glyphs (Unicode) ──
const GLYPH_VOID := "∅"      # TENTATIVE — barely exists
const GLYPH_DELTA := "Δ"     # DISTINGUISHED — a cut was made
const GLYPH_EVIDENCE := "⟡"  # WITNESSED — the trace operator
const GLYPH_SEALED := "◉"    # SEALED — permanent, self-contained

# ── State ──
var local_clarity: float = 0.0
var stage: Stage = Stage.TENTATIVE
var quality: StringName = &"CUT"
var is_scoped: bool = false
var is_witnessed: bool = false
var guard_result: Dictionary = {}
var is_sealed: bool = false
var creation_time: float = 0.0
var distinction_id: int = -1

# ── Visual ──
var _breath_time: float = 0.0
var _glow_radius: float = 10.0
var _core_color: Color = Color(0.4, 0.5, 0.8, 0.8)
var _aura_color: Color = Color(0.3, 0.4, 0.7, 0.0)
var _flicker_amount: float = 0.3
var _hover_intensity: float = 0.0

# ── Signals ──
signal clarity_changed(node: Node2D, new_value: float)
signal stage_changed(node: Node2D, new_stage: Stage)
signal distinction_hovered(node: Node2D)
signal distinction_examined(node: Node2D)

static var _next_id: int = 0

func _init() -> void:
	creation_time = Time.get_ticks_msec() / 1000.0
	distinction_id = _next_id
	_next_id += 1

func _draw() -> void:
	var k := local_clarity
	
	# Aura (guard result)
	if stage >= Stage.GUARDED and not guard_result.is_empty():
		var aura_r := _glow_radius * 3.5
		var aura_pulse := sin(_breath_time * 1.0) * 0.1 if stage < Stage.SEALED else 0.0
		draw_circle(Vector2.ZERO, aura_r, Color(_aura_color.r, _aura_color.g, _aura_color.b, _aura_color.a + aura_pulse))
	
	# Glow
	var glow_r := _glow_radius * (1.0 + k * 2.5)
	var glow_alpha := (0.15 + k * 0.35) * (1.0 + _hover_intensity * 0.5)
	draw_circle(Vector2.ZERO, glow_r, Color(_core_color.r, _core_color.g, _core_color.b, glow_alpha * 0.3))
	
	# Core glyph
	var core_r := 5.0 + k * 5.0
	var core_alpha := 0.5 + k * 0.5
	
	if stage == Stage.SEALED:
		# Sealed: solid filled circle + ring (◉)
		draw_circle(Vector2.ZERO, core_r, Color(_core_color.r, _core_color.g, _core_color.b, 1.0))
		draw_arc(Vector2.ZERO, core_r * 1.4, 0, TAU, 32,
			Color(_core_color.r * 1.3, _core_color.g * 1.3, _core_color.b * 1.3, 0.7), 2.0)
	elif stage >= Stage.WITNESSED:
		# Witnessed: steady glow + ⟡ shape (two overlapping arcs)
		draw_circle(Vector2.ZERO, core_r, Color(_core_color.r, _core_color.g, _core_color.b, core_alpha))
		# ⟡ — resonance trace: two arcs meeting
		var arc_r := core_r * 0.7
		draw_arc(Vector2(-core_r * 0.3, 0), arc_r, -PI/3, PI/3, 12,
			Color(0.6, 0.7, 0.9, 0.8), 1.5)
		draw_arc(Vector2(core_r * 0.3, 0), arc_r, PI - PI/3, PI + PI/3, 12,
			Color(0.6, 0.7, 0.9, 0.8), 1.5)
	elif stage >= Stage.SCOPED:
		# Scoped: solid point + scope ring
		draw_circle(Vector2.ZERO, core_r, Color(_core_color.r, _core_color.g, _core_color.b, core_alpha))
		draw_arc(Vector2.ZERO, glow_r * 1.3, 0, TAU, 24, Color(0.5, 0.6, 0.9, 0.4), 1.0)
	else:
		# Tentative / Distinguished: breathing Δ or ∅
		var breath := sin(_breath_time * 2.0) * _flicker_amount
		if stage == Stage.TENTATIVE:
			# ∅ — faint, barely there
			draw_arc(Vector2.ZERO, core_r * 0.8, 0, TAU * 0.8, 16,
				Color(_core_color.r, _core_color.g, _core_color.b, core_alpha * 0.5 + breath), 1.0)
		else:
			# Δ — triangle, the cut
			var tri_r := core_r
			var p1 := Vector2(0, -tri_r)
			var p2 := Vector2(-tri_r * 0.866, tri_r * 0.5)
			var p3 := Vector2(tri_r * 0.866, tri_r * 0.5)
			draw_colored_polygon([p1, p2, p3],
				Color(_core_color.r, _core_color.g, _core_color.b, core_alpha + breath))

func _process(delta: float) -> void:
	if stage == Stage.SEALED:
		return  # Sealed things do not animate
	
	_breath_time += delta
	_flicker_amount = 0.3 * (1.0 - local_clarity)
	
	# Color shift: cool blue (tentative) → warm violet (stable)
	_core_color = Color(
		lerpf(0.4, 0.6, local_clarity),
		lerpf(0.5, 0.4, local_clarity),
		lerpf(0.8, 0.7, local_clarity),
		0.8
	)
	
	# Aura from guard result
	if guard_result.has("pass"):
		if guard_result["pass"]:
			_aura_color = Color(0.3, 0.6, 0.3, 0.3)
		else:
			_aura_color = Color(0.6, 0.2, 0.2, 0.4)
	
	# Hover fades back
	_hover_intensity = lerpf(_hover_intensity, 0.0, delta * 3.0)
	
	queue_redraw()

func _input(event: InputEvent) -> void:
	if stage == Stage.SEALED:
		return
	if event is InputEventMouseMotion:
		var local_pos := make_input_local(event).position
		if local_pos.distance_to(Vector2.ZERO) < _glow_radius * 2.0:
			_hover_intensity = 1.0
			distinction_hovered.emit(self)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos := make_input_local(event).position
		if local_pos.distance_to(Vector2.ZERO) < _glow_radius * 2.0:
			distinction_examined.emit(self)

# ── Clarity ──
func set_clarity(value: float) -> void:
	var old := local_clarity
	local_clarity = clampf(value, 0.0, 1.0)
	_update_stage()
	if local_clarity != old:
		clarity_changed.emit(self, local_clarity)
		Events.local_clarity_changed.emit(self, local_clarity, local_clarity - old)

func gain_clarity(amount: float) -> void:
	set_clarity(local_clarity + amount)

func _update_stage() -> void:
	var new_stage := stage
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
	gain_clarity(0.25)
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

func get_glyph() -> String:
	match stage:
		Stage.SEALED: return GLYPH_SEALED
		Stage.WITNESSED: return GLYPH_EVIDENCE
		Stage.DISTINGUISHED, Stage.SCOPED, Stage.GUARDED: return GLYPH_DELTA
		_: return GLYPH_VOID