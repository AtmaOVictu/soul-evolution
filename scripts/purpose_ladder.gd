class_name PurposeLadder
extends RefCounted
## Purpose-Fuel (canon: parcel-mandala-algebra). The ascending chain
## MOLK→DOLG→VOLK→SVETLOBA→RITUAL→IGRA→USTVARJANJE→SPOMIN→ZAVEDANJE→INTENCIJA→
## AKCIJA — the soul's growth ladder. Each register has a canon formula (the
## registers as log-algebra). The ladder is FUELED by reactions: every resonant
## reaction from ReactionEngine feeds "purpose" into the current register, and
## when the register's cumulative resonance crosses its threshold, the soul
## ASCENDS to the next register — which then changes how the soul forms and
## reacts (the feedback loop).
##
## Pure logic — no scene nodes — unit-testable in isolation.

const REGISTERS: Array[String] = [
	"MOLK",        # silence — the source
	"DOLG",        # bond / debt — the relation
	"VOLK",        # alarm / instinct
	"SVETLOBA",    # light — revelation
	"RITUAL",      # practice
	"IGRA",        # play
	"USTVARJANJE", # creation
	"SPOMIN",      # memory
	"ZAVEDANJE",   # awareness
	"INTENCIJA",   # intention
	"AKCIJA",      # action
]

var index: int = 0  # current register index (0 = MOLK)
var purpose: float = 0.0  # accumulated purpose toward the next register
var ascensions: int = 0
var history: Array[String] = []


func current() -> String:
	return REGISTERS[index]


func next() -> String:
	return REGISTERS[index + 1] if index < REGISTERS.size() - 1 else REGISTERS[index]


func is_maxed() -> bool:
	return index >= REGISTERS.size() - 1


## The canon register formula value from the genome (the log-algebra).
func register_value(g: RefCounted) -> float:
	# MOLK is the reservoir: silence as the source. Higher negation/mithjos-N
	# (the paradox/doubt) feeds the source; higher mithjos-Z (consciousness)
	# carries the ascent.
	match REGISTERS[index]:
		"MOLK":
			return clampf(g.negation * 0.5 + g.mithjos_N * 0.5, 0.0, 1.0)
		"DOLG":
			return clampf(g.trace * 0.4 + g.mithjos_J * 0.6, 0.0, 1.0)
		"VOLK":
			return clampf(g.delta * 0.5 + g.mithjos_N * 0.5, 0.0, 1.0)
		"SVETLOBA":
			return clampf(g.trace * 0.6 + g.mithjos_Z * 0.4, 0.0, 1.0)
		"RITUAL":
			return clampf(0.5 * g.mithjos_E + 0.5 * g.mithjos_Z, 0.0, 1.0)
		"IGRA":
			return clampf(0.6 * g.delta + 0.4 * g.trace, 0.0, 1.0)
		"USTVARJANJE":
			return clampf(0.5 * g.pow_custvena + 0.5 * g.pow_duhovna, 0.0, 1.0)
		"SPOMIN":
			return clampf(g.mithjos_E * 0.5 + g.mithjos_Z * 0.5, 0.0, 1.0)
		"ZAVEDANJE":
			return clampf(g.mithjos_Z, 0.0, 1.0)
		"INTENCIJA":
			return clampf(g.mithjos_J * 0.5 + g.mithjos_Z * 0.5, 0.0, 1.0)
		"AKCIJA":
			return clampf(g.psi, 0.0, 1.0)
	return 0.0


## Threshold to ascend from the current register. Higher registers need more
## purpose (the ascent steepens toward AKCIJA).
func threshold() -> float:
	return 0.5 + float(index) * 0.08


## Feed a resonant reaction into the ladder. `reaction` is a ReactionEngine
## reaction dict. Returns true if an ascension happened.
func fuel(g: RefCounted, reaction: Dictionary, echo: float) -> bool:
	var gain: float = echo * 1.0 + float(reaction["tone3"]) * 0.5
	# The register's own value also feeds purpose (the register strengthens it).
	gain += register_value(g) * 0.3
	purpose += gain

	var ascended := false
	while purpose >= threshold() and not is_maxed():
		purpose -= threshold()
		index += 1
		ascensions += 1
		history.append(REGISTERS[index])
		# Reset purpose momentum on ascent (the new register starts quiet).
		purpose = 0.0
		ascended = true
	return ascended


func to_dict() -> Dictionary:
	return {
		"index": index,
		"current": current(),
		"next": next(),
		"purpose": purpose,
		"threshold": threshold(),
		"ascensions": ascensions,
		"maxed": is_maxed(),
		"history": history.duplicate(),
	}