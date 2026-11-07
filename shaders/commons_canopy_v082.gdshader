shader_type spatial;
render_mode unshaded;
varying vec3 canopy_position;
varying vec3 canopy_normal;

void vertex() {
    canopy_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    canopy_normal = MODEL_NORMAL_MATRIX * NORMAL;
}

void fragment() {
    float daylight = dot(normalize(canopy_normal), normalize(vec3(-0.45, 0.83, -0.32)));
    float brush = sin(canopy_position.y * 5.0 + sin(canopy_position.x * 3.1 + canopy_position.z * 2.3));
    float lit = smoothstep(0.28, 0.34, daylight + brush * 0.07);
    vec3 shade = COLOR.rgb * vec3(0.50, 0.70, 0.73);
    ALBEDO = mix(shade, COLOR.rgb * vec3(1.14, 1.18, 0.91), lit) * (1.0 + brush * 0.035);
}
