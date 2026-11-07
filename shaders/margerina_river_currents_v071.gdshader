shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

// River currents in the V0.56 Janoah approach floodplain remain
// GAME-ONLY geography. Slow wave crests and flow-foam are lighter than sea.
uniform float flow_seconds = 0.0;
uniform vec4 river_color : source_color = vec4(0.075,0.295,0.35,1.0);
uniform vec4 glint_color : source_color = vec4(0.42,0.68,0.73,1.0);
varying float surface_foam;
void vertex() {
    float ripples = 0.035 * sin(VERTEX.z*0.27 - flow_seconds*1.6) +
        0.018 * sin(VERTEX.x*0.43+VERTEX.z*0.14-flow_seconds*0.70);
    VERTEX.y += ripples;
    surface_foam = smoothstep(0.031,0.055,ripples);
    float dx = 0.018 * 0.43 * cos(VERTEX.x*0.43+VERTEX.z*0.14-flow_seconds*0.70);
    float dz = 0.035 * 0.27 * cos(VERTEX.z*0.27-flow_seconds*1.6) +
        0.018*0.14*cos(VERTEX.x*0.43+VERTEX.z*0.14-flow_seconds*0.70);
    NORMAL = normalize(vec3(-dx,1.0,-dz));
}
void fragment() {
    vec3 n = normalize(NORMAL);
    float fresnel = pow(1.0-clamp(dot(n,normalize(VIEW)),0.0,1.0),3.0);
    float current_lines = abs(sin(UV.x*140.0 + UV.y*25.0 + flow_seconds*0.65));
    float foam = smoothstep(0.90,0.99,current_lines)*surface_foam*0.34;
    ALBEDO = mix(river_color.rgb,glint_color.rgb,fresnel*0.26+foam);
    ROUGHNESS = 0.18;
    SPECULAR = 0.86;
    METALLIC = 0.06;
    EMISSION = glint_color.rgb*fresnel*0.035;
}
