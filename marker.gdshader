shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

uniform vec4 color : source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform float thickness : hint_range(0.0, 1.0) = 0.1;
uniform float radius : hint_range(0.0, 1.0) = 0.45;
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.0;

void fragment() {
    vec2 uv = UV - 0.5;
    float dist = length(uv);
    
    float pulse = (sin(TIME * pulse_speed) * 0.5 + 0.5) * 0.1;
    float inner = radius - thickness + pulse;
    float outer = radius + pulse;
    
    float ring = smoothstep(inner - 0.01, inner, dist) - smoothstep(outer, outer + 0.01, dist);
    
    ALBEDO = color.rgb;
    ALPHA = ring * color.a;
}
