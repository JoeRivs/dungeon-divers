extends Ability

## Pyromancer primary: a slow fireball that bursts for spell AoE and burns
## everything it catches. Costs a little Soul - a chunkier rhythm than the
## free lightning.

const PROJ := preload("res://scenes/projectiles/fireball_proj.tscn")
const MUZZLE: float = 16.0
const BURN_TICKS: int = 5
const BURN_FRACTION: float = 0.5      ## per-tick burn as a share of the hit


func _perform(origin: Vector2, direction: Vector2) -> void:
	var dmg: Dictionary = wielder.compute_damage(damage_dice, damage_kind)
	var per_tick: int = maxi(int(round(float(dmg.amount) * BURN_FRACTION)), 1)

	var proj := PROJ.instantiate()
	wielder.get_parent().add_child(proj)
	proj.setup(origin + direction.normalized() * MUZZLE, direction, dmg.amount, dmg.crit,
		BURN_TICKS, per_tick, forge_id == &"cluster")
