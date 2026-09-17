extends Ability

## Duelist primary: a fast, short-reach twin slash. Low damage per hit but a
## tiny cooldown, and every enemy it bites builds Momentum - the resource the
## Duelist dumps into a finisher.

const ARC: float = 1.05
const SWING_TIME: float = 0.12
const MOMENTUM_PER_HIT: float = 6.0
const THIRD_STRIKE_EVERY: int = 3     ## Third Strike forge: this hit crits + 2x Momentum

## Bloodrush etching: 3 connecting swings in a row (no whiffs) refunds the
## cooldown and pays a Momentum burst - a free extra swing for staying sharp.
const BLOODRUSH_STREAK: int = 3
const BLOODRUSH_MOMENTUM: float = 20.0

const SWOOSH_INNER: float = 10.0
const SWOOSH_OUTER: float = 40.0
const SWOOSH_SEGMENTS: int = 12
const SWOOSH_COLOR := Color(0.8, 1.0, 0.85, 0.8)

@onready var hitbox: Area2D = $Hitbox
@onready var shape: CollisionShape2D = $Hitbox/Shape
@onready var swoosh: Polygon2D = $Swoosh

var _swinging: bool = false
var _hit: Array[Node] = []
var _swing_from: float = 0.0
var _flip: float = 1.0                 ## alternate the swing side each use
var _streak: int = 0                   ## running hit count, for Third Strike
var _connect_streak: int = 0           ## consecutive connecting SWINGS, for Bloodrush


func _ready() -> void:
	hitbox.monitoring = false
	shape.disabled = true
	swoosh.polygon = PackedVector2Array()


func can_use() -> bool:
	return not _swinging and super()


func _perform(_origin: Vector2, direction: Vector2) -> void:
	_swinging = true
	_hit.clear()
	_flip = -_flip

	var base: float = direction.angle()
	_swing_from = base + ARC * 0.5 * _flip
	rotation = _swing_from
	hitbox.monitoring = true
	shape.disabled = false
	swoosh.modulate.a = 1.0
	_update_swoosh(0.0)

	var tween := create_tween()
	tween.tween_property(self, "rotation", base - ARC * 0.5 * _flip, SWING_TIME)
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
			var amount: int = dmg.amount
			var crit: bool = dmg.crit
			var momentum: float = MOMENTUM_PER_HIT
			_streak += 1
			if forge_id == &"third_strike" and _streak % THIRD_STRIKE_EVERY == 0:
				amount = maxi(amount * 2, 1)
				crit = true
				momentum *= 2.0
			var dealt: int = target.apply_damage(amount)
			if dealt > 0:
				FloatingText.spawn(target.global_position, dealt, crit)
			_hit.append(target)
			wielder.gain_resource(momentum)


func _update_swoosh(swept: float) -> void:
	if swept <= 0.02:
		swoosh.polygon = PackedVector2Array()
		return
	var sign_swept: float = swept * signf(-_flip)
	var outer: PackedVector2Array = []
	var inner: PackedVector2Array = []
	var colors: PackedColorArray = []
	for i in SWOOSH_SEGMENTS + 1:
		var t: float = float(i) / float(SWOOSH_SEGMENTS)
		var dir: Vector2 = Vector2.from_angle(sign_swept * t)
		outer.append(dir * SWOOSH_OUTER)
		inner.append(dir * lerpf(SWOOSH_INNER, SWOOSH_OUTER - 4.0, t))
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
	if has_etching(&"bloodrush"):
		if _hit.is_empty():
			_connect_streak = 0
		else:
			_connect_streak += 1
			if _connect_streak >= BLOODRUSH_STREAK:
				_connect_streak = 0
				wielder.gain_resource(BLOODRUSH_MOMENTUM)
				cooldown_left = 0.0
	var tween := create_tween()
	tween.tween_property(swoosh, "modulate:a", 0.0, 0.07)
	tween.tween_callback(func() -> void: swoosh.polygon = PackedVector2Array())
