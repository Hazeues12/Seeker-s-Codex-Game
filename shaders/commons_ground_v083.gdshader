shader_type spatial;
render_mode diffuse_toon, specular_disabled;

varying vec3 surface_position;

void vertex() {
    surface_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    vec2 ground = surface_position.xz;
    float grass = step(0.035, COLOR.g - COLOR.r);
    float brush = sin(ground.x * 3.6 + ground.y * 1.5 + sin(ground.y * 2.6));
    vec2 tile = fract(vec2(ground.x / 1.10 + floor(ground.y / 0.78) * 0.5, ground.y / 0.78));
    vec2 edge = min(tile, 1.0 - tile);
    float seam = 1.0 - smoothstep(0.015, 0.037, min(edge.x, edge.y));
    float stone_tone = 0.73 - seam * 0.18 + brush * 0.025;
    float grass_tone = 0.57 + brush * 0.047 + sin(ground.x * 0.88 - ground.y * 0.68) * 0.06;
    ALBEDO = COLOR.rgb * mix(stone_tone, grass_tone, grass);
    ROUGHNESS = 1.0;
}
