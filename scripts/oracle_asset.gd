class_name OracleAsset
extends RefCounted
## The Oracle of the Many Windows — an interactive, upgradeable asset.
## It is a *fated reading* machine: you spend dust to consult it, and it returns
## a seeded, resonant reading (a register-hint, a governing operator/sigil, a
## reaction-valence, and a canon phrase). Over many readings it accumulates a
## FATE-DISTRIBUTION — the insight it reveals.
##
## It is UPGRADEABLE: spending dust raises its sight-tier, which unlocks richer
## readings (more phrases, finer odds resolution, deeper resonance insight).
##
## Built coherently from the existing systems/art:
##   - the ascending chain (PurposeLadder REGISTERS)
##   - the operator sigils (ReactionEngine OPERATORS -> assets/sigil_*.png)
##   - the reaction verdicts (DA / ∅ / NE)
##   - the canon phrases (the word-protocol / mythos lines)
##   - the dust economy (the game's currency)
##   - a seeded RandomNumberGenerator (reproducible fates)

const OPERATORS := ["∇", "¬", "∆", "✡", "τ", "σ"]
const VERDICTS := ["DA", "∅", "NE"]

var tier: int = 1
var tier_max: int = 5
var consultations: int = 0
var dust_spent: int = 0

# Fate-distribution (the insight): how many times each operator ruled a reading.
var operator_fate := {"∇": 0, "¬": 0, "∆": 0, "✡": 0, "τ": 0, "σ": 0}
var verdict_fate := {"DA": 0, "∅": 0, "NE": 0}

var _rng := RandomNumberGenerator.new()


## Coherent canon phrases, drawn from the word-protocol / mythos / ∅-language.
const PHRASES := [
	"a cut is a bridge, not a wall.",
	"speech is no, and therefore possibility.",
	"one cannot exist without the other.",
	"silence is the first matrix of truth.",
	"every truth carries its hidden opposite.",
	"the world is grey not because color is absent, but because neither side can see.",
	"the soul speaks what it is.",
	"you are the fracture that sings.",
	"resonance does not require presence, but sensitivity.",
	"fear you found a system; love, a mistake.",
	"when you were finally honest, you spoke in the future tense.",
	"the empty word has no pulse.",
]


func set_seed(seed: int) -> void:
	_rng.seed = seed


## Cost to consult at the current tier (rises with tier — a deeper reading
## asks for more).
func consult_cost() -> int:
	return tier * 5


## Cost to upgrade to the next tier.
func upgrade_cost() -> int:
	return 10 + tier * 10


func is_maxed() -> bool:
	return tier >= tier_max


## Consult the oracle: spend `dust_held` (returns false if unaffordable) and
## get a seeded, tier-scaled fated reading.
func consult(dust_held: int) -> Dictionary:
	# The oracle's "sight" grows with tier — higher tiers read finer outcomes.
	if dust_held < consult_cost():
		return {"ok": false, "reason": "no dust"}
	dust_spent += consult_cost()
	consultations += 1

	# Governing operator — weighted by the soul's own fate-lean (an oracle
	# mirrors the reader). At higher tiers the mirror is clearer.
	var op := _weighted_operator()
	operator_fate[op] += 1

	# Reaction-valence through the same seeded stream.
	var verdict: String = VERDICTS[_rng.randi_range(0, VERDICTS.size() - 1)]
	verdict_fate[verdict] += 1

	# Register-hint from the ascending chain.
	var register: String = PurposeLadder.REGISTERS[_rng.randi_range(0, PurposeLadder.REGISTERS.size() - 1)]

	# Phrase — tier unlocks more phrases (deeper sight = richer readings).
	var phrase_pool: Array = PHRASES
	if tier < 3:
		phrase_pool = phrase_pool.slice(0, 6)
	var phrase: String = phrase_pool[_rng.randi_range(0, phrase_pool.size() - 1)]

	# Odds report — how clearly the oracle reveals its own bias (tier-scaled).
	var shown_bias := _dominant_operator()
	var clarity := minf(0.3 + float(tier) * 0.12, 1.0)

	return {
		"ok": true,
		"operator": op,
		"verdict": verdict,
		"register": register,
		"phrase": phrase,
		"sigil": "sigil_%s" % _op_name(op),
		"shown_bias": shown_bias,
		"clarity": clarity,
		"tier": tier,
	}


## Upgrade the oracle: spend dust to raise its sight-tier (unlocks richer
## readings). Returns true on success.
func upgrade(dust_held: int) -> bool:
	if is_maxed():
		return false
	if dust_held < upgrade_cost():
		return false
	dust_spent += upgrade_cost()
	tier += 1
	return true


## The operator that has ruled the most readings so far (the fate-lean).
func _dominant_operator() -> String:
	var best := OPERATORS[0]
	for op in OPERATORS:
		if operator_fate[op] > operator_fate[best]:
			best = op
	return best


## Weighted operator pick — the oracle leans toward the reader's fate-lean,
## but with noise (chance still surprises).
func _weighted_operator() -> String:
	var total := consultations + 4.0  # small prior so early readings aren't fixed
	var weights := {}
	var sum := 0.0
	for op in OPERATORS:
		# weight = prior + fate-lean share, plus tier makes the lean clearer
		var w: float = 1.0 + float(operator_fate[op]) * (0.5 + float(tier) * 0.2)
		weights[op] = w
		sum += w
	var roll := _rng.randf() * sum
	var acc := 0.0
	for op in OPERATORS:
		acc += weights[op]
		if roll <= acc:
			return op
	return OPERATORS[OPERATORS.size() - 1]


func _op_name(op: String) -> String:
	match op:
		"∇": return "div"
		"¬": return "neg"
		"∆": return "delta"
		"✡": return "trace"
		"τ": return "tau"
		"σ": return "sigma"
	return op


## The insight the oracle reveals: the dominant fate-lean, as a readable line.
func fate_insight() -> String:
	var op := _dominant_operator()
	var op_word := {
		"∇": "divergence", "¬": "the cut", "∆": "change", "✡": "trace",
		"τ": "the path", "σ": "discipline",
	}
	return "your fate leans on %s — %s rules your readings." % [op, op_word[op]]


func summary() -> String:
	return "Oracle tier %d · consulted %d · dust spent %d" % [tier, consultations, dust_spent]