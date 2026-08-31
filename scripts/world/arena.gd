extends Node2D

## Builds a play area at runtime from a size + a list of interior obstacles.
## Faked 3/4 perspective: the ground is a true square (not isometric), every
## solid piece is drawn extruded with a top face + front face, its node
## origin on its front-bottom edge (the floor-contact line) so it Y-sorts
## against the player and enemies. Long walls are chopped into segments for
## fine sort granularity. Call build() - it does not build on _ready().

@export var half_width: float = 440.0
@export var half_height: float = 290.0

const WALL: float = 22.0
const WALL_HEIGHT: float = 22.0
const SEGMENT: float = 48.0
const FLOOR_Z: int = -10

const COLOR_FLOOR := Color(0.15, 0.14, 0.19)
const COLOR_WALL_TOP := Color(0.33, 0.31, 0.40)
const COLOR_WALL_FACE := Color(0.20, 0.19, 0.26)
const COLOR_PROP_TOP := Color(0.40, 0.36, 0.30)
const COLOR_PROP_FACE := Color(0.27, 0.24, 0.20)


func build(hw: float, hh: float, obstacles: Array) -> void:
	half_width = hw
	half_height = hh
	for child in get_children():
		child.queue_free()

	_add_floor()
	var outer_w: float = half_width * 2.0 + WALL * 2.0
	_add_block(Vector2(0.0, -half_height), outer_w, WALL, COLOR_WALL_TOP, COLOR_WALL_FACE)
	_add_block(Vector2(0.0, half_height + WALL), outer_w, WALL, COLOR_WALL_TOP, COLOR_WALL_FACE)
	_add_wall_strip(-half_width - WALL * 0.5)
	_add_wall_strip(half_width + WALL * 0.5)

	for o in obstacles:
		var r: Rect2 = o
		_add_block(Vector2(r.get_center().x, r.position.y + r.size.y),
			r.size.x, r.size.y, COLOR_PROP_TOP, COLOR_PROP_FACE)


func _add_floor() -> void:
	var floor_poly := Polygon2D.new()
	floor_poly.color = COLOR_FLOOR
	floor_poly.z_index = FLOOR_Z
	floor_poly.polygon = PackedVector2Array([
		Vector2(-half_width, -half_height), Vector2(half_width, -half_height),
		Vector2(half_width, half_height), Vector2(-half_width, half_height),
	])
	add_child(floor_poly)


func _add_wall_strip(x: float) -> void:
	var top: float = -half_height - WALL
	var bottom: float = half_height + WALL
	var count: int = int(ceil((bottom - top) / SEGMENT))
	var depth: float = (bottom - top) / float(count)
	for i in count:
		var front_edge_y: float = top + depth * float(i + 1)
		_add_block(Vector2(x, front_edge_y), WALL, depth, COLOR_WALL_TOP, COLOR_WALL_FACE)


## origin_front: world position of the centre of the piece's front-bottom
## edge (its floor-contact line, and its Y-sort key).
func _add_block(origin_front: Vector2, width: float, depth: float,
		top_color: Color, face_color: Color) -> void:
	var solid := StaticBody2D.new()
	solid.position = origin_front
	solid.collision_layer = 1
	solid.collision_mask = 0
	solid.add_to_group("world")

	var col := CollisionShape2D.new()
	col.position = Vector2(0.0, -depth * 0.5)
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, depth)
	col.shape = rect
	solid.add_child(col)

	var hw: float = width * 0.5

	var top_face := Polygon2D.new()
	top_face.color = top_color
	top_face.polygon = PackedVector2Array([
		Vector2(-hw, -depth - WALL_HEIGHT), Vector2(hw, -depth - WALL_HEIGHT),
		Vector2(hw, -WALL_HEIGHT), Vector2(-hw, -WALL_HEIGHT),
	])

	var front_face := Polygon2D.new()
	front_face.color = face_color
	front_face.polygon = PackedVector2Array([
		Vector2(-hw, -WALL_HEIGHT), Vector2(hw, -WALL_HEIGHT),
		Vector2(hw, 0.0), Vector2(-hw, 0.0),
	])

	solid.add_child(front_face)
	solid.add_child(top_face)
	add_child(solid)
