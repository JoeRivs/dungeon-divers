class_name Arrow
extends Area2D

## Bow projectile. Reused via ProjectilePool - launch() activates it,
## deactivate() parks it off-screen and hands it back to the pool.

signal despawned

const SPEED: float = 460.0
const LIFETIME: float = 2.0

@onready var body: Polygon2D = $Body
@onready var shape: CollisionShape2D = $Shape

var _velocity: Vector2 = Vector2.ZERO
var _life_left: float = 0.0
var _active: bool = false
var _damage: int = 0
var _crit: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	deactivate()


func _physics_process(delta: float) -> void:
	if not _active:
		return
	global_position += _velocity * delta
	_life_left -= delta
	if _life_left <= 0.0:
		deactivate()


func launch(from: Vector2, direction: Vector2, damage: int, crit: bool) -> void:
	global_position = from
	_velocity = direction.normalized() * SPEED
	rotation = direction.angle()
	_damage = damage
	_crit = crit
	_life_left = LIFETIME
	_active = true
	visible = true
	# Deferred: launch()/deactivate() can be reached from inside a physics
	# callback (body_entered), where changing monitoring state is blocked.
	# The _active flag is the real gate; the physics state can lag a frame.
	shape.set_deferred("disabled", false)
	set_deferred("monitoring", true)


func deactivate() -> void:
	_active = false
	visible = false
	shape.set_deferred("disabled", true)
	set_deferred("monitoring", false)
	global_position = Vector2(-100000, -100000)
	despawned.emit()


func _on_body_entered(hit: Node) -> void:
	if not _active:
		return
	if hit.is_in_group("enemies") and hit.has_method("apply_damage"):
		var dealt: int = hit.apply_damage(_damage)
		if dealt > 0:
			FloatingText.spawn(hit.global_position, dealt, _crit)
		deactivate()
	elif hit.is_in_group("world"):
		deactivate()
