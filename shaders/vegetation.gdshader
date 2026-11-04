shader_type spatial;
render_mode unshaded, cull_disabled;

uniform bool flat_tree = false;

void vertex() {
	if (flat_tree) {
		// Cylindrical billboards turn in the vertex shader, with no per-tree CPU updates.
		vec3 facing = vec3(INV_VIEW_MATRIX[2].x, 0.0, INV_VIEW_MATRIX[2].z);
		facing = length(facing) > 0.001 ? normalize(facing) : vec3(0.0, 0.0, 1.0);
		vec3 right = cross(vec3(0.0, 1.0, 0.0), facing);
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			vec4(right * length(MODEL_MATRIX[0].xyz), 0.0),
			vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
			vec4(facing * length(MODEL_MATRIX[2].xyz), 0.0), MODEL_MATRIX[3]);
	}
}

void fragment() {
	ALBEDO = COLOR.rgb;
}
