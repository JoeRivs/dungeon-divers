class_name PlayerClass
extends Resource

## A starting class. base_modifiers are class-wide tweaks that apply
## regardless of archetype; archetypes are the build paths within it.

@export var id: StringName = &""
@export var display_name: String = ""
@export var base_modifiers: Array[StatModifier] = []
@export var archetypes: Array[Archetype] = []
@export var default_archetype: StringName = &""


func get_archetype(aid: StringName) -> Archetype:
	for a in archetypes:
		if a.id == aid:
			return a
	return archetypes[0] if not archetypes.is_empty() else null
