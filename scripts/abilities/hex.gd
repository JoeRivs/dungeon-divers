extends Ability

## Warlock skill: lob a slow dark orb that bursts for heavy spell damage in
## a radius. High Soul cost, long cooldown.

const ORB := preload("res://scenes/projectiles/hex_orb.tscn")
# damage_dice (Vector2i(2, 6)) is exported on Ability
const BURST_RADIUS: float = 96.0
const MUZZLE: float = 16.0

## Detonator forge (Pyromancer-only, despite Hex being class-shared): the
## burst also detonates any Burn status it catches for bonus damage.
const DETONATE_MULT: float = 2.0

## Grim Harvest etching: the burst also marks everything it hits Weaken -
## no forge needed, ties Hex into the shared debuff system on its own.
const GRIM_HARVEST_WEAKEN: float = 0.2


func _perform(origin: Vector2, direction: Vector2) -> void:
	var dmg: Dictionary = wielder.compute_damage(damage_dice, damage_kind)
	var orb := ORB.instantiate()
	wielder.get_parent().add_child(orb)
	orb.setup(origin + direction.normalized() * MUZZLE, direction, dmg.amount, dmg.crit,
		BURST_RADIUS, has_forge(&"detonator"), DETONATE_MULT,
		has_etching(&"grim_harvest"), GRIM_HARVEST_WEAKEN)
