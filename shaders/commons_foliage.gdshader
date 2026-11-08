shader_type spatial;
render_mode skip_vertex_transform, cull_disabled, diffuse_lambert, specular_disabled;

uniform bool drifting_leaves = false;

varying vec2 brush_uv;
varying float phase;

void vertex() {
    vec3 center = MODEL_MATRIX[3].xyz;
    phase = dot(center.xz, vec2(1.73, 2.27));
    float breeze = sin(TIME * 1.15 + phase * 0.13);
    float angle = 0.45 * sin(phase) + breeze * 0.09;
    float fall = fract(TIME * 0.13 + fract(sin(phase) * 31.7));
    if (drifting_leaves) {
        center += vec3(fall * 2.2 + breeze * 0.35, -fall * 4.0, breeze * 0.45);
        angle += fall * 8.0;
    }
    vec2 offset = VERTEX.xy * vec2(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz));
    offset = mat2(vec2(cos(angle), sin(angle)), vec2(-sin(angle), cos(angle))) * offset;
    float distance_to_tree = distance(CAMERA_POSITION_WORLD, center);
    float reach = 53.0 + 12.0 * fract(sin(phase) * 31.7);
    offset *= 1.0 - smoothstep(reach - 8.0, reach, distance_to_tree);
    if (drifting_leaves) {
        offset *= smoothstep(0.0, 0.10, fall) * (1.0 - smoothstep(0.87, 1.0, fall));
    }
    center += vec3(breeze * 0.18, 0.0, breeze * 0.10);
    VERTEX = (VIEW_MATRIX * vec4(center, 1.0)).xyz + vec3(offset, 0.0);
    brush_uv = UV;
}

void fragment() {
    vec2 p = vec2(brush_uv.x, 1.0 - brush_uv.y) * 2.0 - 1.0;
    float a = atan(p.y, p.x + 0.00001);
    float edge = 0.80 + 0.10 * sin(a * 7.0 + phase) + 0.05 * sin(a * 13.0 - phase);
    if (drifting_leaves) {
        edge = 0.70 + 0.19 * cos(2.0 * a);
    }
    ALPHA = step(length(p), edge);
    ALPHA_SCISSOR_THRESHOLD = 0.5;

    float stroke = sin(p.y * 23.0 + p.x * 7.0 + sin(p.x * 14.0 + phase) * 2.0);
    float upper = smoothstep(-0.45, 0.50, p.y + stroke * 0.09);
    ALBEDO = COLOR.rgb * mix(vec3(0.47, 0.64, 0.65), vec3(1.14, 1.18, 0.94), upper);

    // A rounded crown normal keeps individual cards from lighting like flat panels.
    vec3 crown = normalize(vec3(p.x * 0.45, 0.67 + p.y * 0.27, 0.42));
    NORMAL = normalize(mat3(VIEW_MATRIX) * crown);
}

void light() {
    float band = mix(0.32, 1.0, smoothstep(0.25, 0.41, dot(NORMAL, LIGHT)));
    DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * band;
}
