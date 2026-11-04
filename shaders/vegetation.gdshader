shader_type spatial;
render_mode unshaded, cull_disabled;

// Raw vertex-color space (no source_color), matching the baked foliage colors.
uniform vec3 haze = vec3(0.847, 0.843, 0.690);
uniform vec2 haze_range = vec2(26.0, 112.0);
uniform float haze_strength = 0.62;
varying vec3 tint;

void vertex() {
	// Distance from the house, like the meadow tint, so the haze is static per vertex.
	float distance_to_house = length((MODEL_MATRIX * vec4(VERTEX, 1.0)).xz);
	tint = mix(COLOR.rgb, haze, smoothstep(haze_range.x, haze_range.y, distance_to_house) * haze_strength);
}

void fragment() {
	ALBEDO = tint;
}
