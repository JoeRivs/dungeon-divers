extends Ability

## Duelist skill: the Momentum dump. Lunge forward with brief i-frames and
## sweep a wide arc; damage scales with how much Momentum you'd banked (up to
## ~2x at full), and the whole pool is spent regardless. Needs a minimum
## charge to fire.

const MIN_MOMENTUM: float = 30.0
const ARC: float = 2.6
const SWING_TIME: float = 0.16
const LUNGE_SPEED: float = 560.0
const LUNGE_TIME: float = 0.16
const IFRAMES: float = 0.22

const SWOOSH_INNER: float = 12.0
const SWOOSH_OUTER: float = 74.0
const SWOOSH_SEGMENTS: int = 18
const SWOOSH_COLOR := Color(1.0, 0.95, 0.6, 0.9)

@onready var hitbox: Area2D = $Hitbox
@onready var shape: CollisionShape2D = $Hitbox/Shape
@onready var swoosh: Polygon2D = $Swoosh

var _swinging: bool = false
var _hit: Array[Node] = []
var _swing_from: float = 0.0
var _mult: float = 1.0


func _ready() -> void:
	hitbox.monitoring = false
	shape.disabled = true
	swoosh.polygon = PackedVector2Array()


func can_use() -> bool:
	if _swinging:
		return false
	if wielder.resource_value() < MIN_MOMENTUM:
		return false
	return super()


func _perform(_origin: Vector2, direction: Vector2) -> void:
	var dir: Vector2 = direction if direction != Vector2.ZERO else wielder.facing()
	dir = dir.normalized()

	# bank -> multiplier, then dump the whole pool
	_mult = 1.0 + wielder.resource_ratio()
	wielder.spend_resource(wielder.resource_value())

	wielder.dash(dir * LUNGE_SPEED, LUNGE_TIME, IFRAMES)

	_swinging = true
	_hit.clear()
	var arc: float = TAU if forge_id == &"whirlwind" else ARC
	var base: float = dir.angle()
	_swing_from = base - arc * 0.5
	rotation = _swing_from
	hitbox.monitoring = true
	shape.disabled = false
	swoosh.modulate.a = 1.0
	_update_swoosh(0.0)

	var tween := create_tween()
	tween.tween_property(self, "rotation", base + arc * 0.5, SWING_TIME)
	tween.tween_callback(_end_swing)


func _physics_process(_delta: float) -> void:
	if not _swinging:
		return
	_update_swoosh(absf(rotation - _swing_from))
	for target in hitbox.get_overlapping_bodies():
		if target in _hit:
			continue
		if target.is_in_group("enemies") and target.has_method("apply_damage"):
			var dmg: Dictionary = wielder.compute_damage(damage_dice, damage_kind)
			var amount: int = maxi(int(round(dmg.amount * _mult)), 1)
			var dealt: int = target.apply_damage(amount)
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
	for i in SWOOSH_SEGMENTS + 1:
		var t: float = float(i) / float(SWOOSH_SEGMENTS)
		var d: Vector2 = Vector2.from_angle(-swept * t)
		outer.append(d * SWOOSH_OUTER)
		inner.append(d * lerpf(SWOOSH_INNER, SWOOSH_OUTER - 4.0, t))
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
	tween.tween_property(swoosh, "modulate:a", 0.0, 0.1)
	tween.tween_callback(func() -> void: swoosh.polygon = PackedVector2Array())
