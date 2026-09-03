shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_burley, specular_schlick_ggx;

// Water Color & Depth Absorption
uniform vec4 shallow_color : source_color = vec4(0.18, 0.68, 0.72, 0.65);
uniform vec4 deep_color : source_color = vec4(0.05, 0.28, 0.42, 0.92);
uniform float depth_distance : hint_range(0.1, 20.0) = 4.0;
uniform float absorption_strength : hint_range(0.1, 5.0) = 1.2;

// Wave Animation & Normal Map
uniform sampler2D wave_normal1 : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D wave_normal2 : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec2 wave_speed1 = vec2(0.02, 0.03);
uniform vec2 wave_speed2 = vec2(-0.025, 0.018);
uniform float wave_scale1 : hint_range(0.01, 1.0) = 0.08;
uniform float wave_scale2 : hint_range(0.01, 1.0) = 0.12;
uniform float normal_blend : hint_range(0.0, 1.0) = 0.5;

// Surface & Lighting Properties
uniform float roughness : hint_range(0.0, 1.0) = 0.05;
uniform float metallic : hint_range(0.0, 1.0) = 0.1;
uniform float specular : hint_range(0.0, 1.0) = 0.8;
uniform float fresnel_power : hint_range(0.5, 8.0) = 3.5;
uniform float refraction_strength : hint_range(0.0, 0.1) = 0.03;

// Shoreline Foam
uniform vec4 foam_color : source_color = vec4(0.92, 0.96, 1.0, 0.9);
uniform float foam_distance : hint_range(0.01, 2.0) = 0.45;
uniform float foam_noise_scale : hint_range(0.1, 5.0) = 1.5;

// Screen Texture & Depth Texture samplers
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;

varying vec3 world_pos;
varying vec3 vertex_normal;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    
    // Gentle vertex ripple displacement
    float wave_time = TIME * 1.5;
    float wave = sin(world_pos.x * 0.4 + wave_time) * cos(world_pos.z * 0.4 + wave_time) * 0.06;
    wave += sin(world_pos.x * 0.8 - wave_time * 0.7) * cos(world_pos.z * 0.8 - wave_time * 0.7) * 0.03;
    VERTEX.y += wave;
    
    vertex_normal = NORMAL;
}

void fragment() {
    // 1. Animated Dual Wave Normal Mapping
    vec2 uv1 = world_pos.xz * wave_scale1 + TIME * wave_speed1;
    vec2 uv2 = world_pos.xz * wave_scale2 + TIME * wave_speed2;
    
    vec3 n1 = texture(wave_normal1, uv1).rgb * 2.0 - 1.0;
    vec3 n2 = texture(wave_normal2, uv2).rgb * 2.0 - 1.0;
    
    // Procedural wave normal fallback if textures are empty
    if (length(n1) < 0.1) {
        float p1 = sin(uv1.x * 30.0 + uv1.y * 20.0 + TIME * 2.0);
        float p2 = cos(uv2.x * 25.0 - uv2.y * 35.0 + TIME * 1.8);
        n1 = vec3(p1 * 0.15, p2 * 0.15, 1.0);
    }
    if (length(n2) < 0.1) {
        float p3 = cos(uv2.x * 40.0 + uv2.y * 30.0 - TIME * 1.5);
        float p4 = sin(uv1.x * 35.0 - uv1.y * 25.0 + TIME * 2.2);
        n2 = vec3(p3 * 0.12, p4 * 0.12, 1.0);
    }
    
    vec3 wave_normal = normalize(mix(n1, n2, normal_blend));
    NORMAL = normalize(mix(NORMAL, (VIEW_MATRIX * vec4(wave_normal.x, wave_normal.z, wave_normal.y, 0.0)).xyz, 0.7));
    
    // 2. Depth Buffer Linearization & Intersection
    float raw_depth = texture(depth_texture, SCREEN_UV).r;
    vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, raw_depth);
    vec4 view_pos = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
    view_pos.xyz /= view_pos.w;
    float scene_depth = -view_pos.z;
    float surface_depth = -VERTEX.z;
    float depth_diff = max(scene_depth - surface_depth, 0.0);
    
    // 3. Screen-Space Refraction with Wave Distortion
    vec2 distorted_uv = SCREEN_UV + wave_normal.xy * refraction_strength * clamp(depth_diff, 0.0, 1.0);
    // Fallback if distortion samples in front of water
    float distorted_raw_depth = texture(depth_texture, distorted_uv).r;
    vec4 distorted_view_pos = INV_PROJECTION_MATRIX * vec4(vec3(distorted_uv * 2.0 - 1.0, distorted_raw_depth), 1.0);
    distorted_view_pos.xyz /= distorted_view_pos.w;
    if (-distorted_view_pos.z < surface_depth) {
        distorted_uv = SCREEN_UV;
    }
    vec3 ref_scene = texture(screen_texture, distorted_uv).rgb;
    
    // 4. Depth Color Absorption (Beer's Law)
    float depth_factor = clamp(depth_diff / depth_distance, 0.0, 1.0);
    float absorption = 1.0 - exp(-depth_diff * absorption_strength);
    vec3 water_tint = mix(shallow_color.rgb, deep_color.rgb, depth_factor);
    vec3 absorbed_color = mix(ref_scene * shallow_color.rgb, water_tint, absorption);
    
    // 5. Fresnel Reflectance
    float fresnel = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), fresnel_power);
    fresnel = clamp(fresnel, 0.04, 0.95);
    
    // 6. Soft Shoreline Edge-Blending Foam
    float foam_edge = clamp(1.0 - depth_diff / foam_distance, 0.0, 1.0);
    float foam_noise = sin(world_pos.x * foam_noise_scale * 10.0 + TIME * 3.0) * cos(world_pos.z * foam_noise_scale * 10.0 + TIME * 2.5);
    float foam = smoothstep(0.3, 0.8, foam_edge + foam_noise * 0.25 * foam_edge);
    
    // Final Composition
    vec3 final_albedo = mix(absorbed_color, water_tint, fresnel * 0.4);
    final_albedo = mix(final_albedo, foam_color.rgb, foam * foam_color.a);
    
    ALBEDO = final_albedo;
    METALLIC = metallic;
    ROUGHNESS = mix(roughness, 0.4, foam);
    SPECULAR = mix(specular, 0.1, foam);
    ALPHA = mix(mix(shallow_color.a, deep_color.a, depth_factor), 1.0, fresnel);
    ALPHA = max(ALPHA, foam * 0.8);
}
