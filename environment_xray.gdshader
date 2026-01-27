shader_type spatial;
render_mode unshaded, depth_test_disabled, blend_mix, cull_disabled;

uniform vec4 silhouette_color : source_color = vec4(0.0, 1.0, 0.4, 0.4); 
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

// This will be set by the camera script
global uniform vec3 player_world_pos;
global uniform float player_depth_view;
global uniform vec2 player_screen_uv;
global uniform bool xray_enabled;
global uniform float visibility_radius;

varying vec3 world_pos;
varying float view_z;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    view_z = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).z;
}

void fragment() {
    if (!xray_enabled) {
        discard;
    }
    float world_dist = distance(world_pos, player_world_pos);
    
    // Fog of War / Spotlight Effect
    // User requested "Dark/Invisible" outside the center light.
    // We restrict visibility to a specific radius around the player.
    if (world_dist > 50.0) { 
        discard; // Outside of max range is completely dark/invisible
    }
    
    // 2. Depth check: Only glow if this part of the environment is IN FRONT of the player
    // player_depth_view is calculated in camera_3d.gd as distance from camera plane (-z)
    if (-view_z > player_depth_view - 0.2) {
        discard;
    }
    
    // Smooth Falloff ("Cloudy" Edge)
    // Full brightness up to 25m, then fades out to 50m
    float falloff = 1.0 - smoothstep(25.0, 50.0, world_dist);
    
	ALBEDO = vec3(0.0, 1.0, 0.4); // Lime Green
	ALPHA = 0.6 * falloff;
}
