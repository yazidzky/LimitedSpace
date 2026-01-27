// This shader is for the OBSTRUCTING wall.
shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled;

uniform vec2 player_screen_pos;
uniform float radius : hint_range(0.0, 1.0) = 0.2;
uniform float smoothness : hint_range(0.0, 0.5) = 0.1;

void fragment() {
    float aspect_ratio = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;
    vec2 correction = vec2(aspect_ratio, 1.0);
    vec2 uv = FRAGCOORD.xy / VIEWPORT_SIZE.xy;
    
    float dist = length((uv - player_screen_pos) * correction);
    
    // We can't easily punch a hole in another material via overlay.
    // BUT we can render a black hole that hides things, or just
    // use this as a silhouette logic.
    
    // IF we are inside the circle, we render NOTHING (ALPHA 0) 
    // and hope the depth buffer allows seeing through.
    // Actually, discarding works if used on the BASE material.
    
    if (dist < radius) {
        discard;
    }
    
    // Outside circle, render nothing (invisible overlay)
    ALPHA = 0.0;
}