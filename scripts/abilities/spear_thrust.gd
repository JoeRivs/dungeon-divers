extends Ability

## The weapon a Forge can swap the Sword into. A straight thrust along the
## aim line instead of an arc swing - longer reach, narrower, hits in a
## line. Base: the nearest enemy in the line. Impale etching: pierces
## through to a second.

const REACH: float = 96.0
const THRUST_TIME: float = 0.15
const RETRACT_TIME: float = 0.11

## Cleave carries over if you had it on Sword before Spearhead swapped you
## to this - a straight thrust has no arc to widen, so it widens the thrust
## corridor instead and keeps the same damage bump. Picked up automatically
## via player.gd's _swap_ability() carrying old-weapon forges forward.
const CLEAVE_WIDTH_MULT: float = 1.6
const CLEAVE_DIE_BONUS: int = 2

@onready var hitbox: Area2D = $Hitbox
@onready var shape: CollisionShape2D = $Hitbox/Shape
@onready var blade: Polygon2D = $Blade

var _active: bool = false
var _hit: Array[Node] = []
var _dice_bonus: int = 0


func _ready() -> void:
	hitbox.monitoring = false
	shape.disabled = true
	blade.scale.x = 0.0


func _on_forge(id: StringName) -> void:
	if id == &"cleave":
		var rect := (shape.shape as RectangleShape2D)
		if rect != null:
			rect = rect.duplicate()
			rect.size = rect.size * Vector2(1.0, CLEAVE_WIDTH_MULT)
			shape.shape = rect
		_dice_bonus = CLEAVE_DIE_BONUS


func can_use() -> bool:
	return not _active and super()


func _perform(_origin: Vector2, direction: Vector2) -> void:
	_active = true
	_hit.clear()
	rotation = direction.angle()
	hitbox.monitoring = true
	shape.disabled = false

	var tween := create_tween()
	tween.tween_property(blade, "scale:x", 1.0, THRUST_TIME).set_trans(Tween.TRANS_SINE)
	tween.tween_property(blade, "scale:x", 0.0, RETRACT_TIME).set_delay(0.05)
	tween.tween_callback(_end_thrust)


func _physics_process(_delta: float) -> void:
	if not _active:
		return

	var candidates: Array[Node] = []
	for b in hitbox.get_overlapping_bodies():
		if not (b in _hit) and b.is_in_group("enemies") and b.has_method("apply_damage"):
			candidates.append(b)
	if candidates.is_empty():
		return
	candidates.sort_custom(func(a, b) -> bool:
		return global_position.distance_squared_to(a.global_position) \
			< global_position.distance_squared_to(b.global_position)
	)

	var limit: int = 2 if has_etching(&"impale") else 1
	var room: int = limit - _hit.size()
	var dice: Vector2i = Vector2i(damage_dice.x, damage_dice.y + _dice_bonus)
	for i in mini(room, candidates.size()):
		var target: Node = candidates[i]
		var dmg: Dictionary = wielder.compute_damage(dice, damage_kind)
		var dealt: int = target.apply_damage(dmg.amount)
		if dealt > 0:
			FloatingText.spawn(target.global_position, dealt, dmg.crit)
		_hit.append(target)


func _end_thrust() -> void:
	_active = false
	hitbox.monitoring = false
	shape.disabled = true
