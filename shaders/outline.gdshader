shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled;
uniform float width = 0.012;
void vertex() {
	vec3 p = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float wobble = sin(dot(p, vec3(17.0, 29.0, 13.0))) * 0.25;
	VERTEX += NORMAL * width * (1.0 + wobble);
}
void fragment() {
	ALBEDO = vec3(0.2314, 0.1647, 0.1333);
}
