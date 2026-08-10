extends Node2D
## Neutron remnant — the third state. What an annihilated soul becomes: not
## white, not black, a broken and inert fragment of what was a body. Physical
## wreckage, not a hidden counter — it blocks movement, degrades under fire,
## and yields dust when destroyed. A later annihilation nearby can crack it
## back open (see main.gd _check_annihilation) — reclaimed, not permanent.
##
## Deliberately its own system (own script, own state) rather than folded
## into the existing ColorRect obstacle arrays in main.gd — a neutron is a
## conceptually different thing from a destructible wall.

var hp: int = 4
var max_hp: int = 4
var radius: float = 22.0
var _shard_seed: int = 0


func _ready() -> void:
	_shard_seed = randi()
	queue_redraw()


func get_life_ratio() -> float:
	return float(hp) / float(max_hp) if max_hp > 0 else 0.0


## Returns true if this destroys the remnant.
func take_beam_damage(amount: int) -> bool:
	hp -= amount
	queue_redraw()
	return hp <= 0


func _draw() -> void:
	# Broken, split — not a sphere. A handful of jagged shard fragments held
	# loosely around a center point. Seeded so the shape is stable across
	# redraws (only changes when damaged), not re-randomized every frame.
	var rng := RandomNumberGenerator.new()
	rng.seed = _shard_seed
	var ratio := get_life_ratio()
	var base_col := Color(0.24, 0.23, 0.26, 0.85).lerp(Color(0.07, 0.07, 0.09, 0.85), 1.0 - ratio)
	var edge_col := Color(0.4, 0.36, 0.46, 0.5)
	var shard_count := 5
	for i in shard_count:
		var ang: float = TAU * float(i) / float(shard_count) + rng.randf_range(-0.3, 0.3)
		var dist: float = radius * rng.randf_range(0.1, 0.5)
		var center := Vector2(cos(ang), sin(ang)) * dist
		var size: float = radius * rng.randf_range(0.3, 0.55)
		var sides := 5
		var points := PackedVector2Array()
		for s in sides:
			var sa: float = TAU * float(s) / float(sides) + rng.randf_range(-0.4, 0.4)
			points.append(center + Vector2(cos(sa), sin(sa)) * size * rng.randf_range(0.55, 1.0))
		draw_colored_polygon(points, base_col)
		var outline := points.duplicate()
		outline.append(points[0])
		draw_polyline(outline, edge_col, 1.0, false)
