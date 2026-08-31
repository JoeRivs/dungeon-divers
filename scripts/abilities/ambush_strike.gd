extends Ability

## Assassin primary: the Flurry, but the FIRST hit on any given enemy lands
## for double and pays extra Momentum - reward for opening on a fresh target
## before it's aware of you. Follow-up hits are normal.

const ARC: float = 1.05
const SWING_TIME: float = 0.12
const MOMENTUM_PER_HIT: float = 6.0
const AMBUSH_MULT: float = 2.0
const AMBUSH_BONUS_MOMENTUM: float = 6.0

const SWOOSH_INNER: float = 10.0
const SWOOSH_OUTER: float = 40.0
const SWOOSH_SEGMENTS: int = 12
const SWOOSH_COLOR := Color(0.85, 0.7, 1.0, 0.85)

@onready var hitbox: Area2D = $Hitbox
@onready var shape: CollisionShape2D = $Hitbox/Shape
@onready var swoosh: Polygon2D = $Swoosh

var _swinging: bool = false
var _hit: Array[Node] = []
var _seen: Array[Node] = []             ## enemies already ambushed this run
var _swing_from: float = 0.0
var _flip: float = 1.0


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
	for i in range(_seen.size() - 1, -1, -1):
		if not is_instance_valid(_seen[i]):
			_seen.remove_at(i)
	for target in hitbox.get_overlapping_bodies():
		if target in _hit:
			continue
		if target.is_in_group("enemies") and target.has_method("apply_damage"):
			var dmg: Dictionary = wielder.compute_damage(damage_dice, damage_kind)
			# Killer Instinct: the opener bonus fires on the first hit of
			# every swing, not just the first time you ever hit this enemy.
			var ambush: bool = forge_id == &"killer_instinct" or not (target in _seen)
			var amount: int = dmg.amount
			if ambush:
				amount = maxi(int(round(amount * AMBUSH_MULT)), 1)
				if not (target in _seen):
					_seen.append(target)
			var dealt: int = target.apply_damage(amount)
			if dealt > 0:
				FloatingText.spawn(target.global_position, dealt, dmg.crit or ambush)
			_hit.append(target)
			wielder.gain_resource(MOMENTUM_PER_HIT + (AMBUSH_BONUS_MOMENTUM if ambush else 0.0))


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
		var d: Vector2 = Vector2.from_angle(sign_swept * t)
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
	tween.tween_property(swoosh, "modulate:a", 0.0, 0.07)
	tween.tween_callback(func() -> void: swoosh.polygon = PackedVector2Array())
