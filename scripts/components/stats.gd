class_name Stats
extends Node

## Modifier stack for a combatant. Base values are set per-entity in the
## inspector; classes, archetypes, upgrades and cards push StatModifiers on
## top, each tagged with a source so it can be removed as a group.
##
## Two layers:
##   1. per-stat     final = (base + Σ add) * Π mul
##   2. derivation   the 4 primary attributes then feed the combat stats
##                   (Might -> damage, Finesse -> speed/cooldown, etc.)
## Upgrades can target either layer - bump an attribute, or a stat directly.

signal changed

const ATTR_BASELINE: float = 10.0

## which attribute powers each weapon kind's damage
const ATTACK_ATTR := {
	&"melee": &"might",
	&"ranged": &"finesse",
}

## primary attributes
@export var might: float = 10.0
@export var finesse: float = 10.0
@export var vitality: float = 10.0
@export var focus: float = 10.0

## combat stats (also nudged by the attributes above)
@export var max_health: float = 20.0
@export var move_speed: float = 220.0
@export var damage_mult: float = 1.0
@export var dice_bonus: float = 0.0
@export var cooldown_mult: float = 1.0
@export var damage_reduction: float = 0.0
@export var spell_power: float = 1.0

var _base: Dictionary = {}
var _mods: Array[Dictionary] = []       ## { mod: StatModifier, source: StringName }
var _final: Dictionary = {}


func _ready() -> void:
	_base = {
		&"might": might,
		&"finesse": finesse,
		&"vitality": vitality,
		&"focus": focus,
		&"max_health": max_health,
		&"move_speed": move_speed,
		&"damage_mult": damage_mult,
		&"dice_bonus": dice_bonus,
		&"cooldown_mult": cooldown_mult,
		&"damage_reduction": damage_reduction,
		&"spell_power": spell_power,
	}
	_recompute()


func add_modifier(mod: StatModifier, source: StringName) -> void:
	_mods.append({"mod": mod, "source": source})
	_recompute()


func add_modifiers(mods: Array, source: StringName) -> void:
	for m in mods:
		_mods.append({"mod": m, "source": source})
	_recompute()


func clear_source(source: StringName) -> void:
	var kept: Array[Dictionary] = []
	for e in _mods:
		if e["source"] != source:
			kept.append(e)
	_mods = kept
	_recompute()


func get_stat(key: StringName) -> float:
	return _final.get(key, 0.0)


## Flat damage bonus for a weapon kind: the generic bucket (from upgrades)
## plus a D&D-style modifier from the kind's attribute (Might for melee,
## Finesse for ranged).
func attack_flat(kind: StringName) -> float:
	var bonus: float = get_stat(&"dice_bonus")
	var attr: StringName = ATTACK_ATTR.get(kind, &"")
	if attr != &"":
		bonus += floorf((get_stat(attr) - ATTR_BASELINE) / 2.0)
	return bonus


## Damage multiplier for a weapon kind: the generic +% bucket plus the
## kind's attribute percent. Both are additive into one multiplier.
func attack_mult(kind: StringName) -> float:
	var mult: float = get_stat(&"damage_mult")
	var attr: StringName = ATTACK_ATTR.get(kind, &"")
	if attr != &"":
		mult += (get_stat(attr) - ATTR_BASELINE) * 0.03
	return mult


func _recompute() -> void:
	_final.clear()
	for key in _base:
		var add_sum: float = 0.0
		var mul_prod: float = 1.0
		for e in _mods:
			var m: StatModifier = e["mod"]
			if m.stat == key:
				add_sum += m.add
				mul_prod *= m.mul
		_final[key] = (float(_base[key]) + add_sum) * mul_prod
	_derive()
	changed.emit()


## Attributes -> combat stats. Baseline 10 contributes nothing.
##
## Damage is NOT derived here - it's per weapon kind, via attack_flat() /
## attack_mult(), so Might drives melee and Finesse drives ranged. damage_mult
## and dice_bonus stay generic buckets that upgrades push to (base 1.0 + Σ +%).
func _derive() -> void:
	var d_fin: float = _final[&"finesse"] - ATTR_BASELINE
	var d_vit: float = _final[&"vitality"] - ATTR_BASELINE
	var d_focus: float = _final[&"focus"] - ATTR_BASELINE

	_final[&"move_speed"] += d_fin * 6.0
	_final[&"cooldown_mult"] *= clampf(1.0 - d_fin * 0.02, 0.5, 1.5)
	_final[&"max_health"] += d_vit * 3.0
	_final[&"damage_reduction"] += d_vit * 0.01
	_final[&"spell_power"] += d_focus * 0.08

	_final[&"damage_mult"] = maxf(_final[&"damage_mult"], 0.1)
	_final[&"move_speed"] = maxf(_final[&"move_speed"], 20.0)
	_final[&"cooldown_mult"] = clampf(_final[&"cooldown_mult"], 0.3, 2.0)
	_final[&"max_health"] = maxf(_final[&"max_health"], 1.0)
	_final[&"damage_reduction"] = clampf(_final[&"damage_reduction"], 0.0, 0.9)
