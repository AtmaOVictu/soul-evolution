extends Node2D
## Hex grid — terrain for tactical combat.
## Each hex is a terrain type that affects visibility and cover.

var hex_size: float = 40.0
var terrain: Array = []
var grid_cols: int = 0
var grid_rows: int = 0
var _time: float = 0.0
var dark_zone_positions: Array = []  # Vector2, world-space centers of T_DARK hexes

const T_OPEN := 0
const T_WALL := 1
const T_DARK := 2
const T_LIGHT := 3
const T_COVER := 4


func _ready() -> void:
	_generate_terrain()
	queue_redraw()


func _process(delta: float) -> void:
	# Redraw continuously — the grid ripples like a liquid (see _draw_hex_grid).
	_time += delta
	queue_redraw()


## Nearest-hex lookup for a world position — approximate (nearest center,
## not point-in-polygon), good enough for gameplay checks like concealment.
func world_to_hex(pos: Vector2) -> Vector2i:
	var hex_h: float = hex_size * sqrt(3.0)
	var col_sp: float = hex_size * 1.5
	var row_sp: float = hex_h
	var c: int = int(roundf((pos.x - hex_size) / col_sp))
	var y_offset: float = hex_h * 0.5 if c % 2 == 1 else 0.0
	var r: int = int(roundf((pos.y - y_offset - hex_h * 0.5) / row_sp))
	return Vector2i(c, r)


func get_terrain_at(pos: Vector2) -> int:
	var hc := world_to_hex(pos)
	return get_terrain(hc.x, hc.y)


func hex_to_world(c: int, r: int) -> Vector2:
	var hex_h: float = hex_size * sqrt(3.0)
	var col_sp: float = hex_size * 1.5
	var row_sp: float = hex_h
	return Vector2(
		float(c) * col_sp + hex_size,
		float(r) * row_sp + (hex_h * 0.5 if c % 2 == 1 else 0.0) + hex_h * 0.5
	)


## Nearest T_DARK hex center to a world position, or Vector2.INF if none exist.
func get_nearest_dark_zone(pos: Vector2) -> Vector2:
	if dark_zone_positions.is_empty():
		return Vector2.INF
	var best: Vector2 = dark_zone_positions[0]
	var best_dist: float = pos.distance_to(best)
	for p in dark_zone_positions:
		var d: float = pos.distance_to(p)
		if d < best_dist:
			best_dist = d
			best = p
	return best


func _generate_terrain() -> void:
	var hex_h: float = hex_size * sqrt(3.0)
	var col_sp: float = hex_size * 1.5
	var row_sp: float = hex_h
	var arena_w: float = 2400.0
	var arena_h: float = 1800.0
	grid_cols = int(ceil(arena_w / col_sp)) + 1
	grid_rows = int(ceil(arena_h / row_sp)) + 1
	terrain.resize(grid_cols * grid_rows)
	terrain.fill(T_WALL)
	# Maze generation (recursive backtracking)
	_maze_carve(1, 1)
	# Add rooms at key locations
	_carve_room(3, 2, 2)
	_carve_room(8, 2, 2)
	_carve_room(5, 4, 2)
	_carve_room(3, 6, 2)
	_carve_room(8, 6, 2)
	# Ensure corridors connect rooms
	_carve_corridor(3, 2, 5, 4)
	_carve_corridor(5, 4, 8, 2)
	_carve_corridor(5, 4, 3, 6)
	_carve_corridor(5, 4, 8, 6)
	_carve_corridor(3, 2, 3, 6)
	_carve_corridor(8, 2, 8, 6)
	# Dark zones (black ambush spots)
	for p in [Vector2i(2,3), Vector2i(2,4), Vector2i(7,3), Vector2i(7,4), Vector2i(1,5), Vector2i(9,5)]:
		_set_t(p.x, p.y, T_DARK)
		dark_zone_positions.append(hex_to_world(p.x, p.y))
	# Light zones (white advantage)
	for p in [Vector2i(5,2), Vector2i(6,2), Vector2i(5,6), Vector2i(6,6), Vector2i(4,1), Vector2i(7,1)]:
		_set_t(p.x, p.y, T_LIGHT)
	# Cover (tactical positions)
	for p in [Vector2i(5,3), Vector2i(4,4), Vector2i(6,5), Vector2i(3,4), Vector2i(7,4), Vector2i(5,7)]:
		_set_t(p.x, p.y, T_COVER)
	# Ensure walls at edges
	for c in grid_cols:
		_set_t(c, 0, T_WALL)
		_set_t(c, grid_rows - 1, T_WALL)
	for r in grid_rows:
		_set_t(0, r, T_WALL)
		_set_t(grid_cols - 1, r, T_WALL)


func _maze_carve(start_c: int, start_r: int) -> void:
	# Recursive backtracking maze on hex grid
	var stack: Array = [Vector2i(start_c, start_r)]
	_set_t(start_c, start_r, T_OPEN)
	var visited: Dictionary = {}
	visited[Vector2i(start_c, start_r)] = true
	var dirs := [Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2),
				 Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]
	while stack.size() > 0:
		var current: Vector2i = stack.back()
		var neighbors: Array = []
		for d in dirs:
			var nx: int = current.x + d.x
			var ny: int = current.y + d.y
			var n := Vector2i(nx, ny)
			if nx > 0 and nx < grid_cols - 1 and ny > 0 and ny < grid_rows - 1:
				if not visited.has(n):
					neighbors.append(n)
		if neighbors.size() > 0:
			var next: Vector2i = neighbors[randi() % neighbors.size()]
			# Carve wall between current and next
			var mx: int = (current.x + next.x) / 2
			var my: int = (current.y + next.y) / 2
			_set_t(mx, my, T_OPEN)
			_set_t(next.x, next.y, T_OPEN)
			visited[next] = true
			stack.append(next)
		else:
			stack.pop_back()


func _carve_room(cx: int, cy: int, radius: int) -> void:
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			if dx * dx + dy * dy <= radius * radius:
				_set_t(cx + dx, cy + dy, T_OPEN)


func _carve_corridor(x1: int, y1: int, x2: int, y2: int) -> void:
	var steps := maxi(absi(x2 - x1), absi(y2 - y1)) + 1
	for i in steps:
		var t: float = float(i) / float(maxi(steps - 1, 1))
		var c: int = int(roundf(lerp(float(x1), float(x2), t)))
		var r: int = int(roundf(lerp(float(y1), float(y2), t)))
		_set_t(c, r, T_OPEN)
		if c + 1 < grid_cols:
			_set_t(c + 1, r, T_OPEN)


func _set_t(c: int, r: int, type: int) -> void:
	if c >= 0 and c < grid_cols and r >= 0 and r < grid_rows:
		terrain[r * grid_cols + c] = type


func get_terrain(c: int, r: int) -> int:
	if c >= 0 and c < grid_cols and r >= 0 and r < grid_rows:
		return terrain[r * grid_cols + c]
	return T_WALL


func _draw() -> void:
	_draw_hex_grid()
	_draw_effects()


func _draw_hex_grid() -> void:
	var hex_h: float = hex_size * sqrt(3.0)
	var col_sp: float = hex_size * 1.5
	var row_sp: float = hex_h
	# How much color has entered the world through annihilation (main.gd) —
	# the grid's ripple carries that color instead of staying purely decorative.
	var color_ratio := 0.0
	var balance := 0.0
	var parent := get_parent()
	if parent and "world_color" in parent and "army_size" in parent:
		var max_color: float = float(parent.army_size) * 2.0
		color_ratio = clampf(float(parent.world_color) / maxf(max_color, 1.0), 0.0, 1.0)
	if parent and "color_balance" in parent:
		balance = parent.color_balance
	for c in grid_cols:
		for r in grid_rows:
			var center := Vector2(
				float(c) * col_sp + hex_size,
				float(r) * row_sp + (hex_h * 0.5 if c % 2 == 1 else 0.0) + hex_h * 0.5
			)
			var points := PackedVector2Array()
			for i in 6:
				var angle: float = TAU * float(i) / 6.0
				points.append(center + Vector2(cos(angle), sin(angle)) * hex_size * 0.92)
			var t: int = get_terrain(c, r)
			var fill_col: Color
			var line_col: Color
			match t:
				T_OPEN:
					fill_col = Color(0.05, 0.05, 0.08, 0.12)
					line_col = Color(0.1, 0.1, 0.15, 0.18)
				T_WALL:
					fill_col = Color(0.15, 0.15, 0.2, 0.55)
					line_col = Color(0.25, 0.25, 0.3, 0.45)
				T_DARK:
					fill_col = Color(0.02, 0.02, 0.04, 0.3)
					line_col = Color(0.06, 0.06, 0.1, 0.25)
				T_LIGHT:
					fill_col = Color(0.12, 0.12, 0.1, 0.2)
					line_col = Color(0.2, 0.2, 0.18, 0.25)
				T_COVER:
					fill_col = Color(0.08, 0.08, 0.12, 0.3)
					line_col = Color(0.15, 0.15, 0.2, 0.35)
			# Liquid ripple: a slow travelling wave across the grid (position-phased,
			# not per-hex random) so it reads as one body of "fluid", not noise.
			var wave: float = sin(_time * 0.6 + float(c) * 0.35 + float(r) * 0.22) * 0.5 + 0.5
			fill_col.a *= 0.7 + wave * 0.5
			if color_ratio > 0.0:
				var tint := Color(0.5, 0.3, 0.6) if t != T_DARK else Color(0.4, 0.22, 0.5)
				# Balance skews the tint's hue, not its amount: white ahead
				# warms it, black ahead cools it. 0.0 (neutral middle) leaves
				# the base tint untouched.
				if balance > 0.0:
					tint = tint.lerp(Color(0.75, 0.55, 0.4), balance * 0.5)
				elif balance < 0.0:
					tint = tint.lerp(Color(0.3, 0.28, 0.55), -balance * 0.5)
				fill_col = fill_col.lerp(tint, color_ratio * wave * 0.4)
			draw_colored_polygon(points, fill_col)
			for i in 6:
				draw_line(points[i], points[(i + 1) % 6], line_col, 1.0, false)


func _draw_effects() -> void:
	var parent := get_parent()
	if not parent or not "_effects" in parent:
		return
	var effects: Array = parent._effects
	for e in effects:
		var col: Color = e["color"]
		col.a = e["alpha"]
		draw_circle(e["pos"], e["radius"], col)