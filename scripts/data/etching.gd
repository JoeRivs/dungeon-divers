class_name Etching
extends Resource

## A kill-XP reward: a small MECHANIC-shaped change to one ability - never a
## flat stat number, that's what boons are for. Sits between boons (frequent,
## tiny, generic) and Forges (rare, one big rewire, whole-ability). Two ways
## an Etching can be gated to build synergy instead of just piling up:
##   - requires_forge: only offered if that Forge id is already active on
##     the same ability (e.g. Forked Bolt -> Overcharge Chain)
##   - requires_etching: only offered after an earlier Etching id on the
##     same ability is already taken (a 2-3 node combo chain per weapon)

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var ability_id: StringName = &""
@export var requires_forge: StringName = &""      ## &"" = no Forge gate
@export var requires_etching: StringName = &""    ## &"" = no prerequisite
@export var requires_archetype: StringName = &""  ## &"" = any archetype with the ability


static func make(id: StringName, display_name: String, description: String,
		ability_id: StringName, requires_forge: StringName = &"",
		requires_etching: StringName = &"") -> Etching:
	var e := Etching.new()
	e.id = id
	e.display_name = display_name
	e.description = description
	e.ability_id = ability_id
	e.requires_forge = requires_forge
	e.requires_etching = requires_etching
	return e
