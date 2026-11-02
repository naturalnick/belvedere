shader_type spatial;
uniform vec4 base_color : source_color = vec4(0.9, 0.85, 0.75, 1.0);
uniform vec4 shadow_tint : source_color = vec4(0.35, 0.28, 0.25, 1.0);
uniform sampler2D paper_grain : repeat_enable, filter_linear;
varying vec3 world_position;
varying vec3 world_normal;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
	vec3 weights = abs(world_normal);
	weights /= max(dot(weights, vec3(1.0)), 0.001);
	float grain = texture(paper_grain, world_position.yz * 0.7).r * weights.x
		+ texture(paper_grain, world_position.xz * 0.7).r * weights.y
		+ texture(paper_grain, world_position.xy * 0.7).r * weights.z;
	ALBEDO = base_color.rgb * mix(0.92, 1.0, grain);
	ROUGHNESS = 0.75;
	SPECULAR = 0.25;
}
void light() {
	float facing = dot(NORMAL, LIGHT);
	float mid = smoothstep(0.16, 0.20, facing);
	float lit = smoothstep(0.66, 0.70, facing);
	vec3 band = mix(mix(ALBEDO, shadow_tint.rgb, 0.22) * 0.55, ALBEDO * 0.85, mid);
	band = mix(band, ALBEDO, lit);
	float rim = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), 3.0) * 0.15 * lit;
	DIFFUSE_LIGHT += (band + ALBEDO * rim) * LIGHT_COLOR * ATTENUATION / PI;
}
