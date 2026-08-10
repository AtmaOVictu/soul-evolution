shader_type canvas_item;

// Soul Evolution — Hex Grid (the fabric's lattice)
// Replaces ~1100 CPU-drawn polygons redrawn every frame with real per-pixel
// math: a hexagon signed-distance-field sampled once per screen pixel. Same
// visual logic as the old _draw_hex_grid() (terrain colors, the travelling
// ripple, the world_color/color_balance tint) — ported to GLSL, not redesigned.

uniform sampler2D terrain_tex : filter_nearest;
uniform vec2 grid_size = vec2(41.0, 27.0); // cols, rows
uniform float hex_size = 40.0;
uniform vec2 arena_size = vec2(2400.0, 1800.0);
uniform float world_color_ratio : hint_range(0.0, 1.0) = 0.0;
uniform float color_balance : hint_range(-1.0, 1.0) = 0.0; // -1 black .. 0 neutral .. +1 white

const float T_OPEN = 0.0;
const float T_WALL = 1.0;
const float T_DARK = 2.0;
const float T_LIGHT = 3.0;
const float T_COVER = 4.0;

// Same offset-column hex layout as hex_grid.gd's hex_to_world/world_to_hex.
vec2 hex_center(vec2 cell) {
	float col_sp = hex_size * 1.5;
	float row_h = hex_size * sqrt(3.0);
	float y_off = mod(cell.x, 2.0) >= 0.5 ? row_h * 0.5 : 0.0;
	return vec2(cell.x * col_sp + hex_size, cell.y * row_h + y_off + row_h * 0.5);
}

vec2 world_to_cell(vec2 world_pos) {
	float col_sp = hex_size * 1.5;
	float row_h = hex_size * sqrt(3.0);
	float c = floor((world_pos.x - hex_size) / col_sp + 0.5);
	float y_off = mod(c, 2.0) >= 0.5 ? row_h * 0.5 : 0.0;
	float r = floor((world_pos.y - y_off - row_h * 0.5) / row_h + 0.5);
	return vec2(c, r);
}

// Flat-top hexagon SDF: negative inside, 0 at the edge, positive outside.
float hex_sdf(vec2 p, float r) {
	vec2 q = abs(p);
	return max(dot(q, normalize(vec2(1.0, 1.7320508))), q.x) - r;
}

void fragment() {
	vec2 world_pos = UV * arena_size;
	vec2 cell = clamp(world_to_cell(world_pos), vec2(0.0), grid_size - vec2(1.0));
	vec2 local = world_pos - hex_center(cell);
	float d = hex_sdf(local, hex_size * 0.92);

	vec2 tex_uv = (cell + 0.5) / grid_size;
	float t = texture(terrain_tex, tex_uv).r;

	vec4 fill_col;
	vec4 line_col;
	if (t < 0.5) {
		fill_col = vec4(0.05, 0.05, 0.08, 0.12);
		line_col = vec4(0.1, 0.1, 0.15, 0.18);
	} else if (t < 1.5) {
		fill_col = vec4(0.15, 0.15, 0.2, 0.55);
		line_col = vec4(0.25, 0.25, 0.3, 0.45);
	} else if (t < 2.5) {
		fill_col = vec4(0.02, 0.02, 0.04, 0.3);
		line_col = vec4(0.06, 0.06, 0.1, 0.25);
	} else if (t < 3.5) {
		fill_col = vec4(0.12, 0.12, 0.1, 0.2);
		line_col = vec4(0.2, 0.2, 0.18, 0.25);
	} else {
		fill_col = vec4(0.08, 0.08, 0.12, 0.3);
		line_col = vec4(0.15, 0.15, 0.2, 0.35);
	}

	// Liquid ripple: a slow travelling wave across the grid (position-phased,
	// not per-pixel random) so it reads as one body of fluid, not noise.
	float wave = sin(TIME * 0.6 + cell.x * 0.35 + cell.y * 0.22) * 0.5 + 0.5;
	fill_col.a *= 0.7 + wave * 0.5;

	if (world_color_ratio > 0.0) {
		vec3 tint = (t > 1.5 && t < 2.5) ? vec3(0.4, 0.22, 0.5) : vec3(0.5, 0.3, 0.6);
		// Balance skews the tint's hue, not its amount: white ahead warms it,
		// black ahead cools it. 0.0 (neutral middle) leaves the tint alone.
		if (color_balance > 0.0) {
			tint = mix(tint, vec3(0.75, 0.55, 0.4), color_balance * 0.5);
		} else if (color_balance < 0.0) {
			tint = mix(tint, vec3(0.3, 0.28, 0.55), -color_balance * 0.5);
		}
		fill_col.rgb = mix(fill_col.rgb, tint, world_color_ratio * wave * 0.4);
	}

	vec4 col = fill_col;
	float border_w = 1.5;
	if (d > -border_w && d < 0.0) {
		col = mix(col, line_col, smoothstep(-border_w, 0.0, d));
	}
	if (d > 0.5) {
		col.a = 0.0;
	}

	COLOR = col;
}
