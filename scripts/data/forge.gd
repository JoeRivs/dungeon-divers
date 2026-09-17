class_name ForgeUpgrade
extends Resource

## A rare "rewire" for ONE ability - it changes how that ability behaves for
## the rest of the run, not a stat. Bound to an `ability_id`; the player
## applies it to whichever slot currently holds that ability (archetypes can
## move abilities between slots, so the slot isn't fixed here).

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var ability_id: StringName = &""

## &"" = any archetype with this ability mounted can be offered it (this is
## how the class-SHARED forges work, e.g. on Life Drain). Set to lock a
## forge to one archetype even on a shared ability - e.g. a Hex forge that
## only Pyromancer sees - without needing a whole separate ability scene.
@export var requires_archetype: StringName = &""

## Set only on a "new weapon" Forge: instead of rewiring the mounted
## ability, it REPLACES it outright with a different ability scene (its
## `ability_id` then becomes whatever that scene declares). Everything that
## keys off ability_id - Etching draws, other Forges - follows automatically.
@export var replacement_ability: PackedScene = null


static func make(id: StringName, display_name: String, description: String,
		ability_id: StringName, replacement_ability: PackedScene = null) -> ForgeUpgrade:
	var f := ForgeUpgrade.new()
	f.id = id
	f.display_name = display_name
	f.description = description
	f.ability_id = ability_id
	f.replacement_ability = replacement_ability
	return f
