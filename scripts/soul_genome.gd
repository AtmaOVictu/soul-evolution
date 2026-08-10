extends RefCounted
class_name SoulGenome

## The soul's genome — its DNA in the plane.
## "Our version of the genome code" — the ontomathematical identity.

var soul_id: int = 0
var polarity: int = 0

# === GENOME (the plane's code) ===
var divergence: float = 0.0  # ∇
var negation: float = 0.0    # ¬
var delta: float = 0.0       # ∆
var trace: float = 0.0       # ✡ — feeds COLOR
var tau: float = 0.0         # τ
var sigma: float = 0.0       # σ
var carbon: float = 0.0      # C
var nitrogen: float = 0.0    # N
var phosphorus: float = 0.0  # P
var sulfur: float = 0.0      # S

# === ABILITIES (the phenotype) ===
var STR: int = 0
var STA: int = 0
var INT: int = 0
var WIS: int = 0
var CHA: int = 0
var LUK: int = 0
var DEX: int = 0

# === POOLS ===
var capacity_max: int = 0
var capacity_current: int = 0

# === EQUATION ===
var psi: float = 0.0

# === DEATH ===
var skulls: int = 0

# === STORY ===
var story_lines: PackedStringArray = PackedStringArray()
var fragments_touched: PackedStringArray = PackedStringArray()


static func create_random(id: int, pol: int) -> SoulGenome:
	var g := SoulGenome.new()
	g.soul_id = id
	g.polarity = pol
	g.divergence = randf()
	g.negation = randf()
	g.delta = randf()
	g.trace = randf()
	g.tau = randf()
	g.sigma = randf()
	g.carbon = randf()
	g.nitrogen = randf()
	g.phosphorus = randf()
	g.sulfur = randf()
	g._compute_abilities()
	g._compute_psi()
	g._compute_pools()
	g._compute_powers()
	g._compute_mithjos()
	return g


func _compute_abilities() -> void:
	STR = _score(sigma * 0.6 + delta * 0.4)
	STA = _score(sigma * 0.5 + carbon * 0.3 + negation * 0.2)
	INT = _score(divergence * 0.5 + carbon * 0.3 + nitrogen * 0.2)
	WIS = _score(negation * 0.4 + nitrogen * 0.3 + trace * 0.3)
	CHA = _score(trace * 0.5 + phosphorus * 0.3 + sulfur * 0.2)
	DEX = _score(tau * 0.5 + sulfur * 0.3 + divergence * 0.2)
	LUK = _score(0.3 + randf() * 0.7)


func _score(raw: float) -> int:
	return clampi(roundi(raw * 99.0 + 1.0), 1, 100)


func _compute_psi() -> void:
	# Ψ(x) = ∇∞(π(x)) ⊘ ¬¬(∴x) + ∆x ✡
	var pi_x := carbon * TAU
	var term1 := divergence * pi_x / TAU
	var term2 := negation * negation
	var term3 := delta * trace
	psi = clampf(term1 - term2 + term3, 0.0, 1.0)


func _compute_pools() -> void:
	capacity_max = STA * 10
	capacity_current = capacity_max


func get_reflex() -> int:
	return clampi(roundi((DEX + WIS) * 0.5), 1, 100)


func get_aura() -> int:
	return clampi(roundi((CHA + LUK) * 0.5), 1, 100)


func add_story(text: String) -> void:
	story_lines.append(text)


func add_fragment(text: String) -> void:
	fragments_touched.append(text)


func die() -> void:
	skulls += 1
	capacity_current = capacity_max


func get_symbol_text() -> String:
	return "○" if polarity == 0 else "●"


# =================================================================
# 8 POWERS (THE BOX)
# =================================================================

var pow_fizicna: float = 0.0
var pow_psiholoska: float = 0.0
var pow_custvena: float = 0.0
var pow_duhovna: float = 0.0
var pow_dusevna: float = 0.0
var pow_inteligenca: float = 0.0
var pow_gibljivost: float = 0.0
var pow_stamina_val: float = 0.0


func _compute_powers() -> void:
	pow_fizicna = trace * 0.6 + delta * 0.4
	pow_psiholoska = (negation + nitrogen) * 0.5
	pow_custvena = trace * 0.5 + phosphorus * 0.5
	pow_duhovna = (negation + nitrogen) * 0.3 + trace * 0.7
	pow_dusevna = carbon * 0.5 + nitrogen * 0.5
	pow_inteligenca = divergence * 0.5 + nitrogen * 0.3 + carbon * 0.2
	pow_gibljivost = tau * 0.5 + sulfur * 0.3 + divergence * 0.2
	pow_stamina_val = sigma * 0.5 + carbon * 0.3 + negation * 0.2


# =================================================================
# 4 MITHJOS DYNAMICS (Z · J · E · N)
# =================================================================

var mithjos_Z: float = 0.0  # zavest (consciousness)
var mithjos_J: float = 0.0  # ego-relacija
var mithjos_E: float = 0.0  # etični proces
var mithjos_N: float = 0.0  # paradoks / "Ne"


func _compute_mithjos() -> void:
	mithjos_Z = carbon * trace + divergence * 0.3
	mithjos_J = divergence * sulfur + 0.2
	mithjos_E = trace * phosphorus + 0.1
	mithjos_N = negation * delta + 0.1


# =================================================================
# COMBAT FACTORS (abilities + powers → damage, timing, speed)
# =================================================================

func get_laser_damage() -> float:
	return STR * 0.05 + pow_fizicna * 2.0 + laser_damage_level * 3.0


func get_laser_range() -> float:
	return 300.0 + INT * 2.0 + laser_range_level * 40.0


func get_devour_damage() -> float:
	return STR * 0.04 + pow_dusevna * 2.0 + devour_burst_level * 3.0


func get_devour_window() -> float:
	return 0.25 + WIS * 0.003 + devour_window_level * 0.05


func get_speed() -> float:
	return 220.0 + DEX * 1.5 + speed_level * 20.0


# =================================================================
# UPGRADES
# =================================================================

var upgrade_points: int = 0
var laser_damage_level: int = 0
var laser_range_level: int = 0
var devour_window_level: int = 0
var devour_burst_level: int = 0
var speed_level: int = 0


func spend_upgrade(category: String) -> bool:
	if upgrade_points <= 0:
		return false
	match category:
		"laser_dmg":
			laser_damage_level += 1
		"laser_rng":
			laser_range_level += 1
		"devour_win":
			devour_window_level += 1
		"devour_bst":
			devour_burst_level += 1
		"speed":
			speed_level += 1
		_:
			return false
	upgrade_points -= 1
	return true


func get_upgrade_name(category: String) -> String:
	match category:
		"laser_dmg": return "Laser Damage"
		"laser_rng": return "Laser Range"
		"devour_win": return "Devour Window"
		"devour_bst": return "Devour Burst"
		"speed": return "Speed"
		_: return ""


## Scale all genome values by a multiplier. Original soul gets 1.25, reserves get 0.75.
func _boost_genome(multiplier: float) -> void:
	divergence = clampf(divergence * multiplier, 0.0, 1.0)
	negation = clampf(negation * multiplier, 0.0, 1.0)
	delta = clampf(delta * multiplier, 0.0, 1.0)
	trace = clampf(trace * multiplier, 0.0, 1.0)
	tau = clampf(tau * multiplier, 0.0, 1.0)
	sigma = clampf(sigma * multiplier, 0.0, 1.0)
	carbon = clampf(carbon * multiplier, 0.0, 1.0)
	nitrogen = clampf(nitrogen * multiplier, 0.0, 1.0)
	phosphorus = clampf(phosphorus * multiplier, 0.0, 1.0)
	sulfur = clampf(sulfur * multiplier, 0.0, 1.0)
	_compute_abilities()
	_compute_psi()
	_compute_pools()
	_compute_powers()
	_compute_mithjos()
	capacity_current = capacity_max


## Ego: 0.0 = hollow (no player), 1.0 = original (born with ego).
## Affects all stats: effective = base × (1.0 + ego × 0.3)
var ego: float = 0.0


func set_ego(val: float) -> void:
	ego = clampf(val, 0.0, 1.0)
	# Ego boosts all genome values multiplicatively
	var ego_mult := 1.0 + ego * 0.3
	# Re-derive abilities with ego boost
	_compute_abilities()
	_compute_psi()
	_compute_pools()
	_compute_powers()
	_compute_mithjos()
	capacity_current = capacity_max
