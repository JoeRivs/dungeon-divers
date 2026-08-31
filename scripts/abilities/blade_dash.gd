extends Ability

## Duelist dodge: a snappy repositioning dash with i-frames. Shorter cooldown
## than a Knight's roll and it feeds Momentum - dashing is part of the
## Duelist's offense, not just an escape.

const DASH_SPEED: float = 680.0
const DASH_DURATION: float = 0.16
const DASH_IFRAMES: float = 0.20
const MOMENTUM_PER_DASH: float = 14.0


func _perform(_origin: Vector2, direction: Vector2) -> void:
	var dir: Vector2 = direction if direction != Vector2.ZERO else wielder.facing()
	wielder.dash(dir.normalized() * DASH_SPEED, DASH_DURATION, DASH_IFRAMES)
	wielder.gain_resource(MOMENTUM_PER_DASH)
