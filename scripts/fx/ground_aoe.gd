extends Node2D

## Telegraphed hostile ground AoE. A crisp danger ring marks the zone the
## instant it spawns; a fill sweeps out to the edge and an inner ring closes
## in as a countdown; then it detonates once - flash + shockwave - hitting
## the player if they're still standing inside. Reusable by any enemy.

const SEGMENTS: int = 48

const RING_COL := Color(1.0, 0.42, 0.24, 0.92)
const FILL_COL := Color(1.0, 0.32, 0.14, 0.30)

var _radius: float = 80.0
var _damage: int = 0
var _windup: float = 0.8
var _t: float = 0.0
var _done: bool = false
var _flash: float = 0.0        ## detonation white-out, tweened 1 -> 0
var _shock: float = 0.0        ## shockwave expansion, tweened 0 -> 1


func setup(at: Vector2, radius: float, damage: int, windup: float) -> void:
	global_position = at.round()
	_radius = radius
	_damage = damage
	_windup = maxf(windup, 0.05)
	queue_redraw()


func _process(delta: float) -> void:
	queue_redraw()
	if _done:
		return
	_t += delta
	if _t >= _windup:
		_detonate()


func _detonate() -> void:
	_done = true
	var player := get_tree().get_first_node_in_group("player")
	if player != null and is_instance_valid(player) and player.has_method("apply_damage") \
			and player.global_position.distance_to(global_position) <= _radius:
		var dealt: int = player.apply_damage(_damage)
		if dealt > 0:
			FloatingText.spawn(player.global_position, dealt, false, true)

	_flash = 1.0
	var tween := create_tween()
	tween.parallel().tween_property(self, "_flash", 0.0, 0.26)
	tween.parallel().tween_property(self, "_shock", 1.0, 0.30)
	tween.tween_property(self, "modulate:a", 0.0, 0.08)
	tween.tween_callback(queue_free)


func _draw() -> void:
	if not _done:
		var progress: float = clampf(_t / _windup, 0.0, 1.0)
		# fill sweeping out toward the boundary
		draw_circle(Vector2.ZERO, _radius * progress, FILL_COL)
		# fixed danger boundary, shimmering so it reads as live
		var pulse: float = 0.72 + 0.28 * sin(_t * 13.0)
		_ring(_radius, Color(RING_COL.r, RING_COL.g, RING_COL.b, RING_COL.a * pulse), 3.0)
		# inner ring closing in on the edge = countdown to detonation
		var inner: float = _radius * (0.32 + 0.62 * progress)
		_ring(inner, Color(RING_COL.r, RING_COL.g, RING_COL.b, 0.45), 2.0)
	else:
		if _flash > 0.0:
			draw_circle(Vector2.ZERO, _radius, Color(1.0, 0.85, 0.55, 0.55 * _flash))
		var sr: float = lerpf(_radius * 0.65, _radius * 1.4, _shock)
		_ring(sr, Color(1.0, 0.6, 0.3, 0.85 * (1.0 - _shock)), 4.0)


func _ring(r: float, col: Color, width: float) -> void:
	var pts: PackedVector2Array = []
	for i in SEGMENTS + 1:
		pts.append(Vector2.RIGHT.rotated(TAU * float(i) / float(SEGMENTS)) * r)
	draw_polyline(pts, col, width, true)
