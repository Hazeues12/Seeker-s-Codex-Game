shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

// V0.71: vertex-displaced offshore surface for Godot Compatibility/Web.
// CPU mirror: systems/ocean_hydrodynamics_v071.gd. Game-only Janoah
// coastal survey; not an established coastline or a live weather forecast.
uniform float sea_seconds = 0.0;
uniform float sea_wind : hint_range(0.20, 0.95) = 0.48;
uniform vec4 deep_color : source_color = vec4(0.014,0.092,0.17,1.0);
uniform vec4 shallow_color : source_color = vec4(0.063,0.37,0.42,1.0);
uniform vec4 sun_glint : source_color = vec4(0.50,0.76,0.85,1.0);
uniform vec4 foam_color : source_color = vec4(0.78,0.90,0.90,1.0);

varying float foam_phase;
varying float offshore_amount;
varying float model_wave_height;

float ocean_height(vec2 p, float seconds, float wind) {
    float offshore = clamp((p.x + 320.0) / 490.0, 0.0, 1.0);
    float strength = (0.18 + 1.25 * clamp(wind,0.20,0.95)) * (0.22 + 0.78 * offshore);
    float t = seconds * (0.72 + clamp(wind,0.20,0.95) * 0.9);
    float waves =
        0.54 * sin(p.x * 0.095 + p.y * 0.034 + t * 1.08) +
        0.29 * sin(-p.x * 0.061 + p.y * 0.129 + t * 0.79) +
        0.17 * sin(p.x * 0.16 - p.y * 0.084 + t * 1.42);
    return sin(seconds * 6.28318530718 / 440.0) * 0.14 + strength * waves;
}

void vertex() {
    vec2 p = VERTEX.xz;
    float h = ocean_height(p,sea_seconds,sea_wind);
    VERTEX.y = h;
    float epsilon = 0.35;
    float dx = (ocean_height(p+vec2(epsilon,0.0),sea_seconds,sea_wind) -
        ocean_height(p-vec2(epsilon,0.0),sea_seconds,sea_wind)) / (2.0*epsilon);
    float dz = (ocean_height(p+vec2(0.0,epsilon),sea_seconds,sea_wind) -
        ocean_height(p-vec2(0.0,epsilon),sea_seconds,sea_wind)) / (2.0*epsilon);
    NORMAL = normalize(vec3(-dx,1.0,-dz));
    foam_phase = smoothstep(0.25,0.72,h);
    offshore_amount = clamp((p.x+320.0)/490.0,0.0,1.0);
    model_wave_height = h;
}

void fragment() {
    vec3 n = normalize(NORMAL);
    float facing = clamp(dot(n,normalize(VIEW)),0.0,1.0);
    float fresnel = pow(1.0-facing,4.0);
    float small_ripple = sin(UV.x*242.0+sea_seconds*0.90) *
        sin(UV.y*193.0-sea_seconds*0.72) * 0.022;
    float foam = clamp(foam_phase*(0.22+0.5*sea_wind)*(0.4+0.6*offshore_amount)
        + small_ripple,0.0,0.68);
    vec3 water = mix(shallow_color.rgb,deep_color.rgb,
        clamp(offshore_amount*0.70+fresnel*0.25,0.0,1.0));
    water = mix(water,foam_color.rgb,foam);
    ALBEDO = water;
    ROUGHNESS = mix(0.22,0.078,fresnel);
    METALLIC = 0.09;
    SPECULAR = 0.90;
    EMISSION = sun_glint.rgb * (fresnel*0.16+max(0.0,small_ripple)*0.20);
}
