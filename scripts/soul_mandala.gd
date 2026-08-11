class_name SoulMandala
extends Control
## The GENOME MANDALA — an interactive asset whose appearance IS the genome.
## Each concentric ring is a genome layer; each segment is a component sized
## and colored by its value, and every segment is CLICKABLE to reveal what the
## attribute is, its % value, and what it converts into (its visible use).
##
## Reuses the canon's mandala/soul-visual concept and the real genome data.
## The % values are drawn as arcs (the "percent-in-circles" display).

signal segment_selected(name: String, value: float, detail: String)

var genome: RefCounted = null
var _hover_segment: int = -1

# Each ring: {name, count, get_val(i), label(i), detail(i)}
var _rings: Array = []


func set_genome(g: RefCounted) -> void:
	genome = g
	_build_rings()
	queue_redraw()


func _build_rings() -> void:
	_rings.clear()
	if not genome:
		return
	# Ring 0 — the operator genes (the DNA).
	_rings.append({
		"name": "GENES",
		"count": 6,
		"get_val": func(i): return [genome.divergence, genome.negation, genome.delta,
			genome.trace, genome.tau, genome.sigma][i] * 100.0,
		"label": func(i): return ["div", "neg", "delta", "trace", "tau", "sigma"][i],
		"detail": func(i): return ["the cut's origin", "the primal No / doubt", "change",
			"trace — feeds color", "the path", "discipline"][i],
	})
	# Ring 1 — the abilities (the phenotype).
	_rings.append({
		"name": "ABILITIES",
		"count": 7,
		"get_val": func(i): return float([genome.STR, genome.STA, genome.INT,
			genome.WIS, genome.CHA, genome.DEX, genome.LUK][i]),
		"label": func(i): return ["STR", "STA", "INT", "WIS", "CHA", "DEX", "LUK"][i],
		"detail": func(i): return ["strength", "stamina = size", "intellect", "wisdom",
			"charisma", "dexterity", "luck — ever present"][i],
	})
	# Ring 2 — the powers (the Box).
	_rings.append({
		"name": "POWERS",
		"count": 8,
		"get_val": func(i): return [genome.pow_fizicna, genome.pow_psiholoska,
			genome.pow_custvena, genome.pow_duhovna, genome.pow_dusevna,
			genome.pow_inteligenca, genome.pow_gibljivost, genome.pow_stamina_val][i] * 100.0,
		"label": func(i): return ["fiz", "psi", "cust", "duh", "dus", "int", "gib", "sta"][i],
		"detail": func(i): return ["physical", "psychological", "emotional", "spiritual",
			"soul", "intelligence", "mobility", "stamina"][i],
	})


func _segment_at(pos: Vector2) -> Dictionary:
	# Hit-test: find which ring + segment the point is over.
	var c := size * 0.5
	var d := pos - c
	var r := d.length()
	var a := wrapf(atan2(d.y, d.x), 0.0, TAU)
	var ring_radii := _ring_radii()
	for ri in range(_rings.size()):
		var rr: Array = ring_radii[ri]
		if r >= rr[0] and r <= rr[1]:
			var ring: Dictionary = _rings[ri]
			var seg := int(a / TAU * float(ring["count"]))
			return {"ring": ri, "seg": seg}
	return {}


func _ring_radii() -> Array:
	# Returns per-ring [inner, outer] radii, scaled to the control size.
	var base := minf(size.x, size.y) * 0.5
	var n := _rings.size()
	var out: Array = []
	for i in range(n):
		var inner := base * (0.35 + 0.2 * float(i) / maxf(float(n), 1.0))
		var outer := base * (0.35 + 0.2 * float(i + 1) / maxf(float(n), 1.0))
		out.append([inner, outer])
	return out


func _draw() -> void:
	if not genome:
		draw_circle(size * 0.5, minf(size.x, size.y) * 0.2, Color(0.2, 0.2, 0.25))
		return
	var ring_radii := _ring_radii()
	var c := size * 0.5
	for ri in range(_rings.size()):
		var ring: Dictionary = _rings[ri]
		var rr: Array = ring_radii[ri]
		var inner: float = rr[0]
		var outer: float = rr[1]
		var step := TAU / float(ring["count"])
		for i in range(ring["count"]):
			var a0 := -PI / 2.0 + float(i) * step
			var a1 := a0 + step
			var val: float = clampf(ring["get_val"].call(i), 0.0, 100.0)
			# Color by value: hue from red (0) through green (100) — the soul's
			# vitality for that attribute.
			var col := Color.from_hsv(val / 100.0 * 0.4, 0.7, 0.8)
			# Radial extent scales with value — the segment 'fills' its arc.
			var fill_r := inner + (outer - inner) * (0.2 + 0.8 * val / 100.0)
			var pts := PackedVector2Array()
			pts.append(c + Vector2(cos(a0), sin(a0)) * inner)
			var segs := 8
			for s in range(1, segs + 1):
				var a := lerpf(a0, a1, float(s) / float(segs))
				pts.append(c + Vector2(cos(a), sin(a)) * fill_r)
			pts.append(c + Vector2(cos(a1), sin(a1)) * inner)
			draw_colored_polygon(pts, col)
			# Stroke the segment edge.
			draw_arc(c, inner, a0, a1, 8, Color(0.1, 0.1, 0.1, 0.6), 1.0)
	# Core — polarity + psi.
	var core_r := minf(size.x, size.y) * 0.12
	draw_circle(c, core_r, Color(0.9, 0.9, 0.95) if genome.polarity == 0 else Color(0.15, 0.15, 0.2))
	draw_arc(c, core_r, 0.0, TAU, 24, Color(0.5, 0.5, 0.55), 2.0)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var hit := _segment_at(event.position)
		var id := -1
		if hit.size() > 0:
			id = hit["ring"] * 100 + hit["seg"]
		if id != _hover_segment:
			_hover_segment = id
			queue_redraw()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var hit := _segment_at(event.position)
		if hit.size() > 0:
			var ring: Dictionary = _rings[hit["ring"]]
			var i: int = hit["seg"]
			var v: float = clampf(ring["get_val"].call(i), 0.0, 100.0)
			segment_selected.emit(ring["label"].call(i), v, ring["detail"].call(i))