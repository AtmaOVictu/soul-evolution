shader_type canvas_item;

// Soul Evolution — Void Background
// Polarity: 0.0 = dark void (white/creation soul), 1.0 = light void (black/destruction soul)
uniform float polarity : hint_range(0.0, 1.0, 0.01) = 0.0;
// Desaturation: 0.0 = full color, 1.0 = full grey (death accumulates here)
uniform float desaturation : hint_range(0.0, 1.0, 0.01) = 0.0;

void fragment() {
	vec2 uv = UV;
	float dist = distance(uv, vec2(0.5));

	// Vignette: edges darker than center
	float vignette = 1.0 - smoothstep(0.15, 0.9, dist);

	// Base brightness: dark for white soul, light for black soul
	float base = mix(0.04, 0.88, polarity);

	// Subtle animated breathing — the void is alive
	float wave1 = sin(uv.x * 14.0 + TIME * 0.4) * 0.018;
	float wave2 = cos(uv.y * 11.0 + TIME * 0.3) * 0.015;
	float wave3 = sin((uv.x + uv.y) * 8.0 + TIME * 0.25) * 0.010;

	// Death pulse — when death accumulates, the void throbbs slower
	float death_pulse = sin(TIME * 0.2 * (1.0 - desaturation * 0.7)) * 0.008 * (1.0 + desaturation);

	float v = base * vignette + wave1 + wave2 + wave3 + death_pulse;

	// Desaturation: death makes the world grey
	v = mix(v, 0.5, desaturation * 0.3);

	v = clamp(v, 0.0, 1.0);

	COLOR = vec4(vec3(v), 1.0);
}
