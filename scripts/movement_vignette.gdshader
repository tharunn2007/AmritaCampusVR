shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled, shadows_disabled;
uniform float strength : hint_range(0.0, 1.0) = 0.0;
void vertex() {
    POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}
void fragment() {
    ALBEDO = vec3(0.0);
    ALPHA = smoothstep(0.26, 0.67, length(UV - vec2(0.5))) * strength;
}
