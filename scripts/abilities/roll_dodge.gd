extends Ability

## Knight dodge: a short committed dash with brief i-frames, in the movement
## direction (or the aim direction if standing still).

const DASH_SPEED: float = 620.0
const DASH_DURATION: float = 0.18
const DASH_IFRAMES: float = 0.20


func _perform(_origin: Vector2, direction: Vector2) -> void:
	var dir: Vector2 = direction if direction != Vector2.ZERO else wielder.facing()
	wielder.dash(dir.normalized() * DASH_SPEED, DASH_DURATION, DASH_IFRAMES)
