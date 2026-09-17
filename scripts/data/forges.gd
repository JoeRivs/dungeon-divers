class_name Forges
extends RefCounted

## The forge-upgrade pool + the draw. Forges are RARE (one Forge room per
## floor, ~2-3 a run) and each rewires one ability. Several can stack on the
## SAME ability - that's deliberate, it's where builds combo (see the
## Warlock roster below for the synergy pairings).
##
## Target shape per archetype: 6 unique forges (only it can be offered them)
## + 2 shared across every archetype in its class = 8 available picks.
## Currently fully built out for Warlock; Knight/Duelist still have their
## original smaller sets - same template, next pass.

const SPEAR := preload("res://scenes/abilities/spear_thrust.tscn")


static func _all() -> Array[ForgeUpgrade]:
	var a: Array[ForgeUpgrade] = []

	# --- Knight (TODO: expand to 6+2, same template as Warlock below) ----
	a.append(ForgeUpgrade.make(&"cleave", "Cleave",
		"Sword swings in a far wider arc and hits harder, but a touch slower.",
		&"sword"))
	a.append(ForgeUpgrade.make(&"split_shot", "Split Shot",
		"Bow looses three arrows in a spread instead of one.",
		&"bow"))
	a.append(ForgeUpgrade.make(&"spearhead", "Spearhead",
		"Replace the Sword with a Spear: a long straight thrust in a line "
		+ "instead of a swing. Less coverage, much more reach.",
		&"sword", SPEAR))

	# --- Warlock: 2 class-shared + 6 unique per archetype = 8 each -------

	a.append(ForgeUpgrade.make(&"vampiric_font", "Vampiric Font",
		"Life Drain heals you for double."
		, &"life_drain"))
	a.append(ForgeUpgrade.make(&"umbral_step", "Umbral Step",
		"Shadow Step lashes out on arrival, striking anything close by and "
		+ "marking it Weaken (+25% damage taken, briefly) for the rest of "
		+ "your kit to punish.",
		&"shadow_step"))

	# Occultist unique - Eldritch Bolt, precision/control identity.
	# Forked Bolt + Piercing Bolt = clear a clustered room in one cast.
	# Arc Reach + Executioner's Bolt = snipe the weakest thing on screen.
	# Soul Siphon is the glue - it keeps the whole kit's Soul flowing.
	a.append(_locked(ForgeUpgrade.make(&"forked", "Forked Bolt",
		"Eldritch Bolt arcs on to a second enemy for half damage.",
		&"eldritch_bolt"), &"occultist"))
	a.append(_locked(ForgeUpgrade.make(&"piercing_bolt", "Piercing Bolt",
		"Eldritch Bolt stops snapping to one target - it's a line now, and "
		+ "hits everything standing in it.",
		&"eldritch_bolt"), &"occultist"))
	a.append(_locked(ForgeUpgrade.make(&"charged_shot", "Charged Shot",
		"Every fourth bolt costs nothing to fire and hits twice as hard.",
		&"eldritch_bolt"), &"occultist"))
	a.append(_locked(ForgeUpgrade.make(&"executioners_bolt", "Executioner's Bolt",
		"Eldritch Bolt deals double damage to anything under 30% health.",
		&"eldritch_bolt"), &"occultist"))
	a.append(_locked(ForgeUpgrade.make(&"arc_reach", "Arc Reach",
		"Much longer range and a wider cone, and the bolt now seeks out "
		+ "the weakest enemy in range instead of the nearest.",
		&"eldritch_bolt"), &"occultist"))
	a.append(_locked(ForgeUpgrade.make(&"soul_siphon", "Soul Siphon",
		"A kill with Eldritch Bolt refunds a burst of Soul.",
		&"eldritch_bolt"), &"occultist"))

	# Pyromancer unique - Fireball, spreading-inferno identity.
	# Cluster Bombs + Molten Core + Wildfire = the room catches fire and
	# keeps catching fire. Detonator + Backdraft close the loop: burn kills
	# feed your Soul AND your Hex. Searing Body rewards standing in it.
	a.append(_locked(ForgeUpgrade.make(&"cluster", "Cluster Bombs",
		"Fireball scatters three lesser bomblets where it bursts.",
		&"fireball"), &"pyromancer"))
	a.append(_locked(ForgeUpgrade.make(&"wildfire", "Wildfire",
		"When your burn kills something, it leaps to the nearest enemy "
		+ "who isn't already burning.",
		&"fireball"), &"pyromancer"))
	a.append(_locked(ForgeUpgrade.make(&"molten_core", "Molten Core",
		"Fireball's burst radius grows by nearly half. Flies slower, costs "
		+ "a little extra Soul.",
		&"fireball"), &"pyromancer"))
	a.append(_locked(ForgeUpgrade.make(&"detonator", "Detonator",
		"Hex's burst detonates any burn it catches for a heavy bonus hit.",
		&"hex"), &"pyromancer"))
	a.append(_locked(ForgeUpgrade.make(&"backdraft", "Backdraft",
		"Killing a burning enemy pays you a burst of Soul regen.",
		&"fireball"), &"pyromancer"))
	a.append(_locked(ForgeUpgrade.make(&"searing_body", "Searing Body",
		"Casting Fireball wraps you in a brief damage-reduction ward.",
		&"fireball"), &"pyromancer"))

	# Conjurer unique - Magic Missile, split between two real builds.
	# Barrage + Volatile Missiles + Twin Cast = a missile storm that clears
	# a packed room. Homing Instinct + Overwhelm is the OPPOSITE read: stop
	# spreading out, dump every dart into one target and watch the focus
	# bonus stack - a dedicated boss-killer instead of a room-clearer.
	a.append(_locked(ForgeUpgrade.make(&"barrage", "Barrage",
		"Magic Missile looses six darts instead of three.",
		&"magic_missile"), &"conjurer"))
	a.append(_locked(ForgeUpgrade.make(&"homing_instinct", "Homing Instinct",
		"Darts turn far faster - they simply do not miss anymore.",
		&"magic_missile"), &"conjurer"))
	a.append(_locked(ForgeUpgrade.make(&"volatile_missiles", "Volatile Missiles",
		"Darts explode in a small burst on impact, catching anything close.",
		&"magic_missile"), &"conjurer"))
	a.append(_locked(ForgeUpgrade.make(&"twin_cast", "Twin Cast",
		"Magic Missile fires a second full volley right behind the first, "
		+ "for extra Soul.",
		&"magic_missile"), &"conjurer"))
	a.append(_locked(ForgeUpgrade.make(&"penetrating_missiles", "Penetrating Missiles",
		"Darts punch through their target to hit whoever's behind it.",
		&"magic_missile"), &"conjurer"))
	a.append(_locked(ForgeUpgrade.make(&"overwhelm", "Overwhelm",
		"While every dart is aimed at the same lone enemy, consecutive "
		+ "volleys stack a growing damage bonus against it.",
		&"magic_missile"), &"conjurer"))

	# --- Duelist (TODO: expand to 6+2, same template as Warlock above) ---
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


static func _locked(f: ForgeUpgrade, archetype_id: StringName) -> ForgeUpgrade:
	f.requires_archetype = archetype_id
	return f


## Up to `count` forges valid for this player right now: the ability must be
## mounted, the SPECIFIC forge not already taken (others on the same
## ability are fine - they're meant to stack), and any archetype lock met.
static func draw_for(player: Node, taken: Array, count: int) -> Array[ForgeUpgrade]:
	var mounted: Dictionary = {}
	var slots: Dictionary = player.slots()
	for slot in slots:
		var ab = slots[slot]
		if is_instance_valid(ab) and ab.ability_id != &"":
			mounted[ab.ability_id] = true

	var taken_ids: Dictionary = {}
	for f in taken:
		taken_ids[f.id] = true

	var pool: Array[ForgeUpgrade] = []
	for f in _all():
		if not mounted.has(f.ability_id):
			continue
		if taken_ids.has(f.id):
			continue
		if f.requires_archetype != &"" and f.requires_archetype != RunState.archetype_id:
			continue
		pool.append(f)

	pool.shuffle()
	if pool.size() > count:
		pool.resize(count)
	return pool
