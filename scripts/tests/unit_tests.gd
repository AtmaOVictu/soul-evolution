extends SceneTree
## Standalone unit tests for pure-logic classes — no game scene needed.
## These test SoulGenome/SoulVault/SoulStream/HexGrid math in isolation,
## fast (no 15s battle wait like the --auto integration smoke test).
##
## Run: Godot_v4.7.1-stable_win64_console.exe --headless --script res://scripts/tests/unit_tests.gd

const SoulGenomeScript := preload("res://scripts/soul_genome.gd")
const HexGridScript := preload("res://scripts/hex_grid.gd")
const SoulVaultScript := preload("res://scripts/soul_vault.gd")
const SoulStreamScript := preload("res://scripts/soul_stream.gd")

var _pass := 0
var _fail := 0
var _failures: Array[String] = []


func _initialize() -> void:
	print("=== UNIT TESTS ===")
	_test_genome_ability_ranges()
	_test_genome_psi_bounds()
	_test_genome_pools()
	_test_genome_set_ego()
	_test_genome_upgrade_spend()
	_test_genome_modifications()
	_test_hex_world_roundtrip()
	_test_hex_terrain_bounds()
	_test_hex_dark_zones()
	_test_vault_success()
	_test_vault_coin_guard()
	_test_vault_perception_does_not_change_odds()
	_test_soul_stream_incarnation()
	_report()
	quit()


func _assert(cond: bool, name: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		_failures.append(name)
		print("  FAIL: ", name)


func _report() -> void:
	print("=== RESULTS: %d passed, %d failed ===" % [_pass, _fail])
	if _fail > 0:
		for f in _failures:
			print("  - ", f)


# ===================================================================
# SoulGenome
# ===================================================================

func _test_genome_ability_ranges() -> void:
	for i in 20:
		var g = SoulGenomeScript.create_random(i, 0)
		for stat in ["STR", "STA", "INT", "WIS", "CHA", "DEX", "LUK"]:
			var v: int = g.get(stat)
			_assert(v >= 1 and v <= 100, "genome.%s in [1,100] (got %d, seed %d)" % [stat, v, i])


func _test_genome_psi_bounds() -> void:
	for i in 20:
		var g = SoulGenomeScript.create_random(i, 0)
		_assert(g.psi >= 0.0 and g.psi <= 1.0, "genome.psi in [0,1] (got %.3f, seed %d)" % [g.psi, i])


func _test_genome_pools() -> void:
	var g = SoulGenomeScript.create_random(1, 0)
	_assert(g.capacity_max == g.STA * 10, "capacity_max derives from STA")
	_assert(g.capacity_current == g.capacity_max, "capacity_current starts full")


func _test_genome_set_ego() -> void:
	var g = SoulGenomeScript.create_random(1, 0)
	g.set_ego(1.0)
	_assert(g.ego == 1.0, "set_ego stores the value")
	_assert(g.capacity_current == g.capacity_max, "set_ego refills capacity")
	g.set_ego(-5.0)
	_assert(g.ego == 0.0, "set_ego clamps below 0")
	g.set_ego(5.0)
	_assert(g.ego == 1.0, "set_ego clamps above 1")


func _test_genome_upgrade_spend() -> void:
	var g = SoulGenomeScript.create_random(1, 0)
	g.upgrade_points = 2
	var ok1: bool = g.spend_upgrade("speed")
	_assert(ok1 == true, "spend_upgrade succeeds on a valid category")
	_assert(g.speed_level == 1, "spend_upgrade increments the level")
	_assert(g.upgrade_points == 1, "spend_upgrade deducts a point on success")
	var ok2: bool = g.spend_upgrade("not_a_real_category")
	_assert(ok2 == false, "spend_upgrade fails on an invalid category")
	_assert(g.upgrade_points == 1, "spend_upgrade does not deduct on failure")
	g.upgrade_points = 0
	var ok3: bool = g.spend_upgrade("speed")
	_assert(ok3 == false, "spend_upgrade fails with zero points")


func _test_genome_modifications() -> void:
	var g = SoulGenomeScript.create_random(1, 0)
	_assert(g.has_curse() == false, "fresh genome has no curse")
	_assert(g.has_blessing() == false, "fresh genome has no blessing")
	var str_before: int = g.STR
	g.add_modification("blessing", "test-boon", "STR", 10.0)
	_assert(g.has_blessing() == true, "add_modification(blessing) is detected by has_blessing")
	_assert(g.STR == clampi(str_before + 10, 1, 100), "add_modification applies its stat delta")
	_assert(g.count_modifications("blessing") == 1, "count_modifications counts the added type")
	g.remove_modification("test-boon")
	_assert(g.modifications.size() == 0, "remove_modification removes by name")


# ===================================================================
# HexGrid
# ===================================================================

func _test_hex_world_roundtrip() -> void:
	var hg = HexGridScript.new()
	# Exact for points at hex centers — world_to_hex(hex_to_world(c,r)) == (c,r).
	for cell in [Vector2i(0, 0), Vector2i(5, 5), Vector2i(3, 9), Vector2i(12, 1)]:
		var world_pos: Vector2 = hg.hex_to_world(cell.x, cell.y)
		var back: Vector2i = hg.world_to_hex(world_pos)
		_assert(back == cell, "hex_to_world -> world_to_hex roundtrips for %s (got %s)" % [cell, back])
	hg.free()


func _test_hex_terrain_bounds() -> void:
	var hg = HexGridScript.new()
	hg._generate_terrain()
	_assert(hg.get_terrain(-1, -1) == hg.T_WALL, "get_terrain out-of-bounds (negative) returns T_WALL")
	_assert(hg.get_terrain(9999, 9999) == hg.T_WALL, "get_terrain out-of-bounds (large) returns T_WALL")
	_assert(hg.grid_cols > 0 and hg.grid_rows > 0, "terrain grid has positive dimensions")
	_assert(hg.terrain.size() == hg.grid_cols * hg.grid_rows, "terrain array size matches grid_cols*grid_rows")
	hg.free()


func _test_hex_dark_zones() -> void:
	var hg = HexGridScript.new()
	hg._generate_terrain()
	_assert(hg.dark_zone_positions.size() > 0, "dark_zone_positions is populated after terrain generation")
	var nearest: Vector2 = hg.get_nearest_dark_zone(Vector2(0, 0))
	_assert(nearest != Vector2.INF, "get_nearest_dark_zone finds a zone when they exist")
	hg.free()
	var hg2 = HexGridScript.new()
	_assert(hg2.get_nearest_dark_zone(Vector2(0, 0)) == Vector2.INF, "get_nearest_dark_zone returns INF with no zones (ungenerated grid)")
	hg2.free()


# ===================================================================
# SoulVault
# ===================================================================

func _test_vault_success() -> void:
	var v = SoulVaultScript.new()
	for i in 10:
		var r: Dictionary = v.draw_from_machine(1, 5, 100, 100)  # max luck/perception
		_assert(r["ok"] == true, "draw_from_machine succeeds with enough coins (trial %d)" % i)
		_assert(r["quality"] in ["good", "common", "poor"], "quality is a valid category (trial %d, got %s)" % [i, r.get("quality")])
	_assert(v.souls.size() == 10, "each successful draw is recorded in the vault")


func _test_vault_coin_guard() -> void:
	var v = SoulVaultScript.new()
	var r: Dictionary = v.draw_from_machine(5, 1, 50, 50)
	_assert(r["ok"] == false, "draw_from_machine refuses when coins_held < coin_value")
	_assert(r.get("reason") == "no coin", "refusal reports reason 'no coin'")
	_assert(v.souls.size() == 0, "a refused draw is not recorded")


func _test_vault_perception_does_not_change_odds() -> void:
	# The correctness property the whole luck/perception split depends on:
	# perception changes what the player is TOLD (perceived_chance), never
	# the actual roll. Same luck must give the same real chance regardless
	# of perception, while perceived_chance itself should visibly differ.
	var v_blind = SoulVaultScript.new()
	var v_clear = SoulVaultScript.new()
	var r_blind: Dictionary = v_blind.draw_from_machine(1, 5, 70, 0)
	var r_clear: Dictionary = v_clear.draw_from_machine(1, 5, 70, 100)
	var expected_good_chance := 0.05 + 70.0 / 100.0 * 0.90
	_assert(absf(r_blind["perceived_chance"] - expected_good_chance) > 0.01,
		"perception=0 distorts perceived_chance away from the real good_chance")
	_assert(absf(r_clear["perceived_chance"] - expected_good_chance) < 0.0001,
		"perception=100 shows the real good_chance exactly")


# ===================================================================
# SoulStream
# ===================================================================

func _test_soul_stream_incarnation() -> void:
	var stream = SoulStreamScript.new()
	var g1 = SoulGenomeScript.create_random(1, 0)
	stream.incarnate(g1)
	_assert(stream.incarnations == 1, "first incarnate() increments the counter")
	_assert(stream.current_body == g1, "current_body is set to the incarnated genome")
	_assert(stream.memory_fragments.size() == 0, "no memory fragment yet — nothing has died")
	g1.capacity_current = 0  # simulate death
	var g2 = SoulGenomeScript.create_random(2, 0)
	stream.incarnate(g2)
	_assert(stream.incarnations == 2, "second incarnate() increments the counter")
	_assert(stream.memory_fragments.size() == 1, "a dead current_body writes a memory fragment on the next incarnate")
	_assert(stream.memory_fragments[0]["body_id"] == g1.soul_id, "the memory fragment records the body that died, not the new one")
