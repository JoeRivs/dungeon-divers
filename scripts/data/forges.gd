class_name Forges
extends RefCounted

## The forge-upgrade pool + the draw. Forges are RARE (one Forge room per
## floor, ~2 a run) and each rewires one ability. A draw only offers forges
## for abilities the player currently has mounted and hasn't already forged.


static func _all() -> Array[ForgeUpgrade]:
	var a: Array[ForgeUpgrade] = []

	# --- Knight ---------------------------------------------------------
	a.append(ForgeUpgrade.make(&"cleave", "Cleave",
		"Sword swings in a far wider arc and hits harder, but a touch slower.",
		&"sword"))
	a.append(ForgeUpgrade.make(&"split_shot", "Split Shot",
		"Bow looses three arrows in a spread instead of one.",
		&"bow"))

	# --- Warlock -------------------------------------------------------
	a.append(ForgeUpgrade.make(&"forked", "Forked Bolt",
		"Eldritch Bolt arcs on to a second enemy for half damage.",
		&"eldritch_bolt"))
	a.append(ForgeUpgrade.make(&"vampiric_font", "Vampiric Font",
		"Life Drain heals you for double.",
		&"life_drain"))
	a.append(ForgeUpgrade.make(&"cluster", "Cluster Bombs",
		"Fireball scatters three lesser bomblets where it bursts.",
		&"fireball"))
	a.append(ForgeUpgrade.make(&"barrage", "Barrage",
		"Magic Missile looses six darts instead of three.",
		&"magic_missile"))

	# --- Duelist ------------------------------------------------------
	a.append(ForgeUpgrade.make(&"third_strike", "Third Strike",
		"Every third Flurry hit lands as a crit and pays double Momentum.",
		&"flurry"))
	a.append(ForgeUpgrade.make(&"whirlwind", "Whirlwind",
		"Finisher sweeps a full circle instead of a frontal arc.",
		&"finisher"))
	a.append(ForgeUpgrade.make(&"killer_instinct", "Killer Instinct",
		"Ambush's double-damage opener triggers on the first hit of every "
		+ "swing, not just once per enemy.",
		&"ambush_strike"))
	a.append(ForgeUpgrade.make(&"cyclone", "Cyclone",
		"Whirl spins wider and longer, catching everything twice.",
		&"whirl"))

	return a


## Up to `count` forges valid for this player right now: the forge's
## ability_id must match a mounted ability, and must not already be taken.
static func draw_for(player: Node, taken: Array, count: int) -> Array[ForgeUpgrade]:
	var mounted: Dictionary = {}
	var slots: Dictionary = player.slots()
	for slot in slots:
		var ab = slots[slot]
		if is_instance_valid(ab) and ab.ability_id != &"":
			mounted[ab.ability_id] = true

	var taken_ids: Dictionary = {}
	for f in taken:
		taken_ids[f.ability_id] = true

	var pool: Array[ForgeUpgrade] = []
	for f in _all():
		if mounted.has(f.ability_id) and not taken_ids.has(f.ability_id):
			pool.append(f)

	pool.shuffle()
	if pool.size() > count:
		pool.resize(count)
	return pool
