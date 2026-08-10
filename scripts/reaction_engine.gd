class_name ReactionEngine
extends RefCounted
## Reaction-Formation + Reaction engine (canon: parcel-sound-physics, parcel-
## kanon-standard, parcel-sound-therapy, parcel-silent-poetry).
##
## FORMS REACTIONS: the player forms an act — a sequence of operators (the
## ∅sentence Sᵢ = {α₁ ⊕ α₂ ⊕ ... ⊕ αₙ}, each α mapped onto a genome gene) —
## and the engine computes its RESONANCE PROFILE (align, noise, Δ, risk from
## the KANON card; the wave-act from the ∅sentence).
##
## REACTS: from that profile it produces a REACTION — an echo (the ∅sound-
## mirror), a validation (∇MENTOR: DA/∅/NE), and the three evaluation-tones
## (first echo / second tone / third ringing). The reaction then modifies the
## soul's mithjos (Z·J·E·N) and powers so the purpose-ladder has fuel to read.
##
## Pure logic — no scene nodes — so it is unit-testable in isolation.

const OPERATORS := ["∇", "¬", "∆", "✡", "τ", "σ"]


## Build a resonance profile for an act formed out of `ops` (an array of
## operator strings, each in OPERATORS) by a soul with genome `g`.
## Returns a Dictionary:
##   { align, noise, delta, risk, wave, carriers, tokens, pass }
func form_act(g: RefCounted, ops: Array[String]) -> Dictionary:
	var carriers := 0
	var tokens := 0
	var wave := 0.0
	var sem := 0.0
	var ont := 0.0
	var eff := 0.0

	for i in ops.size():
		var op := ops[i]
		if op not in OPERATORS:
			continue
		tokens += 1
		# Each operator "carries" meaning only if it resonates (the gene is
		# non-trivial). The more carriers among tokens, the lower the noise.
		var gene_val := _gene_for(g, op)
		if gene_val > 0.05:
			carriers += 1
		# The ∅sentence wave-act: each α contributes a sine term; the phase
		# ladder is the operator's index on the golden-ratio ladder.
		var phase := float(i) * SacredGeometry.PHI
		wave += sin(gene_val * TAU + phase)
		# Semantic content = how much the gene actually carries.
		sem += gene_val
		# Ontological force = the gene's presence times the operator's weight.
		ont += gene_val * (0.5 + 0.5 * (float(i + 1) / float(ops.size())))
		# Effect = whether this act moves the soul (delta of the act).
		eff += (g.delta if op in ["∇", "∆"] else (g.trace if op in ["✡"] else g.negation))

	if tokens == 0:
		return {
			"align": 0.0, "noise": 1.0, "delta": 0.0, "risk": 0.0,
			"wave": 0.0, "carriers": 0, "tokens": 0, "pass": false,
		}

	# KANON metrics.
	var align: float = 0.4 * (sem / tokens) + 0.4 * (ont / tokens) + 0.2 * (eff / tokens)
	align = clampf(align, 0.0, 1.0)
	var noise: float = 1.0 - float(carriers) / float(tokens)
	noise = clampf(noise, 0.0, 1.0)
	var delta: float = clampf(absf(wave) / float(tokens), 0.0, 1.0)
	# Risk grows with noise and the soul's negation (the dvom), falls with align.
	var risk: float = clampf(0.3 * noise + g.negation * 0.4 + (1.0 - align) * 0.3, 0.0, 1.0)

	# Canonical PASS tests (KANON): align ≥ 0.70, noise ≤ 0.10, Δ ≥ 0.01, risk < 0.60.
	var pass_ok: bool = align >= 0.70 and noise <= 0.10 and delta >= 0.01 and risk < 0.60

	return {
		"align": align, "noise": noise, "delta": delta, "risk": risk,
		"wave": wave, "carriers": carriers, "tokens": tokens, "pass": pass_ok,
	}


## Produce the REACTION from a profile. Returns:
##   { echo, verdict, tone1, tone2, tone3, mith_delta, power_delta }
## - echo: the ∅sound-mirror's emotional echo (higher = truer resonance).
## - verdict: "DA" | "∅" | "NE" (∇MENTOR validator).
## - tone1/2/3: the evaluation-tones (immediate / slow-tuning / enduring).
## - mith_delta / power_delta: how the reaction moves mithjos & powers.
func react(g: RefCounted, profile: Dictionary) -> Dictionary:
	var align: float = profile["align"]
	var noise: float = profile["noise"]
	var delta: float = profile["delta"]
	var risk: float = profile["risk"]

	# ∅sound-mirror echo: resonance back, damped by noise and risk.
	var echo: float = clampf(align * (1.0 - noise) * (1.0 - risk * 0.5), 0.0, 1.0)

	# ∇MENTOR validator.
	var verdict := "DA" if (align >= 0.70 and risk < 0.60) else ("NE" if risk >= 0.60 else "∅")

	# Evaluation-tones (canon: first echo / second tone / third ringing).
	var tone1: float = echo
	var tone2: float = clampf(echo + delta * 0.15, 0.0, 1.0)   # slow tuning
	var tone3: float = clampf(echo * 0.7 + align * 0.3, 0.0, 1.0)  # enduring

	# Mithjos shifts: an act that resonates raises consciousness (Z) and the
	# ethical process (E); a noisy/risky act spikes the paradox (N).
	var mith_delta := {
		"Z": clampf(0.15 * echo, 0.0, 0.2),
		"J": clampf(0.10 * echo, 0.0, 0.15),
		"E": clampf(0.12 * echo, 0.0, 0.18),
		"N": clampf(0.10 * (1.0 - align) + 0.08 * risk, 0.0, 0.2),
	}
	var power_delta: float = clampf(echo * 0.5 + delta * 0.3, 0.0, 0.5)

	return {
		"echo": echo, "verdict": verdict,
		"tone1": tone1, "tone2": tone2, "tone3": tone3,
		"mith_delta": mith_delta, "power_delta": power_delta,
	}


## Apply a reaction to a genome's mithjos/powers. Returns the new values.
func apply_reaction(g: RefCounted, reaction: Dictionary) -> Dictionary:
	var md: Dictionary = reaction["mith_delta"]
	g.mithjos_Z = clampf(g.mithjos_Z + md["Z"], 0.0, 1.0)
	g.mithjos_J = clampf(g.mithjos_J + md["J"], 0.0, 1.0)
	g.mithjos_E = clampf(g.mithjos_E + md["E"], 0.0, 1.0)
	g.mithjos_N = clampf(g.mithjos_N + md["N"], 0.0, 1.0)
	# Boosting the soul powers by the reaction's power_delta.
	var pd: float = reaction["power_delta"]
	g.pow_duhovna = clampf(g.pow_duhovna + pd * 0.5, 0.0, 1.0)
	g.pow_custvena = clampf(g.pow_custvena + pd * 0.5, 0.0, 1.0)
	return {
		"Z": g.mithjos_Z, "J": g.mithjos_J, "E": g.mithjos_E, "N": g.mithjos_N,
		"duhovna": g.pow_duhovna, "custvena": g.pow_custvena,
	}


## The gene a given operator maps to on the genome.
func _gene_for(g: RefCounted, op: String) -> float:
	match op:
		"∇": return g.divergence
		"¬": return g.negation
		"∆": return g.delta
		"✡": return g.trace
		"τ": return g.tau
		"σ": return g.sigma
	return 0.0