class_name Sword
extends Area2D

## Melee weapon. use() sweeps a short arc in front of the wielder and damages
## every enemy caught in the arc once per swing. The visual is a crescent
## "swoosh" that trails the blade through the sweep and fades from the tail.

const KIND := &"melee"
const DAMAGE_DICE := Vector2i(1, 4)   ## 1d4
const ARC: float = 1.4          ## total sweep, radians
const SWING_TIME: float = 0.18
const BASE_COOLDOWN: float = 0.35

const SWOOSH_INNER: float = 14.0
const SWOOSH_OUTER: float = 50.0
const SWOOSH_SEGMENTS: int = 14
const SWOOSH_COLOR := Color(0.85, 0.95, 1.0, 0.85)

@onready var swoosh: Polygon2D = $Swoosh
@onready var shape: CollisionShape2D = $Shape
@onready var _wielder: Node = get_parent()

var _swinging: bool = false
var _cooldown_left: float = 0.0
var _hit: Array[Node] = []
var _swing_from: float = 0.0


func _ready() -> void:
	monitoring = false
	shape.disabled = true
	swoosh.polygon = PackedVector2Array()


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if not _swinging:
		return

	_update_swoosh(absf(rotation - _swing_from))

	for target in get_overlapping_bodies():
		if target in _hit:
			continue
		if target.is_in_group("enemies") and target.has_method("apply_damage"):
			var dmg: Dictionary = _wielder.compute_damage(DAMAGE_DICE, KIND)
			var dealt: int = target.apply_damage(dmg.amount)
			if dealt > 0:
				FloatingText.spawn(target.global_position, dealt, dmg.crit)
			_hit.append(target)


func use(_origin: Vector2, direction: Vector2) -> void:
	swing(direction)


func swing(direction: Vector2) -> void:
	if _swinging or _cooldown_left > 0.0:
		return
	_swinging = true
	_cooldown_left = _wielder.scaled_cooldown(BASE_COOLDOWN)
	_hit.clear()

	var base: float = direction.angle()
	_swing_from = base - ARC * 0.5
	rotation = _swing_from
	monitoring = true
	shape.disabled = false
	swoosh.modulate.a = 1.0
	_update_swoosh(0.0)

	var tween := create_tween()
	tween.tween_property(self, "rotation", base + ARC * 0.5, SWING_TIME)
	tween.tween_callback(_end_swing)


## Builds a crescent spanning local angle 0 (the blade now) back to -swept
## (where the swing began): fat and bright at the blade, thin and transparent
## at the tail.
func _update_swoosh(swept: float) -> void:
	if swept <= 0.02:
		swoosh.polygon = PackedVector2Array()
		return

	var outer: PackedVector2Array = []
	var inner: PackedVector2Array = []
	var colors: PackedColorArray = []
	for i in SWOOSH_SEGMENTS + 1:
		var t: float = float(i) / float(SWOOSH_SEGMENTS)   # 0 = blade, 1 = tail
		var dir: Vector2 = Vector2.from_angle(-swept * t)
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
	monitoring = false
	shape.disabled = true

	var tween := create_tween()
	tween.tween_property(swoosh, "modulate:a", 0.0, 0.09)
	tween.tween_callback(func() -> void: swoosh.polygon = PackedVector2Array())
