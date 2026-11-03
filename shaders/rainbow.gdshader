shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 band_color : source_color;
uniform float reveal = 0.0;
void fragment() {
	float feather = smoothstep(0.0, 0.10, UV.y) * (1.0 - smoothstep(0.90, 1.0, UV.y));
	ALBEDO = band_color.rgb;
	ALPHA = 0.32 * reveal * feather;
}
