class_name RoomOption
extends RefCounted

## One door. You pick the die (d4 = brutal + best loot ... d20 = easy + basic
## loot). The reward is fixed by the die. The difficulty number is NOT known
## until you commit - roll() is called as you walk through.

const DICE: Array[int] = [4, 8, 12, 20]

var die_sides: int = 20
var is_boss: bool = false
var is_forge: bool = false


static func from_die(sides: int) -> RoomOption:
	var o := RoomOption.new()
	o.die_sides = sides
	return o


static func boss() -> RoomOption:
	var o := RoomOption.new()
	o.die_sides = 20
	o.is_boss = true
	return o


## A Forge room: no fight, one rare ability rewire, then on to the next room.
static func forge() -> RoomOption:
	var o := RoomOption.new()
	o.die_sides = 20
	o.is_forge = true
	return o


## The actual roll - call only when the player commits to the door.
## Low number = dangerous room. Boss doors are always a 1.
func roll() -> int:
	return 1 if is_boss else Dice.roll(1, die_sides)


## Upgrade tier for the room, set by the die picked (not the roll).
## Lower die = harder = better options.
func tier() -> int:
	if is_boss:
		return 4
	match die_sides:
		4: return 4
		8: return 3
		12: return 2
		_: return 1
