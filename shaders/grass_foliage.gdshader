shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform vec4 top_color : source_color = vec4(0.48, 0.78, 0.28, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.22, 0.42, 0.12, 1.0);
uniform sampler2D grass_texture : source_color, filter_linear_mipmap;
uniform float wind_speed : hint_range(0.1, 5.0) = 1.8;
uniform float wind_strength : hint_range(0.0, 1.5) = 0.25;
uniform float sss_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float fade_distance_start : hint_range(10.0, 200.0) = 60.0;
uniform float fade_distance_end : hint_range(20.0, 300.0) = 110.0;

varying vec3 world_pos;
varying float dist_to_camera;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    vec3 cam_pos = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
    dist_to_camera = length(cam_pos - world_pos);
    
    // Wind displacement influenced by height (UV.y = 0 at top, 1 at bottom for quad)
    float height_factor = 1.0 - UV.y;
    float wind = sin(TIME * wind_speed + world_pos.x * 0.4 + world_pos.z * 0.6) * wind_strength;
    float wind_gust = cos(TIME * wind_speed * 1.3 + world_pos.x * 0.2 - world_pos.z * 0.3) * (wind_strength * 0.6);
    
    VERTEX.x += (wind + wind_gust) * height_factor;
    VERTEX.z += (wind * 0.5 - wind_gust * 0.5) * height_factor;
}

void fragment() {
    // Distance LOD fade
    float lod_fade = clamp(1.0 - (dist_to_camera - fade_distance_start) / (fade_distance_end - fade_distance_start), 0.0, 1.0);
    if (lod_fade <= 0.01) {
        discard;
    }
    
    vec4 tex = texture(grass_texture, UV);
    vec3 gradient_col = mix(top_color.rgb, bottom_color.rgb, UV.y);
    
    ALBEDO = mix(gradient_col, tex.rgb * gradient_col, 0.5);
    ALPHA = tex.a * lod_fade;
    ALPHA_SCISSOR_THRESHOLD = 0.45;
    
    ROUGHNESS = 0.82;
    SPECULAR = 0.2;
    NORMAL = vec3(0.0, 1.0, 0.0);
    
    // Subsurface scattering & translucent sunlight pass-through
    BACKLIGHT = top_color.rgb * sss_intensity;
}
