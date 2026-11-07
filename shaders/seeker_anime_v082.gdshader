shader_type spatial;
render_mode unshaded, cull_back;

uniform vec4 base_color : source_color = vec4(1.0);
uniform bool face_lighting = false;
varying vec3 world_normal;

void vertex() {
    // Light the face with a broader, forward-biased field while keeping its
    // actual surface normals available to the separate ink pass.
    vec3 lighting_normal = NORMAL;
    if (face_lighting) {
        vec3 soft_face = normalize(vec3(NORMAL.x * 0.52, NORMAL.y * 0.24, -0.92));
        lighting_normal = normalize(mix(NORMAL, soft_face, smoothstep(0.0, 0.65, -NORMAL.z) * 0.85));
    }
    world_normal = MODEL_NORMAL_MATRIX * lighting_normal;
}

void fragment() {
    vec3 key = normalize(vec3(-0.46, 0.79, -0.42));
    float light_amount = dot(normalize(world_normal), key);
    vec3 shadow = base_color.rgb * vec3(0.53, 0.59, 0.88) + vec3(0.017, 0.014, 0.029);
    if (face_lighting) {
        shadow = base_color.rgb * vec3(0.88, 0.60, 0.68) + vec3(0.033, 0.010, 0.015);
    }
    vec3 lit = base_color.rgb * 1.08 + vec3(0.035, 0.026, 0.014);
    ALBEDO = mix(shadow, lit, step(0.24, light_amount));
}
