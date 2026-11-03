class_name ManorSlideMotion
extends RefCounted

const TAKE_UP := 0.09
const TRAVEL := 1.23
const DOCK := 0.08
const DURATION := TAKE_UP + TRAVEL + DOCK
const ACCELERATION := 0.26
const BRAKING := 0.14

static func travel_progress(fraction: float) -> float:
	var t := clampf(fraction, 0.0, 1.0)
	var speed := 1.0 / (1.0 - (ACCELERATION + BRAKING) * 0.5)
	# Integrating cosine velocity ramps joins the steady push without a speed jump.
	# Shorter braking gives a definite arrival, with no overshoot into the next room.
	if t < ACCELERATION:
		return speed * 0.5 * (t - ACCELERATION * sin(PI * t / ACCELERATION) / PI)
	if t > 1.0 - BRAKING:
		var remaining := 1.0 - t
		return 1.0 - speed * 0.5 * (remaining - BRAKING * sin(PI * remaining / BRAKING) / PI)
	return speed * (t - ACCELERATION * 0.5)
