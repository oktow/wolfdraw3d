shader_type spatial;
render_mode unshaded, cull_disabled, depth_prepass_alpha;
uniform vec4 ink_color : source_color = vec4(0.15,0.2,0.22,1.0);
uniform float opacity = 1.0;
uniform int brush_mode = 0;
uniform bool selected = false;
float grain(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void fragment() {
    float edge = 1.0-smoothstep(0.76,1.0,abs(UV.y*2.0-1.0));
    float mask = 1.0;
    if (brush_mode == 1) {
        float g = grain(floor(UV*vec2(28.0,36.0)));
        mask = smoothstep(0.2,0.65,g)*0.82+0.08;
    } else if (brush_mode == 2) {
        float bristle = grain(vec2(floor(UV.y*48.0),floor(UV.x*0.4)));
        mask = mix(0.18,1.0,smoothstep(0.15,0.6,bristle));
        mask *= 0.8+0.2*grain(floor(UV*vec2(8.0,50.0)));
    }
    ALBEDO = selected ? mix(ink_color.rgb,vec3(1.0,0.72,0.3),0.6) : ink_color.rgb;
    ALPHA = opacity*ink_color.a*edge*mask;
}
