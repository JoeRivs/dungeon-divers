extends Ability

## Ranged: rolls damage through the wielder's stats and launches a pooled
## arrow toward the aim direction.

# damage_dice (Vector2i(1, 4)) is exported on Ability
const MUZZLE_OFFSET: float = 16.0

## Split Shot forge: three arrows in a spread, each rolled independently.
const SPLIT_SPREAD: float = 0.16      ## radians between arrows
const SPLIT_DAMAGE_MULT: float = 0.75


func _perform(origin: Vector2, direction: Vector2) -> void:
	var dir: Vector2 = direction.normalized()
	if forge_id == &"split_shot":
		for k in [-1.0, 0.0, 1.0]:
			var d: Vector2 = dir.rotated(k * SPLIT_SPREAD)
			var dmg: Dictionary = wielder.compute_damage(damage_dice, damage_kind)
			var amount: int = maxi(int(round(dmg.amount * SPLIT_DAMAGE_MULT)), 1)
			var a: Arrow = ProjectilePool.acquire_arrow()
			a.launch(origin + d * MUZZLE_OFFSET, d, amount, dmg.crit)
		return

	var dmg: Dictionary = wielder.compute_damage(damage_dice, damage_kind)
	var arrow: Arrow = ProjectilePool.acquire_arrow()
	arrow.launch(origin + dir * MUZZLE_OFFSET, dir, dmg.amount, dmg.crit)
