class_name Classes
extends RefCounted

## Code-built class definitions. Fine for now; convert to authored
## res://data/classes/*.tres once someone wants to tune them in-editor.
##
## A class sets an attribute spread + a default 4-slot ability loadout.
## Archetypes shift attributes and can override individual slots or mount a
## passive hook. Everything numeric flows through Stats.

const SWORD := preload("res://scenes/abilities/sword_swing.tscn")
const BOW := preload("res://scenes/abilities/bow_shot.tscn")
const ROLL := preload("res://scenes/abilities/roll_dodge.tscn")
const BRACE := preload("res://scenes/abilities/brace.tscn")

const ELDRITCH_BOLT := preload("res://scenes/abilities/eldritch_bolt.tscn")
const LIFE_DRAIN := preload("res://scenes/abilities/life_drain.tscn")
const HEX := preload("res://scenes/abilities/hex.tscn")
const SHADOW_STEP := preload("res://scenes/abilities/shadow_step.tscn")
const FIREBALL := preload("res://scenes/abilities/fireball.tscn")
const MAGIC_MISSILE := preload("res://scenes/abilities/magic_missile.tscn")

const FLURRY := preload("res://scenes/abilities/flurry.tscn")
const DAGGER_TOSS := preload("res://scenes/abilities/dagger_toss.tscn")
const FINISHER := preload("res://scenes/abilities/finisher.tscn")
const BLADE_DASH := preload("res://scenes/abilities/blade_dash.tscn")
const AMBUSH_STRIKE := preload("res://scenes/abilities/ambush_strike.tscn")
const WHIRL := preload("res://scenes/abilities/whirl.tscn")

const SHADOW_HOOK := preload("res://scenes/archetypes/shadow_clone.tscn")
const KNIGHT_TEX := preload("res://assets/sprites/knight.png")


static func all() -> Array[PlayerClass]:
	return [knight(), warlock(), duelist()]


# --- Knight : melee bruiser -------------------------------------------------

static func knight() -> PlayerClass:
	var c := PlayerClass.new()
	c.id = &"knight"
	c.display_name = "Knight"
	c.body_texture = KNIGHT_TEX
	c.base_modifiers = [
		StatModifier.make(&"might", 3.0),
		StatModifier.make(&"vitality", 3.0),
		StatModifier.make(&"focus", -2.0),
	]
	c.primary_ability = SWORD
	c.secondary_ability = BOW
	c.dodge_ability = ROLL
	c.default_archetype = &"shadow"
	c.archetypes = [_shadow(), _tank(), _ranger()]
	return c


static func _shadow() -> Archetype:
	var a := Archetype.new()
	a.id = &"shadow"
	a.display_name = "Shadow"
	a.modifiers = [
		StatModifier.make(&"finesse", 2.0),
		StatModifier.make(&"might", -1.0),
	]
	a.hook_scene = SHADOW_HOOK
	return a


static func _tank() -> Archetype:
	var a := Archetype.new()
	a.id = &"tank"
	a.display_name = "Tank"
	a.modifiers = [
		StatModifier.make(&"vitality", 4.0),
		StatModifier.make(&"finesse", -3.0),
		StatModifier.make(&"damage_reduction", 0.1),
	]
	a.skill_ability = BRACE
	return a


static func _ranger() -> Archetype:
	var a := Archetype.new()
	a.id = &"ranger"
	a.display_name = "Ranger"
	a.modifiers = [
		StatModifier.make(&"finesse", 4.0),
		StatModifier.make(&"might", -2.0),
		StatModifier.make(&"vitality", -2.0),
		StatModifier.make(&"cooldown_mult", 0.0, 0.8),
	]
	a.primary_ability = BOW
	a.secondary_ability = SWORD
	return a


# --- Warlock : ranged caster, spends Soul --------------------------------

static func warlock() -> PlayerClass:
	var c := PlayerClass.new()
	c.id = &"warlock"
	c.display_name = "Warlock"
	# lean caster chassis - the archetype decides the Soul economy and body type
	c.base_modifiers = [
		StatModifier.make(&"focus", 5.0),
		StatModifier.make(&"might", -3.0),
		StatModifier.make(&"vitality", -1.0),
		StatModifier.make(&"resource_max", 45.0),
		StatModifier.make(&"resource_regen", 2.0),
	]
	c.pool_name = "Soul"
	c.primary_ability = ELDRITCH_BOLT
	c.secondary_ability = LIFE_DRAIN
	c.skill_ability = HEX
	c.dodge_ability = SHADOW_STEP
	c.default_archetype = &"occultist"
	c.archetypes = [_occultist(), _pyromancer(), _conjurer()]
	return c


## Eldritch Bolt: free single-target hitscan. The reference build - mid-range
## poke, light on its feet, average frame. Spends Soul only on Drain / Hex.
static func _occultist() -> Archetype:
	var a := Archetype.new()
	a.id = &"occultist"
	a.display_name = "Occultist"
	a.modifiers = [
		StatModifier.make(&"focus", 2.0),
		StatModifier.make(&"finesse", 2.0),
		StatModifier.make(&"resource_max", 15.0),
		StatModifier.make(&"resource_regen", 2.0),
	]
	return a


## Fireball: AoE + burn, and it COSTS Soul - the only Warlock whose primary
## drains the pool. So it gets the deepest Soul and the fastest regen, plus
## the extra Vitality and speed to fight at the close-mid range the AoE wants.
static func _pyromancer() -> Archetype:
	var a := Archetype.new()
	a.id = &"pyromancer"
	a.display_name = "Pyromancer"
	a.modifiers = [
		StatModifier.make(&"focus", 2.0),
		StatModifier.make(&"vitality", 3.0),
		StatModifier.make(&"move_speed", 15.0),
		StatModifier.make(&"resource_max", 45.0),
		StatModifier.make(&"resource_regen", 5.0),
	]
	a.primary_ability = FIREBALL
	return a


## Magic Missile: free homing darts, no aim needed - so this build plants and
## turtles while the darts do the work. Heaviest Vitality + damage reduction,
## slowest feet, smallest Soul pool (its primary is free).
static func _conjurer() -> Archetype:
	var a := Archetype.new()
	a.id = &"conjurer"
	a.display_name = "Conjurer"
	a.modifiers = [
		StatModifier.make(&"focus", 3.0),
		StatModifier.make(&"vitality", 5.0),
		StatModifier.make(&"finesse", -4.0),
		StatModifier.make(&"damage_reduction", 0.06),
	]
	a.primary_ability = MAGIC_MISSILE
	return a


# --- Duelist : fast, fragile hit-and-run melee, runs on Momentum -----------

## Momentum is the inverse of the Warlock's Soul: it spawns EMPTY, decays
## when you're not fighting (negative regen), and builds as you land hits and
## dash. The skill dumps the whole pool into a scaling finisher. Glassy on
## purpose - the trade for the speed and the burst.
static func duelist() -> PlayerClass:
	var c := PlayerClass.new()
	c.id = &"duelist"
	c.display_name = "Duelist"
	c.body_style = &"rogue"
	c.base_modifiers = [
		StatModifier.make(&"finesse", 4.0),
		StatModifier.make(&"might", 1.0),
		StatModifier.make(&"vitality", -2.0),
		StatModifier.make(&"focus", -2.0),
		StatModifier.make(&"resource_max", 100.0),
		StatModifier.make(&"resource_regen", -6.0),   # Momentum bleeds when idle
	]
	c.pool_name = "Momentum"
	c.resource_starts_full = false
	c.primary_ability = FLURRY
	c.secondary_ability = DAGGER_TOSS
	c.skill_ability = FINISHER
	c.dodge_ability = BLADE_DASH
	c.default_archetype = &"bladedancer"
	c.archetypes = [_bladedancer(), _assassin(), _windblade()]
	return c


## The reference build: balanced, finisher-centric. Momentum decays slower, so
## you can reliably bank a big Finisher every fight.
static func _bladedancer() -> Archetype:
	var a := Archetype.new()
	a.id = &"bladedancer"
	a.display_name = "Bladedancer"
	a.modifiers = [
		StatModifier.make(&"finesse", 2.0),
		StatModifier.make(&"might", 2.0),
		StatModifier.make(&"vitality", 1.0),
		StatModifier.make(&"resource_regen", 2.0),   # net decay -4 instead of -6
	]
	return a


## Glassy single-target killer. First strike on a fresh enemy (Ambush) hits
## for double and pays bonus Momentum - open hard, then finish.
static func _assassin() -> Archetype:
	var a := Archetype.new()
	a.id = &"assassin"
	a.display_name = "Assassin"
	a.modifiers = [
		StatModifier.make(&"might", 3.0),
		StatModifier.make(&"finesse", 3.0),
	]
	a.primary_ability = AMBUSH_STRIKE
	return a


## Group skirmisher. Primary becomes Whirl - a 360 spin that hits everything
## in reach and pays Momentum per body. Fastest feet, a touch less fragile.
static func _windblade() -> Archetype:
	var a := Archetype.new()
	a.id = &"windblade"
	a.display_name = "Windblade"
	a.modifiers = [
		StatModifier.make(&"finesse", 5.0),
		StatModifier.make(&"vitality", 2.0),
		StatModifier.make(&"might", -1.0),
	]
	a.primary_ability = WHIRL
	return a
