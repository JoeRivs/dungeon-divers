extends Ability

## Melee: sweeps a short arc in front of the wielder, damaging each enemy in
## it once per swing, with a trailing crescent "swoosh".

# damage_dice (Vector2i(1, 4)) is exported on Ability
const ARC: float = 1.4
const SWING_TIME: float = 0.18

const SWOOSH_INNER: float = 14.0
const SWOOSH_OUTER: float = 50.0
const SWOOSH_SEGMENTS: int = 14
const SWOOSH_COLOR := Color(0.85, 0.95, 1.0, 0.85)

## Cleave forge: a much wider, slightly slower swing that hits for more.
const CLEAVE_ARC_MULT: float = 1.7
const CLEAVE_TIME_MULT: float = 1.3
const CLEAVE_DIE_BONUS: int = 2

@onready var hitbox: Area2D = $Hitbox
@onready var shape: CollisionShape2D = $Hitbox/Shape
@onready var swoosh: Polygon2D = $Swoosh

var _swinging: bool = false
var _hit: Array[Node] = []
var _swing_from: float = 0.0
var _reach_mult: float = 1.0


func _ready() -> void:
	hitbox.monitoring = false
	shape.disabled = true
	swoosh.polygon = PackedVector2Array()


func _on_forge(id: StringName) -> void:
	if id == &"cleave":
		# widen the hit shape once, up front (own the resource so we don't
		# mutate a shared RectangleShape2D)
		var rect := (shape.shape as RectangleShape2D)
		if rect != null:
			rect = rect.duplicate()
			rect.size = rect.size * Vector2(1.0, CLEAVE_ARC_MULT)
			shape.shape = rect
		_reach_mult = 1.18


func _arc() -> float:
	return ARC * CLEAVE_ARC_MULT if forge_id == &"cleave" else ARC


func _swing_time() -> float:
	return SWING_TIME * CLEAVE_TIME_MULT if forge_id == &"cleave" else SWING_TIME


func _dice() -> Vector2i:
	if forge_id == &"cleave":
		return Vector2i(damage_dice.x, damage_dice.y + CLEAVE_DIE_BONUS)
	return damage_dice


func can_use() -> bool:
	return not _swinging and super()


func _perform(_origin: Vector2, direction: Vector2) -> void:
	_swinging = true
	_hit.clear()

	var base: float = direction.angle()
	_swing_from = base - _arc() * 0.5
	rotation = _swing_from
	hitbox.monitoring = true
	shape.disabled = false
	swoosh.modulate.a = 1.0
	_update_swoosh(0.0)

	var tween := create_tween()
	tween.tween_property(self, "rotation", base + _arc() * 0.5, _swing_time())
	tween.tween_callback(_end_swing)


func _physics_process(_delta: float) -> void:
	if not _swinging:
		return
	_update_swoosh(absf(rotation - _swing_from))
	for target in hitbox.get_overlapping_bodies():
		if target in _hit:
			continue
		if target.is_in_group("enemies") and target.has_method("apply_damage"):
			var dmg: Dictionary = wielder.compute_damage(_dice(), damage_kind)
			var dealt: int = target.apply_damage(dmg.amount)
			if dealt > 0:
				FloatingText.spawn(target.global_position, dealt, dmg.crit)
			_hit.append(target)


func _update_swoosh(swept: float) -> void:
	if swept <= 0.02:
		swoosh.polygon = PackedVector2Array()
		return
	var outer: PackedVector2Array = []
	var inner: PackedVector2Array = []
	var colors: PackedColorArray = []
	var reach: float = SWOOSH_OUTER * _reach_mult
	for i in SWOOSH_SEGMENTS + 1:
		var t: float = float(i) / float(SWOOSH_SEGMENTS)
		var dir: Vector2 = Vector2.from_angle(-swept * t)
		outer.append(dir * reach)
		inner.append(dir * lerpf(SWOOSH_INNER, reach - 4.0, t))
		colors.append(Color(SWOOSH_COLOR.r, SWOOSH_COLOR.g, SWOOSH_COLOR.b, SWOOSH_COLOR.a * (1.0 - t)))
	var poly: PackedVector2Array = []
	var vcols: PackedColorArray = []
	poly.append_array(outer)
	vcols.append_array(colors)
	for i in range(inner.size() - 1, -1, -1):
		poly.append(inner[i])
		vcols.append(colors[i])
	swoosh.polygon = poly
	swoosh.vertex_colors = vcols


func _end_swing() -> void:
	_swinging = false
	hitbox.monitoring = false
	shape.disabled = true
	var tween := create_tween()
	tween.tween_property(swoosh, "modulate:a", 0.0, 0.09)
	tween.tween_callback(func() -> void: swoosh.polygon = PackedVector2Array())
