class_name Upgrades
extends RefCounted

## The upgrade pool. Entries are small and REPEATABLE - a long run (10+ rooms
## a floor) is meant to build up gradually, not spike. Tier is magnitude:
## tier 1 tiny and common, tier 4 chunky and rare even in a tier-4 room.

## base draw weight per tier, before the room-tier boost
const TIER_WEIGHT := { 1: 100.0, 2: 24.0, 3: 6.0, 4: 1.8 }
## the room's own tier gets this multiplier; one tier below gets NEAR
const ROOM_MATCH_BOOST: float = 3.0
const ROOM_NEAR_BOOST: float = 1.7


static func _all() -> Array[Upgrade]:
	var a: Array[Upgrade] = []

	# --- tier 1 : common, tiny -------------------------------------------
	a.append(Upgrade.make(&"might_1", "Brawn", "+1 Might", 1,
		[StatModifier.make(&"might", 1.0)]))
	a.append(Upgrade.make(&"fin_1", "Quickstep", "+1 Finesse", 1,
		[StatModifier.make(&"finesse", 1.0)]))
	a.append(Upgrade.make(&"vit_1", "Toughness", "+1 Vitality", 1,
		[StatModifier.make(&"vitality", 1.0)]))
	a.append(Upgrade.make(&"dmg_1", "Whetstone", "+3% damage", 1,
		[StatModifier.make(&"damage_mult", 0.03)]))
	a.append(Upgrade.make(&"spd_1", "Light Step", "+8 move speed", 1,
		[StatModifier.make(&"move_speed", 8.0)]))
	a.append(Upgrade.make(&"hp_1", "Field Rations", "+5 max HP", 1,
		[StatModifier.make(&"max_health", 5.0)]))
	a.append(Upgrade.make(&"gold_1", "Coin Purse", "+15 gold", 1, [], &"gold15"))
	a.append(Upgrade.make(&"heal_1", "Poultice", "Heal 12", 1, [], &"heal12"))

	# --- tier 2 : uncommon --------------------------------------------------
	a.append(Upgrade.make(&"might_2", "Power", "+2 Might", 2,
		[StatModifier.make(&"might", 2.0)]))
	a.append(Upgrade.make(&"fin_2", "Deft", "+2 Finesse", 2,
		[StatModifier.make(&"finesse", 2.0)]))
	a.append(Upgrade.make(&"vit_2", "Hardy", "+2 Vitality", 2,
		[StatModifier.make(&"vitality", 2.0)]))
	a.append(Upgrade.make(&"dmg_2", "Sharpened", "+7% damage", 2,
		[StatModifier.make(&"damage_mult", 0.07)]))
	a.append(Upgrade.make(&"cd_2", "Fluid Motion", "-6% cooldowns", 2,
		[StatModifier.make(&"cooldown_mult", 0.0, 0.94)]))
	a.append(Upgrade.make(&"dr_2", "Padding", "+4% damage reduction", 2,
		[StatModifier.make(&"damage_reduction", 0.04)]))

	# --- tier 3 : rare ---------------------------------------------------
	a.append(Upgrade.make(&"mix_3a", "Juggernaut", "+2 Might, +6% damage", 3,
		[StatModifier.make(&"might", 2.0), StatModifier.make(&"damage_mult", 0.06)]))
	a.append(Upgrade.make(&"mix_3b", "Bladedancer", "+2 Finesse, +10 speed", 3,
		[StatModifier.make(&"finesse", 2.0), StatModifier.make(&"move_speed", 10.0)]))
	a.append(Upgrade.make(&"mix_3c", "Ironhide", "+2 Vitality, +4% reduction", 3,
		[StatModifier.make(&"vitality", 2.0), StatModifier.make(&"damage_reduction", 0.04)]))
	a.append(Upgrade.make(&"cd_3", "Momentum", "-10% cooldowns", 3,
		[StatModifier.make(&"cooldown_mult", 0.0, 0.90)]))

	# --- tier 4 : very rare -------------------------------------------
	a.append(Upgrade.make(&"mix_4a", "Titan", "+3 Might, +10% damage", 4,
		[StatModifier.make(&"might", 3.0), StatModifier.make(&"damage_mult", 0.10)]))
	a.append(Upgrade.make(&"mix_4b", "Unbroken", "+3 Vitality, +6% reduction", 4,
		[StatModifier.make(&"vitality", 3.0), StatModifier.make(&"damage_reduction", 0.06)]))
	a.append(Upgrade.make(&"mix_4c", "Flash", "+3 Finesse, -8% cooldowns", 4,
		[StatModifier.make(&"finesse", 3.0), StatModifier.make(&"cooldown_mult", 0.0, 0.92)]))
	a.append(Upgrade.make(&"omni_4", "Ascendant", "+1 to every attribute", 4,
		[StatModifier.make(&"might", 1.0), StatModifier.make(&"finesse", 1.0),
		StatModifier.make(&"vitality", 1.0), StatModifier.make(&"focus", 1.0)]))

	return a


## `count` distinct options for one pick. Draws from every tier up to the
## room's, weighted hard toward the low tiers; the room tier only nudges its
## own band up. Never above the room tier. Repeats across rooms are fine.
static func draw(tier: int, count: int) -> Array[Upgrade]:
	var pool: Array[Upgrade] = []
	var weights: Array[float] = []
	for u in _all():
		if u.tier > tier:
			continue
		pool.append(u)
		var w: float = TIER_WEIGHT.get(u.tier, 1.0)
		if u.tier == tier:
			w *= ROOM_MATCH_BOOST
		elif u.tier == tier - 1:
			w *= ROOM_NEAR_BOOST
		weights.append(w)

	var picked: Array[Upgrade] = []
	while picked.size() < count and not pool.is_empty():
		var total: float = 0.0
		for w in weights:
			total += w
		var roll: float = randf() * total
		var idx: int = pool.size() - 1
		for i in weights.size():
			roll -= weights[i]
			if roll <= 0.0:
				idx = i
				break
		picked.append(pool[idx])
		pool.remove_at(idx)
		weights.remove_at(idx)
	return picked
