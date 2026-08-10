extends SceneTree
## Focused integration test for the Reaction-Formation → Reaction → Purpose-Fuel
## loop (the "forms reactions and fuels purpose" system).
##
## Run: Godot_v4.6.2-stable_win64_console.exe --headless --script res://scripts/tests/reaction_loop_test.gd
##
## Drives the full loop exactly as main.gd does and prints the live numbers so
## the behaviour is visible, not just asserted.

const SoulGenomeScript := preload("res://scripts/soul_genome.gd")
const ReactionEngineScript := preload("res://scripts/reaction_engine.gd")
const PurposeLadderScript := preload("res://scripts/purpose_ladder.gd")

var _pass := 0
var _fail := 0


func _initialize() -> void:
	print("=== REACTION + PURPOSE LOOP INTEGRATION TEST ===\n")

	# A soul like the game's ORIGINAL (ego 1.0, boosted), driven to resonance.
	var g = SoulGenomeScript.create_random(7, 0)
	g.set_ego(1.0)
	g.divergence = 0.85
	g.delta = 0.82
	g.trace = 0.78
	g.negation = 0.28
	g.tau = 0.6
	g.sigma = 0.55
	g._compute_abilities()
	g._compute_psi()
	g._compute_powers()
	g._compute_mithjos()

	var engine = ReactionEngineScript.new()
	var ladder = PurposeLadderScript.new()

	print("Starting soul — psi=%.3f  mithjos Z=%.2f J=%.2f E=%.2f N=%.2f" % [g.psi, g.mithjos_Z, g.mithjos_J, g.mithjos_E, g.mithjos_N])
	print("Ladder starts at: ", ladder.current())
	print("")

	# The act the soul forms: its three strongest operators (like main.gd).
	var ops := ["∇", "¬", "∆", "✡", "τ", "σ"]
	var genes := {"∇": g.divergence, "¬": g.negation, "∆": g.delta, "✡": g.trace, "τ": g.tau, "σ": g.sigma}
	var sorted := ops.duplicate()
	sorted.sort_custom(func(a, b): return genes[a] > genes[b])
	var act: Array[String] = []
	for i in mini(3, sorted.size()):
		act.append(String(sorted[i]))

	print("Soul's formed act (∅sentence): ", "⊕".join(act))
	print("")

	# Drive the loop for enough iterations to climb the ladder.
	var ascensions := 0
	var min_align := 1.0
	var max_align := 0.0
	var min_noise := 1.0
	var max_noise := 0.0
	var min_delta := 1.0
	var max_delta := 0.0
	var min_risk := 1.0
	var max_risk := 0.0
	for iter in 14:
		var prof: Dictionary = engine.form_act(g, act)
		var r: Dictionary = engine.react(g, prof)
		engine.apply_reaction(g, r)
		var ascended: bool = ladder.fuel(g, r, r["echo"])
		if ascended:
			ascensions += 1
		min_align = minf(min_align, prof["align"])
		max_align = maxf(max_align, prof["align"])
		min_noise = minf(min_noise, prof["noise"])
		max_noise = maxf(max_noise, prof["noise"])
		min_delta = minf(min_delta, prof["delta"])
		max_delta = maxf(max_delta, prof["delta"])
		min_risk = minf(min_risk, prof["risk"])
		max_risk = maxf(max_risk, prof["risk"])
		var ladder_d: Dictionary = ladder.to_dict()
		print("iter=%2d  %-8s | align=%.2f noise=%.2f d=%.2f risk=%.2f | echo=%.2f %s | purpose=%.2f/%.2f | register=%s%s" % [
			iter, "⊕".join(act), prof["align"], prof["noise"], prof["delta"], prof["risk"],
			r["echo"], r["verdict"], ladder_d["purpose"], ladder_d["threshold"],
			ladder_d["current"], ("  ▲ ASCENDED" if ascended else "")
		])

	print("")
	print("=== ASERTIONS ===")
	# The loop must have ascended at least once from MOLK.
	_assert(ladder.index > 0, "purpose ladder ascended past MOLK (index=%d)" % ladder.index)
	_assert(ascensions >= 1, "at least one ascension event reported (got %d)" % ascensions)
	# The soul's mithjos must have grown (reactions fed consciousness).
	_assert(g.mithjos_Z > 0.0, "reactions raised mithjos_Z (consciousness fuel)")
	# Every reaction must carry the four KANON metrics in [0,1].
	_assert(min_align >= 0.0 and max_align <= 1.0, "align stays in [0,1]")
	_assert(min_noise >= 0.0 and max_noise <= 1.0, "noise stays in [0,1]")
	_assert(min_delta >= 0.0 and max_delta <= 1.0, "delta stays in [0,1]")
	_assert(min_risk >= 0.0 and max_risk <= 1.0, "risk stays in [0,1]")
	# The ladder should end at a sensible register (not overflow the array).
	_assert(ladder.index < PurposeLadderScript.REGISTERS.size(), "ladder index within REGISTERS bounds")

	print("")
	print("=== RESULTS: %d passed, %d failed ===" % [_pass, _fail])
	quit()


func _assert(cond: bool, name: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  FAIL: ", name)