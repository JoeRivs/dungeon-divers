class_name PlayerClass
extends Resource

## A starting class: a stat spread, a default ability loadout for the four
## slots, an optional resource pool, and its archetypes (build paths).

@export var id: StringName = &""
@export var display_name: String = ""
@export var base_modifiers: Array[StatModifier] = []
@export var archetypes: Array[Archetype] = []
@export var default_archetype: StringName = &""

## slot loadout - an Ability scene per slot
@export var primary_ability: PackedScene
@export var secondary_ability: PackedScene
@export var skill_ability: PackedScene
@export var dodge_ability: PackedScene

## class resource label (empty = no resource; pool/regen come from stats)
@export var pool_name: String = ""

## does the pool spawn full (mana model) or empty (build-it-up model)?
@export var resource_starts_full: bool = true

## sprite for the body; null = use a placeholder figure picked by body_style
@export var body_texture: Texture2D = null

## which placeholder figure when body_texture is null: &"robe" or &"rogue"
@export var body_style: StringName = &"robe"


func get_archetype(aid: StringName) -> Archetype:
	for a in archetypes:
		if a.id == aid:
			return a
	return archetypes[0] if not archetypes.is_empty() else null


func ability_for(slot: StringName) -> PackedScene:
	match slot:
		&"primary": return primary_ability
		&"secondary": return secondary_ability
		&"skill": return skill_ability
		&"dodge": return dodge_ability
	return null
