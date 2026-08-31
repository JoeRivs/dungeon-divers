extends Node2D

## A one-shot lightning arc drawn from A to B: jagged, flashes, fades, frees
## itself. Node sits at A; points are built in local space toward B.

@onready var glow: Line2D = $Glow
@onready var core: Line2D = $Core


func play(from: Vector2, to: Vector2, tint: Color) -> void:
	global_position = from
	var seg: Vector2 = to - from
	var length: float = maxf(seg.length(), 1.0)
	var dir: Vector2 = seg / length
	var perp: Vector2 = dir.orthogonal()

	var count: int = clampi(int(length / 16.0), 3, 22)
	var pts: PackedVector2Array = []
	for i in count + 1:
		var t: float = float(i) / float(count)
		var jitter: float = 0.0 if (i == 0 or i == count) else randf_range(-10.0, 10.0)
		pts.append(dir * (length * t) + perp * jitter)
	glow.points = pts
	core.points = pts
	core.default_color = tint

	modulate = Color(1, 1, 1, 1)
	var tween := create_tween()
	tween.tween_interval(0.04)
	tween.tween_property(self, "modulate:a", 0.0, 0.13)
	tween.tween_callback(queue_free)
