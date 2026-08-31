extends Ability

## Warlock skill: lob a slow dark orb that bursts for heavy spell damage in
## a radius. High Soul cost, long cooldown.

const ORB := preload("res://scenes/projectiles/hex_orb.tscn")
# damage_dice (Vector2i(2, 6)) is exported on Ability
const BURST_RADIUS: float = 96.0
const MUZZLE: float = 16.0


func _perform(origin: Vector2, direction: Vector2) -> void:
	var dmg: Dictionary = wielder.compute_damage(damage_dice, damage_kind)
	var orb := ORB.instantiate()
	wielder.get_parent().add_child(orb)
	orb.setup(origin + direction.normalized() * MUZZLE, direction, dmg.amount, dmg.crit, BURST_RADIUS)
