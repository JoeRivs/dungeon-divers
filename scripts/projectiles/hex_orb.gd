extends Area2D

## Hex: a slow dark orb that bursts on contact (or after a short flight) for
## spell damage in a radius.

const SPEED: float = 250.0
const FLIGHT: float = 0.55

var _velocity: Vector2 = Vector2.ZERO
var _flight: float = FLIGHT
var _damage: int = 0
var _crit: bool = false
var _radius: float = 90.0
var _burst_done: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(from: Vector2, direction: Vector2, damage: int, crit: bool, radius: float) -> void:
	global_position = from
	_velocity = direction.normalized() * SPEED
	_damage = damage
	_crit = crit
	_radius = radius


func _physics_process(delta: float) -> void:
	if _burst_done:
		return
	global_position += _velocity * delta
	_flight -= delta
	if _flight <= 0.0:
		_burst()


func _on_body_entered(hit: Node) -> void:
	if _burst_done:
		return
	if hit.is_in_group("enemies") or hit.is_in_group("world"):
		_burst()


func _burst() -> void:
	_burst_done = true
	set_deferred("monitoring", false)

	var ring := Polygon2D.new()
	ring.color = Color(0.6, 0.25, 0.85, 0.4)
	var pts: PackedVector2Array = []
	for i in 22:
		pts.append(Vector2.RIGHT.rotated(TAU * float(i) / 22.0) * _radius)
	ring.polygon = pts
	ring.scale = Vector2.ZERO
	add_child(ring)
	var tween := create_tween()
	tween.tween_property(ring, "scale", Vector2.ONE, 0.18)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.has_method("apply_damage") \
				and e.global_position.distance_to(global_position) <= _radius:
			var dealt: int = e.apply_damage(_damage)
			if dealt > 0:
				FloatingText.spawn(e.global_position, dealt, _crit)
