class_name Classes
extends RefCounted

## Code-built class definitions. Fine for now; convert to authored
## res://data/classes/*.tres once someone wants to tune them in-editor.
##
## Classes set their attribute spread; archetypes shift attributes further
## (plus a couple of direct stat tweaks). Everything flows through Stats'
## derivation, so upgrades that touch attributes affect these the same way.

const SHADOW_HOOK := preload("res://scenes/archetypes/shadow_clone.tscn")
const TANK_HOOK := preload("res://scenes/archetypes/tank_brace.tscn")
const RANGER_HOOK := preload("res://scenes/archetypes/ranger_loadout.tscn")


static func knight() -> PlayerClass:
	var c := PlayerClass.new()
	c.id = &"knight"
	c.display_name = "Knight"
	# bruiser: strong and sturdy, unremarkable finesse, no arcane knack
	c.base_modifiers = [
		StatModifier.make(&"might", 3.0),
		StatModifier.make(&"vitality", 3.0),
		StatModifier.make(&"focus", -2.0),
	]
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
	a.hook_scene = TANK_HOOK
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
	a.hook_scene = RANGER_HOOK
	return a
