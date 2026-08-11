class_name SkillTemplate
extends RefCounted
## A REUSABLE TEMPLATE for how a skill grows and evolves, tied to the real
## Godot mechanics. Any skill (starting with the white soul's laser) is an
## instance of this: it has BASE mechanics, a set of LEVELS (each costing dust
## and modifying the real mechanics), and EVOLUTIONS (at certain levels the
## skill changes behavior, not just numbers).
##
## The mechanics it drives are the actual fields the soul.gd beam uses:
##   damage, range, cooldown, life (the hit window).
## Evolutions are behavior flags the soul reads (pierce, split, homing, ...).

var name: String
var base_damage: float = 0.0
var base_range: float = 0.0
var base_cooldown: float = 0.0
var base_life: float = 0.0

# levels: [{level, cost, mods:{damage,range,cooldown,life}}]
var levels: Array = []
# evolutions: [{at_level, id, desc}] — behavior unlocked at a level.
var evolutions: Array = []

var current_level: int = 0


## Build a template from base mechanics + a level curve.
static func laser_template():
	var t := new()
	t.name = "laser"
	# Base = the current soul.gd beam defaults.
	t.base_damage = 10.0
	t.base_range = 300.0
	t.base_cooldown = 0.2
	t.base_life = 0.4
	# Levels: each raises the real mechanics. Cost = dust.
	t.levels = [
		{"level": 1, "cost": 0,  "mods": {"damage": 0.0,  "range": 0,   "cooldown": 0.0,  "life": 0.0}},
		{"level": 2, "cost": 10, "mods": {"damage": 3.0,  "range": 40,  "cooldown": -0.02, "life": 0.0}},
		{"level": 3, "cost": 20, "mods": {"damage": 6.0,  "range": 80,  "cooldown": -0.03, "life": 0.05}},
		{"level": 4, "cost": 35, "mods": {"damage": 10.0, "range": 120, "cooldown": -0.04, "life": 0.05}},
		{"level": 5, "cost": 50, "mods": {"damage": 15.0, "range": 160, "cooldown": -0.05, "life": 0.1}},
	]
	t.evolutions = [
		{"at_level": 3, "id": "pierce", "desc": "the beam passes through the first target."},
		{"at_level": 4, "id": "split",  "desc": "the beam splits into two at half range."},
	]
	return t


func upgrade_cost() -> int:
	if current_level >= levels.size() - 1:
		return -1
	return levels[current_level + 1]["cost"]


func is_maxed() -> bool:
	return current_level >= levels.size() - 1


## Try to spend dust to advance one level. Returns true on success.
func upgrade(dust_held: int) -> bool:
	if is_maxed():
		return false
	var cost := upgrade_cost()
	if dust_held < cost:
		return false
	current_level += 1
	return true


## The current total mechanics (base + all level mods), as the real fields
## soul.gd uses.
func compute_mechanics() -> Dictionary:
	var dmg := base_damage
	var rng := base_range
	var cd := base_cooldown
	var life := base_life
	for i in range(1, current_level + 1):
		var lv: Dictionary = levels[i]
		var m: Dictionary = lv["mods"]
		dmg += m.get("damage", 0.0)
		rng += m.get("range", 0.0)
		cd += m.get("cooldown", 0.0)
		life += m.get("life", 0.0)
	return {
		"damage": dmg,
		"range": rng,
		"cooldown": maxf(cd, 0.05),
		"life": maxf(life, 0.1),
	}


## The evolutions currently unlocked (by level).
func unlocked_evolutions() -> Array[String]:
	var out: Array[String] = []
	for ev in evolutions:
		if current_level >= ev["at_level"]:
			out.append(ev["id"])
	return out


func has_evolution(id: String) -> bool:
	return unlocked_evolutions().has(id)


func to_dict() -> Dictionary:
	return {
		"name": name,
		"level": current_level,
		"max": levels.size() - 1,
		"upgrade_cost": upgrade_cost(),
		"maxed": is_maxed(),
		"mechanics": compute_mechanics(),
		"evolutions": unlocked_evolutions(),
	}