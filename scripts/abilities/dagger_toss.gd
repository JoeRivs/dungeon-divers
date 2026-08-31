extends Ability

## Duelist secondary: a quick thrown blade so the Duelist isn't helpless at
## range. Weak, but cheap and it feeds a little Momentum just for committing
## to the throw.

const MUZZLE_OFFSET: float = 14.0
const MOMENTUM_PER_THROW: float = 3.0


func _perform(origin: Vector2, direction: Vector2) -> void:
	var dmg: Dictionary = wielder.compute_damage(damage_dice, damage_kind)
	var blade: Arrow = ProjectilePool.acquire_arrow()
	blade.launch(origin + direction.normalized() * MUZZLE_OFFSET, direction, dmg.amount, dmg.crit)
	wielder.gain_resource(MOMENTUM_PER_THROW)
