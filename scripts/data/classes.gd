class_name Classes
extends RefCounted

## Code-built class definitions. Fine for now; convert to authored
## res://data/classes/*.tres once someone wants to tune them in-editor -
## PlayerClass / Archetype / StatModifier already support it.

const SHADOW_HOOK := preload("res://scenes/archetypes/shadow_clone.tscn")
const TANK_HOOK := preload("res://scenes/archetypes/tank_brace.tscn")
const RANGER_HOOK := preload("res://scenes/archetypes/ranger_loadout.tscn")


static func knight() -> PlayerClass:
	var c := PlayerClass.new()
	c.id = &"knight"
	c.display_name = "Knight"
	c.base_modifiers = [StatModifier.make(&"max_health", 6.0)]
	c.default_archetype = &"shadow"
	c.archetypes = [_shadow(), _tank(), _ranger()]
	return c


static func _shadow() -> Archetype:
	var a := Archetype.new()
	a.id = &"shadow"
	a.display_name = "Shadow"
	a.modifiers = [
		StatModifier.make(&"move_speed", 10.0),
		StatModifier.make(&"damage_mult", 0.0, 0.9),
	]
	a.hook_scene = SHADOW_HOOK
	return a


static func _tank() -> Archetype:
	var a := Archetype.new()
	a.id = &"tank"
	a.display_name = "Tank"
	a.modifiers = [
		StatModifier.make(&"max_health", 14.0),
		StatModifier.make(&"move_speed", -30.0),
		StatModifier.make(&"damage_reduction", 0.1),
	]
	a.hook_scene = TANK_HOOK
	return a


static func _ranger() -> Archetype:
	var a := Archetype.new()
	a.id = &"ranger"
	a.display_name = "Ranger"
	a.modifiers = [
		StatModifier.make(&"max_health", -6.0),
		StatModifier.make(&"move_speed", 20.0),
		StatModifier.make(&"cooldown_mult", 0.0, 0.8),
	]
	a.hook_scene = RANGER_HOOK
	return a
