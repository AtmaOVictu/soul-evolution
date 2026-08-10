extends Node2D
## Hex grid — terrain for tactical combat.
## Each hex is a terrain type that affects visibility and cover.

var hex_size: float = 40.0
var terrain: Array = []
var grid_cols: int = 0
var grid_rows: int = 0
var _time: float = 0.0
var dark_zone_positions: Array = []  # Vector2, world-space centers of T_DARK hexes

const ARENA_SIZE := Vector2(3440.0, 1440.0)
const T_OPEN := 0
const T_WALL := 1
const T_DARK := 2
const T_LIGHT := 3
const T_COVER := 4

# The lattice itself is rendered by shaders/hex_grid.gdshader — real per-pixel
# GPU math (a hex SDF) instead of ~1100 CPU-drawn polygons redrawn every
# frame. Terrain is static after generation, so the lookup texture is baked
# once; only world_color_ratio/color_balance update per frame.
var hex_lattice_rect: ColorRect = null
var hex_shader_material: ShaderMaterial = null


func _ready() -> void:
	_generate_terrain()
	_build_hex_lattice_shader()
	queue_redraw()


func _build_hex_lattice_shader() -> void:
	var img := Image.create(grid_cols, grid_rows, false, Image.FORMAT_RF)
	for r in grid_rows:
		for c in grid_cols:
			img.set_pixel(c, r, Color(float(get_terrain(c, r)), 0.0, 0.0, 1.0))
	var tex := ImageTexture.create_from_image(img)

	hex_shader_material = ShaderMaterial.new()
	hex_shader_material.shader = preload("res://shaders/hex_grid.gdshader")
	hex_shader_material.set_shader_parameter("terrain_tex", tex)
	hex_shader_material.set_shader_parameter("grid_size", Vector2(grid_cols, grid_rows))
	hex_shader_material.set_shader_parameter("hex_size", hex_size)
	hex_shader_material.set_shader_parameter("arena_size", ARENA_SIZE)
	if ResourceLoader.exists("res://assets/glass_hex_tile.png"):
		hex_shader_material.set_shader_parameter("glass_tex", load("res://assets/glass_hex_tile.png"))

	# Sacred-geometry-derived shader constants (canon/01b-sacred-geometry.md) —
	# computed here since GLSL can't preload scripts/sacred_geometry.gd.
	var sg := preload("res://scripts/sacred_geometry.gd")
	hex_shader_material.set_shader_parameter("border_w", sg.ladder(-1.0) * hex_size * 0.1)
	hex_shader_material.set_shader_parameter("hex_fill_frac", sg.ladder(0.0))
	hex_shader_material.set_shader_parameter("glass_uv_scale", sg.ladder(1.5))
	hex_shader_material.set_shader_parameter("wave_speed", sg.ladder(-1.0))
	hex_shader_material.set_shader_parameter("tint_blend", sg.ladder(-2.0))
	hex_shader_material.set_shader_parameter("glass_blend", sg.ladder(-2.0))
	hex_shader_material.set_shader_parameter("hue_skew_blend", sg.ladder(-1.5))
	hex_shader_material.set_shader_parameter("hexagram_angle", sg.HEXAGRAM_ANGLE)

	hex_lattice_rect = ColorRect.new()
	hex_lattice_rect.name = "HexLattice"
	hex_lattice_rect.position = Vector2.ZERO
	hex_lattice_rect.size = ARENA_SIZE
	hex_lattice_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hex_lattice_rect.material = hex_shader_material
	hex_lattice_rect.show_behind_parent = true
	add_child(hex_lattice_rect)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()  # only _draw_effects() now — the lattice is the shader above
	if not hex_shader_material:
		return
	var parent := get_parent()
	var color_ratio := 0.0
	var balance := 0.0
	if parent and "world_color" in parent and "army_size" in parent:
		var max_color: float = float(parent.army_size) * 2.0
		color_ratio = clampf(float(parent.world_color) / maxf(max_color, 1.0), 0.0, 1.0)
	if parent and "color_balance" in parent:
		balance = parent.color_balance
	hex_shader_material.set_shader_parameter("world_color_ratio", color_ratio)
	hex_shader_material.set_shader_parameter("color_balance", balance)


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
	var arena_w: float = ARENA_SIZE.x
	var arena_h: float = ARENA_SIZE.y
	grid_cols = int(ceil(arena_w / col_sp)) + 1
	grid_rows = int(ceil(arena_h / row_sp)) + 1
	terrain.resize(grid_cols * grid_rows)
	terrain.fill(T_WALL)
	# Maze generation (recursive backtracking)
	_maze_carve(1, 1)
	# Add rooms at key locations — spread across the wide (ultrawide) arena:
	# left cluster, center cluster, right cluster.
	_carve_room(4, 2, 2)
	_carve_room(10, 2, 2)
	_carve_room(7, 4, 2)
	_carve_room(4, 6, 2)
	_carve_room(10, 6, 2)
	_carve_room(28, 3, 3)
	_carve_room(28, 8, 3)
	_carve_room(46, 2, 2)
	_carve_room(52, 4, 2)
	_carve_room(46, 7, 2)
	_carve_room(52, 9, 2)
	# Ensure corridors connect rooms (left cluster)
	_carve_corridor(4, 2, 7, 4)
	_carve_corridor(7, 4, 10, 2)
	_carve_corridor(7, 4, 4, 6)
	_carve_corridor(7, 4, 10, 6)
	_carve_corridor(4, 2, 4, 6)
	_carve_corridor(10, 2, 10, 6)
	# Center + right connectors
	_carve_corridor(10, 4, 28, 4)
	_carve_corridor(28, 3, 28, 8)
	_carve_corridor(28, 4, 46, 4)
	_carve_corridor(46, 2, 52, 4)
	_carve_corridor(52, 4, 52, 9)
	_carve_corridor(46, 2, 46, 7)
	# Dark zones (black ambush spots) — spread left/center/right
	for p in [Vector2i(2,3), Vector2i(2,4), Vector2i(9,3), Vector2i(9,4), Vector2i(1,5), Vector2i(11,5),
			Vector2i(26,3), Vector2i(30,6), Vector2i(44,2), Vector2i(44,5), Vector2i(50,6), Vector2i(54,3)]:
		_set_t(p.x, p.y, T_DARK)
		dark_zone_positions.append(hex_to_world(p.x, p.y))
	# Light zones (white advantage) — spread across the width
	for p in [Vector2i(5,2), Vector2i(6,2), Vector2i(5,6), Vector2i(6,6), Vector2i(4,1), Vector2i(9,1),
			Vector2i(27,2), Vector2i(29,7), Vector2i(45,3), Vector2i(51,2), Vector2i(53,8), Vector2i(47,1)]:
		_set_t(p.x, p.y, T_LIGHT)
	# Cover (tactical positions) — across left/center/right
	for p in [Vector2i(5,3), Vector2i(4,4), Vector2i(6,5), Vector2i(3,4), Vector2i(9,4), Vector2i(5,7),
			Vector2i(27,4), Vector2i(29,5), Vector2i(45,4), Vector2i(47,5), Vector2i(51,4), Vector2i(53,6)]:
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
	# The lattice itself is the shader (shaders/hex_grid.gdshader, applied to
	# hex_lattice_rect in _build_hex_lattice_shader). Only the transient
	# effects (annihilation flashes, death bursts) are still CPU-drawn — few
	# in number, short-lived, don't need per-pixel math.
	_draw_effects()


func _draw_effects() -> void:
	var parent := get_parent()
	if not parent or not "_effects" in parent:
		return
	var effects: Array = parent._effects
	for e in effects:
		var col: Color = e["color"]
		col.a = e["alpha"]
		draw_circle(e["pos"], e["radius"], col)