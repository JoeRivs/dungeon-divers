class_name RoomLayout
extends RefCounted

## Light procedural layout for a combat room: a randomised footprint size
## plus a handful of interior obstacle blocks, drawn from a few presets.
## Obstacles are Rect2 in the arena's local space (position = top-left).
## Nothing fancy - shape + cover, not maze generation.

const PERIM_MARGIN: float = 46.0    ## keep obstacles off the walls
const OBSTACLE_GAP: float = 48.0    ## walkable gap between obstacles
const ENTRY_CLEAR: float = 140.0    ## south strip left open (spawn-in)
const DOOR_CLEAR: float = 120.0     ## north strip left open (exits)
const CENTER_CLEAR: float = 78.0    ## breathing room at the middle


static func for_combat(difficulty: int, floor_index: int) -> Dictionary:
	var hw: float = randf_range(340.0, 500.0) + float(floor_index - 1) * 8.0
	var hh: float = randf_range(250.0, 360.0) + float(floor_index - 1) * 6.0
	var preset: String = _pick_preset()
	var obstacles: Array = _obstacles_for(preset, hw, hh, difficulty)
	return { "half_width": hw, "half_height": hh, "obstacles": obstacles, "preset": preset }


static func block(center: Vector2, size: Vector2) -> Rect2:
	return Rect2(center - size * 0.5, size)


## True if a circle of `radius` at local point `p` overlaps any obstacle.
static func point_blocked(obstacles: Array, p: Vector2, radius: float) -> bool:
	for o in obstacles:
		if (o as Rect2).grow(radius).has_point(p):
			return true
	return false


static func _pick_preset() -> String:
	var r: float = randf()
	if r < 0.28:
		return "open"
	if r < 0.56:
		return "scattered"
	if r < 0.82:
		return "pillars"
	return "split"


static func _obstacles_for(preset: String, hw: float, hh: float, difficulty: int) -> Array:
	if preset == "split":
		return _split_bar(hw, hh)

	var count: int = 0
	match preset:
		"open":
			count = randi_range(1, 2)
		"scattered":
			count = randi_range(3, 4)
		"pillars":
			count = randi_range(4, 6)
	if difficulty <= 6:
		count += 1

	var out: Array = []
	var attempts: int = 0
	while out.size() < count and attempts < count * 26:
		attempts += 1
		var size := Vector2(randf_range(42.0, 92.0), randf_range(42.0, 86.0))
		var c := Vector2(
			randf_range(-hw + PERIM_MARGIN + size.x * 0.5, hw - PERIM_MARGIN - size.x * 0.5),
			randf_range(-hh + DOOR_CLEAR + size.y * 0.5, hh - ENTRY_CLEAR - size.y * 0.5))
		if c.length() < CENTER_CLEAR + size.length() * 0.5:
			continue
		var r := block(c, size)
		var clash: bool = false
		for o in out:
			if r.grow(OBSTACLE_GAP).intersects(o):
				clash = true
				break
		if not clash:
			out.append(r)
	return out


## Two stub bars leaving a walkable gap across the middle - the closest thing
## to a differently shaped room without touching the boundary.
static func _split_bar(hw: float, hh: float) -> Array:
	if randf() < 0.5:
		# vertical divide
		var x: float = randf_range(-hw * 0.32, hw * 0.32)
		var run: float = (hh - DOOR_CLEAR - ENTRY_CLEAR)
		var bar: float = run * 0.42
		return [
			block(Vector2(x, -hh + DOOR_CLEAR + bar * 0.5), Vector2(40.0, bar)),
			block(Vector2(x, hh - ENTRY_CLEAR - bar * 0.5), Vector2(40.0, bar)),
		]
	# horizontal divide
	var y: float = randf_range(-hh * 0.15, hh * 0.25)
	var bar_w: float = (hw - PERIM_MARGIN * 2.0) * 0.42
	return [
		block(Vector2(-hw + PERIM_MARGIN + bar_w * 0.5, y), Vector2(bar_w, 40.0)),
		block(Vector2(hw - PERIM_MARGIN - bar_w * 0.5, y), Vector2(bar_w, 40.0)),
	]
