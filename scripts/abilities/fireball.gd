extends Ability

## Pyromancer primary: a slow fireball that bursts for spell AoE and burns
## everything it catches. Costs a little Soul - a chunkier rhythm than the
## free lightning.

const PROJ := preload("res://scenes/projectiles/fireball_proj.tscn")
const MUZZLE: float = 16.0
const BURN_TICKS: int = 5
const BURN_FRACTION: float = 0.5      ## per-tick burn as a share of the hit

## Molten Core forge: bigger burst, slower flight, costs extra Soul.
const MOLTEN_RADIUS_MULT: float = 1.45
const MOLTEN_SPEED_MULT: float = 0.7
const MOLTEN_EXTRA_COST: float = 6.0

## Searing Body forge: casting grants a brief self damage-reduction buff.
const SEARING_DR: float = 0.12
const SEARING_DURATION: float = 2.2


func _perform(origin: Vector2, direction: Vector2) -> void:
	var dmg: Dictionary = wielder.compute_damage(damage_dice, damage_kind)
	var per_tick: int = maxi(int(round(float(dmg.amount) * BURN_FRACTION)), 1)

	var radius_mult: float = 1.0
	var speed_mult: float = 1.0
	if has_forge(&"molten_core"):
		radius_mult = MOLTEN_RADIUS_MULT
		speed_mult = MOLTEN_SPEED_MULT
		wielder.spend_resource(MOLTEN_EXTRA_COST)

	var proj := PROJ.instantiate()
	wielder.get_parent().add_child(proj)
	proj.setup(origin + direction.normalized() * MUZZLE, direction, dmg.amount, dmg.crit,
		BURN_TICKS, per_tick, has_forge(&"cluster"), radius_mult, speed_mult,
		wielder, has_forge(&"wildfire"), has_forge(&"backdraft"),
		has_forge(&"molten_core") and has_etching(&"ashfall"))

	if has_forge(&"searing_body"):
		wielder.stats.add_modifiers([StatModifier.make(&"damage_reduction", SEARING_DR)], &"searing_body")
		get_tree().create_timer(SEARING_DURATION).timeout.connect(
			func() -> void:
				if is_instance_valid(wielder):
					wielder.stats.clear_source(&"searing_body")
		)
