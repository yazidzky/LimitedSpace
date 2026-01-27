shader_type spatial;
render_mode unshaded, depth_test_disabled, blend_mix, cull_disabled;

uniform vec4 silhouette_color : source_color = vec4(0.0, 0.5, 1.0, 0.5);
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
global uniform bool xray_enabled;

void fragment() {
	if (!xray_enabled) {
		discard;
	}
	float depth = texture(depth_texture, SCREEN_UV).r;
	
	if (depth <= FRAGCOORD.z) {
		discard;
	}
	
	// Scanline effect
	float scanline = sin(FRAGCOORD.y * 1.5) * 0.1 + 0.9;
	
	// Pulse effect
	float pulse = sin(TIME * 3.0) * 0.1 + 0.9;
	
	ALBEDO = silhouette_color.rgb;
	ALPHA = silhouette_color.a * scanline * pulse;
}
