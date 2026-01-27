shader_type spatial;
render_mode blend_mix;

uniform float alpha : hint_range(0.0, 1.0) = 0.3;

void fragment() {
    ALBEDO = vec3(1.0);
    ALPHA = alpha;
}