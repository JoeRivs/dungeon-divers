class_name Stats
extends Node

## Modifier stack for a combatant. Base values are set per-entity in the
## inspector; classes, archetypes, upgrades and cards push StatModifiers on
## top, each tagged with a source so it can be removed as a group.
##
## final = (base + Σ add) * Π mul  , per stat.

signal changed

@export var max_health: float = 20.0
@export var move_speed: float = 220.0
@export var damage_mult: float = 1.0
@export var dice_bonus: float = 0.0
@export var cooldown_mult: float = 1.0
@export var damage_reduction: float = 0.0

var _base: Dictionary = {}
var _mods: Array[Dictionary] = []       ## { mod: StatModifier, source: StringName }
var _final: Dictionary = {}


func _ready() -> void:
	_base = {
		&"max_health": max_health,
		&"move_speed": move_speed,
		&"damage_mult": damage_mult,
		&"dice_bonus": dice_bonus,
		&"cooldown_mult": cooldown_mult,
		&"damage_reduction": damage_reduction,
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
	changed.emit()
