extends Node2D

## Builds the boxed play area at runtime. Faked 3/4 perspective: the ground
## is a true square (not isometric), walls are drawn extruded with a top
## face + front face. Collision is a flat footprint; the drawn height is
## purely visual.
##
## Each wall piece's node origin sits on its front-bottom edge (the line
## where it meets the floor). That Y is its Y-sort key, so the player
## occludes / is occluded by wall pieces correctly as he moves past them.
## Long side walls are chopped into segments so the sort has fine grain.

const HALF_WIDTH: float = 440.0
const HALF_HEIGHT: float = 290.0
const WALL: float = 22.0            ## footprint thickness
const WALL_HEIGHT: float = 22.0     ## apparent height on screen
const SEGMENT: float = 48.0         ## Y-sort granularity for long walls

const FLOOR_Z: int = -10

const COLOR_FLOOR := Color(0.15, 0.14, 0.19)
const COLOR_WALL_TOP := Color(0.33, 0.31, 0.40)
const COLOR_WALL_FACE := Color(0.20, 0.19, 0.26)


func _ready() -> void:
	_add_floor()
	var outer_w: float = HALF_WIDTH * 2.0 + WALL * 2.0
	_add_wall_block(Vector2(0.0, -HALF_HEIGHT), outer_w, WALL)
	_add_wall_block(Vector2(0.0, HALF_HEIGHT + WALL), outer_w, WALL)
	_add_wall_strip(-HALF_WIDTH - WALL * 0.5)
	_add_wall_strip(HALF_WIDTH + WALL * 0.5)


func _add_floor() -> void:
	var floor_poly := Polygon2D.new()
	floor_poly.color = COLOR_FLOOR
	floor_poly.z_index = FLOOR_Z
	floor_poly.polygon = PackedVector2Array([
		Vector2(-HALF_WIDTH, -HALF_HEIGHT), Vector2(HALF_WIDTH, -HALF_HEIGHT),
		Vector2(HALF_WIDTH, HALF_HEIGHT), Vector2(-HALF_WIDTH, HALF_HEIGHT),
	])
	add_child(floor_poly)


func _add_wall_strip(x: float) -> void:
	var top: float = -HALF_HEIGHT - WALL
	var bottom: float = HALF_HEIGHT + WALL
	var count: int = int(ceil((bottom - top) / SEGMENT))
	var depth: float = (bottom - top) / float(count)
	for i in count:
		var front_edge_y: float = top + depth * float(i + 1)
		_add_wall_block(Vector2(x, front_edge_y), WALL, depth)


## origin_front: world position of the centre of the piece's front-bottom
## edge (its floor-contact line, and its Y-sort key).
func _add_wall_block(origin_front: Vector2, width: float, depth: float) -> void:
	var wall := StaticBody2D.new()
	wall.position = origin_front
	wall.collision_layer = 1
	wall.collision_mask = 0
	wall.add_to_group("world")

	var col := CollisionShape2D.new()
	col.position = Vector2(0.0, -depth * 0.5)
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, depth)
	col.shape = rect
	wall.add_child(col)

	var hw: float = width * 0.5

	var top_face := Polygon2D.new()
	top_face.color = COLOR_WALL_TOP
	top_face.polygon = PackedVector2Array([
		Vector2(-hw, -depth - WALL_HEIGHT), Vector2(hw, -depth - WALL_HEIGHT),
		Vector2(hw, -WALL_HEIGHT), Vector2(-hw, -WALL_HEIGHT),
	])

	var front_face := Polygon2D.new()
	front_face.color = COLOR_WALL_FACE
	front_face.polygon = PackedVector2Array([
		Vector2(-hw, -WALL_HEIGHT), Vector2(hw, -WALL_HEIGHT),
		Vector2(hw, 0.0), Vector2(-hw, 0.0),
	])

	wall.add_child(front_face)
	wall.add_child(top_face)
	add_child(wall)
