class_name StatModifier
extends Resource

## One tweak to one stat. Final stat = (base + sum of adds) * product of muls.
## Authorable as a sub-resource in the inspector, or built in code via make().

@export var stat: StringName = &""
@export var add: float = 0.0
@export var mul: float = 1.0


static func make(stat: StringName, add: float = 0.0, mul: float = 1.0) -> StatModifier:
	var m := StatModifier.new()
	m.stat = stat
	m.add = add
	m.mul = mul
	return m
