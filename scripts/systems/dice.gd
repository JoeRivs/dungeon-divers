class_name Dice
extends RefCounted

## D&D-style dice rolls. Static - call Dice.roll(1, 4) for 1d4.

static func roll(count: int, sides: int) -> int:
	var total: int = 0
	for _i in count:
		total += randi_range(1, sides)
	return total


## True when every die came up its maximum face (a "crit").
static func is_max(value: int, count: int, sides: int) -> bool:
	return value == count * sides
