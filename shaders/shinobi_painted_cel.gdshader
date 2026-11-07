shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec3 skin_tint = vec3(1.0);
uniform bool face_layer = false;
varying vec3 world_normal;

void vertex() {
    vec3 normal = NORMAL;
    if (face_layer) {
        float facing = smoothstep(0.30, 0.90, -normal.z);
        normal = normalize(mix(normal, vec3(normal.x * 0.40, normal.y * 0.28, -1.0), facing * 0.62));
    }
    world_normal = MODEL_NORMAL_MATRIX * normal;
}

void fragment() {
    vec3 normal = normalize(world_normal);
    normal *= FRONT_FACING ? 1.0 : -1.0;
    vec3 key = normalize(vec3(-0.48, 0.74, -0.47));
    float shade = smoothstep(0.15, 0.27, dot(key, normal));
    vec3 pigment = COLOR.rgb * skin_tint;
    vec3 shadow = pigment * vec3(0.57, 0.61, 0.72);
    vec3 lit = pigment * vec3(1.25, 1.23, 1.17);
    vec3 cel = mix(shadow, lit, shade);
    if (OUTPUT_IS_SRGB) {
        cel = mix(cel * 12.92, 1.055 * pow(cel, vec3(1.0 / 2.4)) - 0.055,
            step(vec3(0.0031308), cel));
    }
    ALBEDO = cel;
}
