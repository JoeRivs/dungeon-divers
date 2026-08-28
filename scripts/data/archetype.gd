class_name Archetype
extends Resource

## A build path within a class. Its stat modifiers are applied to the player,
## and its hook_scene (a small self-contained behaviour node) is instanced as
## a child of the player - that's the archetype's signature mechanic.

@export var id: StringName = &""
@export var display_name: String = ""
@export var modifiers: Array[StatModifier] = []
@export var hook_scene: PackedScene = null
