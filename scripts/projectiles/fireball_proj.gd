extends Area2D

## Fireball: a slow lobbed orb that bursts on contact (or after a short
## flight) for spell AoE and leaves a burn on everything caught.

const SPEED: float = 365.0
const FLIGHT: float = 0.9
const RADIUS: float = 84.0
const BURN := preload("res://scenes/status/burn.tscn")

## Cluster Bombs forge: on burst, spawn this many lesser bomblets.
const CLUSTER_COUNT: int = 3
const CLUSTER_DAMAGE_FRACTION: float = 0.4
const CLUSTER_RADIUS_FRACTION: float = 0.6
const CLUSTER_HOP: float = 0.13

var _velocity: Vector2 = Vector2.ZERO
var _flight: float = FLIGHT
var _damage: int = 0
var _crit: bool = false
var _burn_ticks: int = 0
var _burn_dmg: int = 0
var _burst_done: bool = false
var _cluster: bool = false
var _radius: float = RADIUS


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(from: Vector2, direction: Vector2, damage: int, crit: bool,
		burn_ticks: int, burn_dmg: int, cluster: bool = false) -> void:
	global_position = from
	_velocity = direction.normalized() * SPEED
	_damage = damage
	_crit = crit
	_burn_ticks = burn_ticks
	_burn_dmg = burn_dmg
	_cluster = cluster


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
	ring.color = Color(1.0, 0.5, 0.15, 0.45)
	var pts: PackedVector2Array = []
	for i in 20:
		pts.append(Vector2.RIGHT.rotated(TAU * float(i) / 20.0) * _radius)
	ring.polygon = pts
	ring.scale = Vector2.ZERO
	add_child(ring)
	var tween := create_tween()
	tween.tween_property(ring, "scale", Vector2.ONE, 0.16)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or not e.has_method("apply_damage"):
			continue
		if e.global_position.distance_to(global_position) > _radius:
			continue
		var dealt: int = e.apply_damage(_damage)
		if dealt > 0:
			FloatingText.spawn(e.global_position, dealt, _crit)
		_ignite(e)

	if _cluster:
		_scatter_bomblets()


func _scatter_bomblets() -> void:
	var scene: PackedScene = load("res://scenes/projectiles/fireball_proj.tscn")
	var start: float = randf() * TAU
	for k in CLUSTER_COUNT:
		var ang: float = start + TAU * float(k) / float(CLUSTER_COUNT)
		var b = scene.instantiate()
		get_parent().add_child(b)
		b.global_position = global_position
		b.setup(global_position, Vector2.from_angle(ang),
			maxi(int(round(_damage * CLUSTER_DAMAGE_FRACTION)), 1), _crit,
			_burn_ticks, _burn_dmg, false)
		b._flight = CLUSTER_HOP
		b._radius = RADIUS * CLUSTER_RADIUS_FRACTION


func _ignite(enemy: Node) -> void:
	var burn := enemy.get_node_or_null("Burn")
	if burn == null:
		burn = BURN.instantiate()
		burn.name = "Burn"
		enemy.add_child.call_deferred(burn)
	burn.apply(enemy, _burn_ticks, _burn_dmg)
