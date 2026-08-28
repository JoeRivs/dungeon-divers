class_name Upgrade
extends Resource

## One pickable upgrade. Mostly a bundle of StatModifiers pushed onto the
## player (source &"upgrade"), plus an optional `special` tag for the few
## that do something other than move a stat (gold, heal).

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var tier: int = 1
@export var modifiers: Array[StatModifier] = []
@export var special: StringName = &""


static func make(id: StringName, display_name: String, description: String,
		tier: int, mods: Array, special: StringName = &"") -> Upgrade:
	var u := Upgrade.new()
	u.id = id
	u.display_name = display_name
	u.description = description
	u.tier = tier
	u.modifiers.assign(mods)
	u.special = special
	return u
