extends Node2D

## Fire-and-forget slash crescent. play() builds an arc facing a direction,
## then it scales up, fades, and frees itself. Melee attackers spawn one to
## connect their hit visually - same read as the player's sword swoosh.

const SEGMENTS: int = 14
const LIFE: float = 0.14

@onready var poly: Polygon2D = $Poly


func play(direction: Vector2, reach: float, thickness: float, color: Color, arc: float = 1.3) -> void:
	rotation = direction.angle()

	var outer: PackedVector2Array = []
	var inner: PackedVector2Array = []
	for i in SEGMENTS + 1:
		var t: float = float(i) / float(SEGMENTS)
		var a: float = lerpf(-arc * 0.5, arc * 0.5, t)
		var d := Vector2.from_angle(a)
		var taper: float = 0.4 + 0.6 * sin(t * PI)     # thin at both ends, fat mid
		outer.append(d * reach)
		inner.append(d * (reach - thickness * taper))

	var pts: PackedVector2Array = []
	pts.append_array(outer)
	for i in range(inner.size() - 1, -1, -1):
		pts.append(inner[i])

	poly.polygon = pts
	poly.color = color

	var tween := create_tween()
	tween.tween_property(poly, "scale", Vector2(1.15, 1.15), LIFE)
	tween.parallel().tween_property(poly, "modulate:a", 0.0, LIFE)
	tween.tween_callback(queue_free)
