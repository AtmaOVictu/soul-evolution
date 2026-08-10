extends RefCounted
class_name SoulVault

## The Soul Vault — the player's collection of souls.
## The Gumball Machine: an interactive tool where you spend a coin (treasure)
## and, under a LUCK roll, draw a soul-ball. PERCEPTION lets you read the odds
## before you spend.

var souls: Array[Dictionary] = []  # each is a soul record {id, genome, date_acq}


## The gumball machine — the core draw.
## Spends `coin_value` of treasure, uses `luck` to shape the result, and
## `perception` only to report the odds (does not change the roll).
## Returns the drawn soul record, or null if the player can't afford it.
func draw_from_machine(coin_value: int, coins_held: int, luck: int, perception: int) -> Dictionary:
	var result := {}
	if coins_held < coin_value:
		result["ok"] = false
		result["reason"] = "no coin"
		return result

	# --- PERCEPTION: read the odds (info only, does not change the roll) ---
	# Perception maps to how precisely the player can gauge their luck.
	var odds_known := 0.0
	if perception >= 80:
		odds_known = 1.0      # sees the exact chance
	elif perception >= 50:
		odds_known = 0.6      # rough sense
	elif perception >= 25:
		odds_known = 0.3      # vague
	else:
		odds_known = 0.1      # blind

	# Compute the "good soul" probability from luck (0..100 → 5%..95%)
	var good_chance := 0.05 + float(luck) / 100.0 * 0.90
	# What the player *perceives* they're getting (the odds they think they have)
	result["perceived_chance"] = good_chance * odds_known + 0.5 * (1.0 - odds_known)

	# --- LUCK: decide the result ---
	var roll := randf()
	var quality: String
	if roll < good_chance:
		quality = "good"
	elif roll < good_chance + (1.0 - good_chance) * 0.5:
		quality = "common"
	else:
		quality = "poor"

	# --- Build the soul-ball ---
	var g := SoulGenome.create_random(randi(), 0)
	# Quality affects the genome strength
	var mult := 1.0
	match quality:
		"good":
			mult = 1.2
		"common":
			mult = 1.0
		"poor":
			mult = 0.8
	# g._boost_genome(mult) exists upstream; apply modifiers
	if g.has_method("_boost_genome"):
		g._boost_genome(mult)

	result["ok"] = true
	result["quality"] = quality
	result["genome"] = g
	result["soul"] = _record_soul(g, quality)
	return result


func _record_soul(genome: RefCounted, quality: String) -> Dictionary:
	var rec := {
		"id": genome.soul_id,
		"quality": quality,
		"genome": genome,
		"date_acq": Time.get_datetime_string_from_system(),
	}
	souls.append(rec)
	return rec


## The vault's contents, summarized.
func get_vault_summary() -> String:
	if souls.is_empty():
		return "empty vault"
	return "%d souls held" % souls.size()