uniform bool window_clue = false;
uniform vec3 clue_room_origin = vec3(0.0);
uniform vec4 clue_windows = vec4(0.0);
uniform vec4 clue_closed_doors = vec4(0.0);

bool through_clue_window(vec3 eye, vec3 point) {
	vec3 start = eye - clue_room_origin;
	vec3 end = point - clue_room_origin;
	if (abs(start.x) < 3.0625 && abs(start.z) < 3.0625) { return false; }
	vec3 ray = end - start;
	float entry = -1.0;
	int side = -1;
	// The last inward crossing is the room entry, including oblique corner views.
	for (int d = 0; d < 4; d++) {
		vec3 normal = vec3(0.0, 0.0, -1.0);
		if (d == 1) { normal = vec3(1.0, 0.0, 0.0); }
		if (d == 2) { normal = vec3(0.0, 0.0, 1.0); }
		if (d == 3) { normal = vec3(-1.0, 0.0, 0.0); }
		float distance = dot(start, normal);
		float travel = dot(ray, normal);
		if (distance > 3.0625 && travel < -0.00001) {
			float t = (3.0625 - distance) / travel;
			if (t > entry) { entry = t; side = d; }
		}
	}
	if (side < 0 || entry < 0.0 || entry > 1.0) { return false; }
	vec3 crossing = start + ray * entry;
	float along = (side == 0 || side == 2) ? crossing.x : crossing.z;
	bool window = clue_windows[side] > 0.5 && crossing.y > 0.9 && crossing.y < 2.4
		&& abs(abs(along) - 1.6) < 0.7;
	bool closed_door = clue_closed_doors[side] > 0.5 && crossing.y > 0.0 && crossing.y < 2.2 && abs(along) < 0.6;
	return window || closed_door;
}
