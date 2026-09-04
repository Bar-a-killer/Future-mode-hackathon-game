class_name CollisionUtils

## Swept segment-vs-AABB test (slab method). Returns {} on no hit, else
## {t, point, normal} where t is the fraction along the segment [0,1].
static func segment_vs_aabb(seg_from: Vector2, seg_to: Vector2, box_min: Vector2, box_max: Vector2) -> Dictionary:
	var d := seg_to - seg_from
	var t_min := 0.0
	var t_max := 1.0
	var normal := Vector2.ZERO
	for axis in range(2):
		var o: float = seg_from[axis]
		var dd: float = d[axis]
		var bmin: float = box_min[axis]
		var bmax: float = box_max[axis]
		if abs(dd) < 0.000001:
			if o < bmin or o > bmax:
				return {}
			continue
		var inv := 1.0 / dd
		var t1 := (bmin - o) * inv
		var t2 := (bmax - o) * inv
		var entry_sign := 1.0 if dd > 0.0 else -1.0
		if t1 > t2:
			var tmp := t1
			t1 = t2
			t2 = tmp
		if t1 > t_min:
			t_min = t1
			normal = Vector2.ZERO
			normal[axis] = -entry_sign
		if t2 < t_max:
			t_max = t2
		if t_min > t_max:
			return {}
	if t_min < 0.0 or t_min > 1.0:
		return {}
	return {"t": t_min, "point": seg_from + d * t_min, "normal": normal}

## Finds the closest hit among colliders (each must expose global_position and half_size).
## inflate expands every box by this amount, used to sweep a circle of that radius as a point.
static func find_closest_hit(seg_from: Vector2, seg_to: Vector2, colliders: Array, inflate: float = 0.0) -> Dictionary:
	var best: Dictionary = {}
	var best_t := INF
	var pad := Vector2(inflate, inflate)
	for c in colliders:
		var box_min: Vector2 = c.global_position - c.half_size - pad
		var box_max: Vector2 = c.global_position + c.half_size + pad
		var res := segment_vs_aabb(seg_from, seg_to, box_min, box_max)
		if not res.is_empty() and res["t"] < best_t:
			best_t = res["t"]
			best = res
			best["target"] = c
	return best
