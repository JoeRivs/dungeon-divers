class_name Ability
extends Node2D

## Base for anything in a player slot (primary / secondary / skill / dodge).
## Handles the cooldown + resource gate; subclasses override _perform().
## Mounted as a child of the player; setup() hands it the wielder.

@export var display_name: String = "Ability"
@export var base_cooldown: float = 0.0
@export var mana_cost: float = 0.0
@export var damage_kind: StringName = &"none"   ## melee / ranged / spell / none
@export var damage_dice: Vector2i = Vector2i(1, 4)
@export var ability_id: StringName = &""        ## identity for forge upgrades

var wielder: Node = null
var cooldown_left: float = 0.0                   ## read by the HUD
var forge_id: StringName = &""                   ## active forge rewire, if any


func setup(w: Node) -> void:
	wielder = w


## Apply a forge rewire. Subclasses read `forge_id` at perform time and/or
## override _on_forge() for one-time setup.
func apply_forge(id: StringName) -> void:
	forge_id = id
	_on_forge(id)


func _on_forge(_id: StringName) -> void:
	pass


func _process(delta: float) -> void:
	if cooldown_left > 0.0:
		cooldown_left = maxf(cooldown_left - delta, 0.0)


func can_use() -> bool:
	if cooldown_left > 0.0:
		return false
	if mana_cost > 0.0 and wielder.resource_value() < mana_cost:
		return false
	return true


## Returns true if it fired.
func try_use(origin: Vector2, direction: Vector2) -> bool:
	if not can_use():
		return false
	cooldown_left = wielder.scaled_cooldown(base_cooldown)
	if mana_cost > 0.0:
		wielder.spend_resource(mana_cost)
	_perform(origin, direction)
	return true


## 1.0 = ready, 0.0 = just fired.
func ready_ratio() -> float:
	if base_cooldown <= 0.0:
		return 1.0
	var full: float = maxf(wielder.scaled_cooldown(base_cooldown), 0.001)
	return 1.0 - clampf(cooldown_left / full, 0.0, 1.0)


func _perform(_origin: Vector2, _direction: Vector2) -> void:
	pass
