class_name Archetype
extends Resource

## A build path within a class. Its stat modifiers apply on top of the class,
## it can override individual ability slots, and it can mount a passive hook
## scene as a child of the player (its signature mechanic).

@export var id: StringName = &""
@export var display_name: String = ""
@export var modifiers: Array[StatModifier] = []
@export var hook_scene: PackedScene = null

## optional per-slot ability overrides (null = keep the class's)
@export var primary_ability: PackedScene
@export var secondary_ability: PackedScene
@export var skill_ability: PackedScene
@export var dodge_ability: PackedScene


func ability_for(slot: StringName) -> PackedScene:
	match slot:
		&"primary": return primary_ability
		&"secondary": return secondary_ability
		&"skill": return skill_ability
		&"dodge": return dodge_ability
	return null
