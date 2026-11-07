shader_type spatial;
render_mode unshaded, cull_front;
uniform float width = 0.012;

void vertex() {
    // Extrude by a world-space distance so thin limbs keep a consistent line.
    vec3 world_offset = normalize(MODEL_NORMAL_MATRIX * NORMAL) * width;
    VERTEX += inverse(mat3(MODEL_MATRIX)) * world_offset;
}

void fragment() {
    ALBEDO = vec3(0.035, 0.024, 0.061);
}
