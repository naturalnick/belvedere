shader_type spatial;
#include "res://shaders/window_clue.gdshaderinc"
uniform vec4 base_color : source_color = vec4(0.9, 0.85, 0.75, 1.0);
uniform float self_light = 0.0;
uniform bool vertex_colors = false;
uniform bool gap_tracks = false;
uniform bool meadow = false;
uniform bool clip_below_ground = false;
uniform float ground_level = -0.04;
uniform int floor_pattern = 0;
uniform float tile_size = 0.45;
uniform vec4 grout_color : source_color = vec4(0.78, 0.77, 0.73, 1.0);
uniform vec4 alternate_tile : source_color = vec4(0.23, 0.165, 0.133, 1.0);
uniform vec4 meadow_far : source_color = vec4(0.7255, 0.7882, 0.5569, 1.0);
varying vec3 world_position;
uniform vec4 track_groove : source_color = vec4(0.239, 0.271, 0.278, 1.0);
uniform vec4 track_steel : source_color = vec4(0.545, 0.573, 0.557, 1.0);
uniform vec4 shadow_tint : source_color = vec4(0.35, 0.28, 0.25, 1.0);
// Room wall boxes face outward along mesh -Z (interior trims sit on +Z).
uniform bool exterior_siding = false;
// Bit 1: the +X end face is a house corner; bit 2: the -X end. Other ends are opening reveals.
uniform int siding_corners = 0;
uniform vec4 siding_color : source_color = vec4(0.66, 0.645, 0.62, 1.0);
uniform vec4 siding_base : source_color = vec4(0.36, 0.345, 0.33, 1.0);
uniform vec4 siding_trim : source_color = vec4(0.937, 0.894, 0.824, 1.0);
uniform sampler2D paper_grain : repeat_enable, filter_linear_mipmap;
varying vec3 surface_position;
varying vec3 surface_normal;
void vertex() {
	// Mesh-local grain rides with moving rooms and swinging doors.
	surface_position = VERTEX;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	surface_normal = NORMAL;
}
void fragment() {
	if (window_clue && !through_clue_window(CAMERA_POSITION_WORLD, world_position)) { discard; }
	if (clip_below_ground && world_position.y < ground_level) { discard; }
	float grain = 1.0;
	// The meadow replaces its albedo below, so skip three samples across most of the outdoor view.
	if (!meadow) {
		vec3 weights = abs(surface_normal);
		weights /= max(dot(weights, vec3(1.0)), 0.001);
		grain = texture(paper_grain, surface_position.yz * 0.7).r * weights.x
			+ texture(paper_grain, surface_position.xz * 0.7).r * weights.y
			+ texture(paper_grain, surface_position.xy * 0.7).r * weights.z;
	}
	ALBEDO = base_color.rgb * mix(0.92, 1.0, grain) * (vertex_colors ? COLOR.rgb : vec3(1.0));
	if ((floor_pattern == 1 || floor_pattern == 2) && surface_normal.y > 0.5) {
		vec2 tile = surface_position.xz / tile_size;
		vec2 edge = min(fract(tile), 1.0 - fract(tile)) * tile_size;
		float distance_to_grout = min(edge.x, edge.y);
		float aa = max(fwidth(distance_to_grout), 0.001);
		float grout = 1.0 - smoothstep(0.004 - aa, 0.004 + aa, distance_to_grout);
		if (floor_pattern == 2) {
			float checker = mod(floor(tile.x) + floor(tile.y), 2.0);
			ALBEDO = mix(ALBEDO, alternate_tile.rgb * mix(0.92, 1.0, grain), checker);
		}
		ALBEDO = mix(ALBEDO, grout_color.rgb, grout);
	}
	if (floor_pattern == 3 && surface_normal.y > 0.5) {
		vec2 wood = surface_position.xz;
		float row = floor(wood.x / 0.18);
		float across = fract(wood.x / 0.18) * 0.18;
		float along = fract((wood.y + mod(row, 3.0) * 0.53) / 1.6) * 1.6;
		float seam_distance = min(min(across, 0.18 - across), min(along, 1.6 - along));
		float aa = max(fwidth(seam_distance), 0.0005);
		float seam = 1.0 - smoothstep(0.001 - aa, 0.001 + aa, seam_distance);
		// Keep the existing palette; these are quiet joinery marks, not dark outlines.
		ALBEDO *= mix(1.0, 0.98, mod(row, 2.0)) * mix(1.0, 0.92, seam);
	}
	bool corner_end = (surface_normal.x > 0.5 && (siding_corners & 1) != 0) || (surface_normal.x < -0.5 && (siding_corners & 2) != 0);
	if (exterior_siding && surface_normal.z < 0.5) {
		if (surface_normal.z > -0.5 && !corner_end) {
			// Door jambs and window reveals read as cream casings.
			ALBEDO = siding_trim.rgb * mix(0.92, 1.0, grain);
		} else {
			// Board lines use world height: rooms only slide horizontally, so the courses
			// stay fixed and line up across separately built wall pieces and rooms.
			float course = (world_position.y - 0.3) / 0.18;
			float from_top = (1.0 - fract(course)) * 0.18;
			float aa = max(fwidth(world_position.y), 0.0005);
			// Keep lap lines at least a pixel wide and lighten them to match, so distant walls
			// average out instead of breaking into jagged streaks.
			float width = max(0.016, aa * 1.5);
			float lap = (1.0 - smoothstep(width - aa, width + aa, from_top)) * (0.016 / width);
			vec3 boards = siding_color.rgb * mix(1.0, 0.93, fract(course)) * mix(1.0, 0.72, lap);
			float base = 1.0 - smoothstep(0.3 - aa, 0.3 + aa, world_position.y);
			ALBEDO = mix(boards, siding_base.rgb, base) * mix(0.92, 1.0, grain);
		}
	}
	if (meadow) {
		ALBEDO = mix(base_color.rgb, meadow_far.rgb, smoothstep(18.0, 90.0, length(world_position.xz)));
	}
	if (gap_tracks && surface_normal.y > 0.5) {
		float rail_distance = min(abs(abs(surface_position.x) - 1.65), abs(abs(surface_position.z) - 1.65));
		float aa = max(fwidth(rail_distance), 0.001);
		float groove = 1.0 - smoothstep(0.075 - aa, 0.075 + aa, rail_distance);
		float steel = 1.0 - smoothstep(0.028 - aa, 0.028 + aa, rail_distance);
		ALBEDO = mix(ALBEDO, track_groove.rgb, groove);
		ALBEDO = mix(ALBEDO, track_steel.rgb * mix(0.96, 1.0, grain), steel);
	}
	EMISSION = base_color.rgb * self_light;
	ROUGHNESS = 0.75;
	SPECULAR = 0.25;
}
void light() {
	float facing = dot(NORMAL, LIGHT);
	float mid = smoothstep(0.16, 0.20, facing);
	float lit = smoothstep(0.66, 0.70, facing);
	// Godot multiplies DIFFUSE_LIGHT by ALBEDO after light(); applying it here
	// as well squares the palette and exaggerates colour saturation.
	float band = mix(0.55, 0.85, mid);
	band = mix(band, 1.0, lit);
	float rim = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), 3.0) * 0.15 * lit;
	// Compatibility adds shadowed lights in a separate LDR pass; leave headroom
	// for the ambient pass instead of clipping the sunlit palette.
	float energy_scale = LIGHT_IS_DIRECTIONAL ? 0.06 : 0.7;
	DIFFUSE_LIGHT += (band + rim) * LIGHT_COLOR * ATTENUATION * energy_scale / PI;
}
