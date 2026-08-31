extends Ability

## Warlock dodge: an instant blink in the aim / move direction, stopping at
## walls, with brief i-frames. No mana. You keep moving through it.

const BLINK_DIST: float = 108.0
const IFRAMES: float = 0.34
const PUFF_COLOR := Color(0.35, 0.15, 0.5, 0.6)


func _perform(_origin: Vector2, direction: Vector2) -> void:
	var dir: Vector2 = direction if direction != Vector2.ZERO else wielder.facing()
	_puff(wielder.global_position)
	wielder.blink(dir.normalized() * BLINK_DIST, IFRAMES)
	_puff(wielder.global_position)


func _puff(at: Vector2) -> void:
	var puff := Polygon2D.new()
	puff.color = PUFF_COLOR
	puff.z_index = 2
	var pts: PackedVector2Array = []
	for i in 8:
		pts.append(Vector2.RIGHT.rotated(TAU * float(i) / 8.0) * 15.0)
	puff.polygon = pts
	wielder.get_parent().add_child(puff)
	puff.global_position = at
	var tween := puff.create_tween()
	tween.tween_property(puff, "modulate:a", 0.0, 0.2)
	tween.tween_callback(puff.queue_free)
