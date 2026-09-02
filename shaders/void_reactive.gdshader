// void_reactive.gdshader — The void responds to distinctions
//
// CL-033: Added presence_intensity uniform.
// When a presence appears, the void subtly brightens — not at the
// presence location, but everywhere. The whole void stirs.
// This creates a sense that the void is alive and aware of the presence.

shader_type canvas_item;

uniform float breath_speed = 0.3;
uniform float breath_depth = 0.08;
uniform vec4 void_color : source_color = vec4(0.02, 0.02, 0.04, 1.0);
uniform vec4 light_color : source_color = vec4(0.15, 0.2, 0.35, 1.0);
uniform int distinction_count = 0;
uniform float presence_intensity = 0.0;  // CL-033: 0..1, void stirs when presence appears

// Up to 16 distinction positions (screen-space, normalized 0..1)
uniform vec2 distinction_positions[16];
// Per-distinction clarity (0..1)
uniform float distinction_clarities[16];

void fragment() {
    vec4 col = void_color;
    
    // Base breathing
    float breath = sin(TIME * breath_speed) * breath_depth;
    col.rgb += vec3(breath * 0.3);
    
    // CL-033: Presence — the void stirs
    // A subtle global brightening, like the void holding its breath
    if (presence_intensity > 0.01) {
        float presence_pulse = sin(TIME * 0.6) * 0.5 + 0.5;
        col.rgb += light_color.rgb * presence_intensity * 0.04 * presence_pulse;
    }
    
    // Distinction light pools
    float total_light = 0.0;
    for (int i = 0; i < 16; i++) {
        if (i >= distinction_count) break;
        
        vec2 d_pos = distinction_positions[i];
        float d_clarity = distinction_clarities[i];
        
        float dist = distance(UV, d_pos);
        float radius = 0.08 + d_clarity * 0.15;
        float light = smoothstep(radius, 0.0, dist) * d_clarity;
        total_light += light;
    }
    
    total_light = clamp(total_light, 0.0, 1.0);
    col.rgb = mix(col.rgb, light_color.rgb, total_light * 0.6);
    
    // Breathing intensifies with total clarity (world wakes up)
    float wakefulness = clamp(float(distinction_count) / 8.0, 0.0, 1.0);
    col.rgb += vec3(breath * 0.5 * wakefulness);
    
    COLOR = col;
}
