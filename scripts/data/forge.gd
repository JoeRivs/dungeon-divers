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


static func make(id: StringName, display_name: String, description: String,
		ability_id: StringName) -> ForgeUpgrade:
	var f := ForgeUpgrade.new()
	f.id = id
	f.display_name = display_name
	f.description = description
	f.ability_id = ability_id
	return f
