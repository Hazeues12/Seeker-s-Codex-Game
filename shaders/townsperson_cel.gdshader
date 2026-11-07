shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec3 coat_linear = vec3(0.34, 0.37, 0.43);
uniform vec3 trim_linear = vec3(0.45, 0.40, 0.35);
uniform vec3 skin_linear = vec3(0.62, 0.39, 0.28);
uniform vec3 hair_linear = vec3(0.09, 0.07, 0.08);
varying vec3 world_normal;

void vertex() {
    world_normal = MODEL_NORMAL_MATRIX * NORMAL;
}

void fragment() {
    vec3 tint = vec3(1.0);
    if (UV.x < 0.2) {
        tint = coat_linear;
    } else if (UV.x < 0.4) {
        tint = trim_linear;
    } else if (UV.x < 0.6) {
        tint = skin_linear;
    } else if (UV.x < 0.8) {
        tint = hair_linear;
    }
    vec3 normal = normalize(world_normal) * (FRONT_FACING ? 1.0 : -1.0);
    vec3 key = normalize(vec3(-0.48, 0.74, -0.47));
    float band = smoothstep(0.13, 0.25, dot(normal, key));
    vec3 cel = COLOR.rgb * tint * mix(vec3(0.55, 0.60, 0.72), vec3(1.22, 1.19, 1.15), band);
    if (OUTPUT_IS_SRGB) {
        cel = mix(cel * 12.92, 1.055 * pow(cel, vec3(1.0 / 2.4)) - 0.055,
            step(vec3(0.0031308), cel));
    }
    ALBEDO = cel;
}
