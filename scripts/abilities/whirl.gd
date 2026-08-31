extends Ability

## Windblade primary: a full 360 spin that bites every enemy in reach once.
## Weak per hit, but wading into a knot of enemies and spinning pays a lot of
## Momentum at once - then dash out.

const RADIUS: float = 52.0
const ACTIVE_TIME: float = 0.14
const MOMENTUM_PER_HIT: float = 5.0
const RING_COL := Color(0.75, 1.0, 0.9, 0.9)

## Cyclone forge: wider, ~2.6x longer, and everything gets hit a second time.
const CYCLONE_RADIUS_MULT: float = 1.4
const CYCLONE_TIME_MULT: float = 2.6

@onready var hitbox: Area2D = $Hitbox
@onready var shape: CollisionShape2D = $Hitbox/Shape

var _active: float = 0.0
var _dur: float = ACTIVE_TIME
var _hit: Array[Node] = []
var _spin: float = 0.0
var _ring_radius: float = RADIUS
var _rehit_done: bool = false


func _ready() -> void:
	hitbox.monitoring = false
	shape.disabled = true


func _on_forge(id: StringName) -> void:
	if id == &"cyclone":
		var circ := (shape.shape as CircleShape2D)
		if circ != null:
			circ = circ.duplicate()
			circ.radius *= CYCLONE_RADIUS_MULT
			shape.shape = circ
		_ring_radius = RADIUS * CYCLONE_RADIUS_MULT


func can_use() -> bool:
	return _active <= 0.0 and super()


func _perform(_origin: Vector2, _direction: Vector2) -> void:
	_dur = ACTIVE_TIME * CYCLONE_TIME_MULT if forge_id == &"cyclone" else ACTIVE_TIME
	_active = _dur
	_spin = 0.0
	_hit.clear()
	_rehit_done = false
	hitbox.monitoring = true
	shape.disabled = false
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _active <= 0.0:
		return
	_active -= delta
	_spin += delta / _dur * TAU
	queue_redraw()

	if forge_id == &"cyclone" and not _rehit_done and _active <= _dur * 0.5:
		_rehit_done = true
		_hit.clear()          # let the spin catch everything a second time

	for target in hitbox.get_overlapping_bodies():
		if target in _hit:
			continue
		if target.is_in_group("enemies") and target.has_method("apply_damage"):
			var dmg: Dictionary = wielder.compute_damage(damage_dice, damage_kind)
			var dealt: int = target.apply_damage(dmg.amount)
			if dealt > 0:
				FloatingText.spawn(target.global_position, dealt, dmg.crit)
			_hit.append(target)
			wielder.gain_resource(MOMENTUM_PER_HIT)

	if _active <= 0.0:
		hitbox.monitoring = false
		shape.disabled = true
		queue_redraw()


func _draw() -> void:
	if _active <= 0.0:
		return
	var a: float = clampf(_active / _dur, 0.0, 1.0)
	var pts: PackedVector2Array = []
	for i in 33:
		pts.append(Vector2.RIGHT.rotated(_spin + TAU * float(i) / 32.0) * _ring_radius)
	draw_polyline(pts, Color(RING_COL.r, RING_COL.g, RING_COL.b, RING_COL.a * a), 3.0, true)
	var tip: Vector2 = Vector2.RIGHT.rotated(_spin) * _ring_radius
	draw_line(Vector2.ZERO, tip, Color(RING_COL.r, RING_COL.g, RING_COL.b, 0.5 * a), 2.0)
