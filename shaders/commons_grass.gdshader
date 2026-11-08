shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;

varying float breeze;

void vertex() {
    vec3 root = MODEL_MATRIX[3].xyz;
    float wave = sin(TIME * 1.8 + dot(root.xz, vec2(0.46, 0.31)));
    float gust = sin(TIME * 2.7 + dot(root.xz, vec2(-0.72, 0.53)));
    float tip = UV.y * UV.y;
    vec3 wind = vec3(0.055 * wave + 0.024 * gust, 0.0, 0.040 * wave);
    VERTEX += inverse(mat3(MODEL_MATRIX)) * wind * tip;
    float reach = mix(24.0, 40.0, COLOR.r);
    VERTEX *= 1.0 - smoothstep(reach - 6.0, reach, distance(CAMERA_POSITION_WORLD, root));
    breeze = wave * tip;
}

void fragment() {
    vec3 base = mix(vec3(0.11, 0.24, 0.09), vec3(0.39, 0.55, 0.19), UV.y);
    ALBEDO = base * (mix(0.84, 1.12, COLOR.r) + breeze * 0.035);
    // Keep the lighting normal upright on both sides of the blade.
    NORMAL = normalize(mat3(VIEW_MATRIX) * vec3(0.12, 1.0, 0.06));
    ROUGHNESS = 1.0;
}

void light() {
    float band = mix(0.32, 1.0, smoothstep(0.30, 0.40, dot(NORMAL, LIGHT)));
    DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * band;
}
