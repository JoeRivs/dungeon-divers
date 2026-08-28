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


## 2D silhouette of the physical die with this many sides - the shape you'd
## recognise on a table, not just an N-gon. Centred on the origin, point up
## (-Y). Used by the floating roll / damage badges.
static func shape(sides: int, radius: float = 1.0) -> PackedVector2Array:
	var unit: PackedVector2Array
	match sides:
		4:   # tetrahedron -> point-up triangle
			unit = PackedVector2Array([Vector2(0, -1), Vector2(0.92, 0.62), Vector2(-0.92, 0.62)])
		6:   # cube -> square
			unit = PackedVector2Array([Vector2(-0.82, -0.82), Vector2(0.82, -0.82), Vector2(0.82, 0.82), Vector2(-0.82, 0.82)])
		8:   # octahedron -> rhombus
			unit = PackedVector2Array([Vector2(0, -1), Vector2(0.74, 0), Vector2(0, 1), Vector2(-0.74, 0)])
		10:  # pentagonal trapezohedron -> pointed kite
			unit = PackedVector2Array([Vector2(0, -1), Vector2(0.62, -0.26), Vector2(0.5, 0.45), Vector2(0, 1), Vector2(-0.5, 0.45), Vector2(-0.62, -0.26)])
		12:  # dodecahedron -> pentagon
			unit = _regular(5)
		20:  # icosahedron -> hexagon
			unit = _regular(6)
		_:
			unit = _regular(maxi(sides, 3))

	var out: PackedVector2Array = []
	for p in unit:
		out.append(p * radius)
	return out


static func _regular(n: int) -> PackedVector2Array:
	var pts: PackedVector2Array = []
	for i in n:
		var a: float = -PI / 2.0 + TAU * float(i) / float(n)
		pts.append(Vector2(cos(a), sin(a)))
	return pts
