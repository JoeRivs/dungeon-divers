class_name Etchings
extends RefCounted

## The Etching pool + the draw. Deliberately shared much harder than Forges
## are - most Etchings here apply to several archetypes, or need nothing
## but the ability mounted, so there's real variability before a single
## Forge room has even been found.


static func _all() -> Array[Etching]:
	var a: Array[Etching] = []

	# --- Sword: a 2-node combo chain -----------------------------------
	a.append(Etching.make(&"bleeding_edge", "Bleeding Edge",
		"Sword hits apply a stacking bleed.",
		&"sword"))
	a.append(Etching.make(&"hemorrhage", "Hemorrhage",
		"A bleed at max stacks bursts for a heavy hit and clears - a free "
		+ "execute on a target you've been cutting up.",
		&"sword", &"", &"bleeding_edge"))

	# --- Eldritch Bolt (Occultist) ----------------------------------------
	a.append(Etching.make(&"static_charge", "Static Charge",
		"Killing a bolted enemy leaves a small lightning pulse that nicks "
		+ "anything standing near it.",
		&"eldritch_bolt"))
	a.append(Etching.make(&"overcharge_chain", "Overcharge Chain",
		"Forked Bolt's chain can jump again, to a third enemy.",
		&"eldritch_bolt", &"forked"))

	# --- Fireball (Pyromancer) --------------------------------------------
	a.append(Etching.make(&"ashfall", "Ashfall",
		"Molten Core's burst also marks everything it catches Weaken.",
		&"fireball", &"molten_core"))

	# --- Shadow Step (class-shared) ---------------------------------------
	a.append(Etching.make(&"cinder_step", "Cinder Step",
		"Umbral Step's burst also ignites whatever it hits.",
		&"shadow_step", &"umbral_step"))
	a.append(Etching.make(&"quickened_step", "Quickened Step",
		"Shadow Step's cooldown is noticeably shorter. No Forge needed.",
		&"shadow_step"))

	# --- Life Drain (class-shared) -----------------------------------------
	a.append(Etching.make(&"soulbound", "Soulbound",
		"Life Drain costs less Soul to cast. No Forge needed.",
		&"life_drain"))

	# --- Hex (class-shared) -------------------------------------------------
	a.append(Etching.make(&"grim_harvest", "Grim Harvest",
		"Hex's burst also marks everything it hits Weaken. No Forge needed.",
		&"hex"))

	# --- Magic Missile (Conjurer) -------------------------------------------
	a.append(Etching.make(&"ricochet", "Ricochet",
		"Penetrating Missiles punch through to a THIRD enemy.",
		&"magic_missile", &"penetrating_missiles"))
	a.append(Etching.make(&"critical_mass", "Critical Mass",
		"Volatile Missiles' explosion also marks what it catches Weaken.",
		&"magic_missile", &"volatile_missiles"))

	# --- Flurry (Duelist) ------------------------------------------------
	a.append(Etching.make(&"bloodrush", "Bloodrush",
		"Landing three Flurry hits without missing grants a burst of "
		+ "Momentum and a kick of speed.",
		&"flurry"))

	# --- Spear (the weapon a Forge can swap Sword into) -------------------
	a.append(Etching.make(&"impale", "Impale",
		"Spear thrusts skewer one extra enemy standing behind the first.",
		&"spear"))

	return a


## Up to `count` Etchings valid right now: the ability must be mounted, the
## Etching not already taken, and any Forge / Etching / archetype gate met.
static func draw_for(player: Node, taken: Array, forges_taken: Array, count: int) -> Array[Etching]:
	var mounted: Dictionary = {}
	var slots: Dictionary = player.slots()
	for slot in slots:
		var ab = slots[slot]
		if is_instance_valid(ab) and ab.ability_id != &"":
			mounted[ab.ability_id] = true

	var taken_ids: Dictionary = {}
	for e in taken:
		taken_ids[e.id] = true
	var forge_ids: Dictionary = {}
	for f in forges_taken:
		forge_ids[f.id] = true

	var pool: Array[Etching] = []
	for e in _all():
		if not mounted.has(e.ability_id):
			continue
		if taken_ids.has(e.id):
			continue
		if e.requires_forge != &"" and not forge_ids.has(e.requires_forge):
			continue
		if e.requires_etching != &"" and not taken_ids.has(e.requires_etching):
			continue
		if e.requires_archetype != &"" and e.requires_archetype != RunState.archetype_id:
			continue
		pool.append(e)

	pool.shuffle()
	if pool.size() > count:
		pool.resize(count)
	return pool
