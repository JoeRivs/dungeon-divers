extends Area2D

## A homing dart (Magic Missile). Curves toward its assigned target and
## can't really miss; self-frees on hit or lifetime. If the target dies
## mid-flight it just flies straight.

const SPEED: float = 340.0
const TURN: float = 7.0
const LIFETIME: float = 1.6

var _velocity: Vector2 = Vector2.ZERO
var _life: float = LIFETIME
var _damage: int = 0
var _crit: bool = false
var _target: Node = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(from: Vector2, initial_dir: Vector2, damage: int, crit: bool, target: Node) -> void:
	global_position = from
	_velocity = initial_dir.normalized() * SPEED
	_damage = damage
	_crit = crit
	_target = target


func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	if is_instance_valid(_target):
		var want: Vector2 = (_target.global_position - global_position).normalized() * SPEED
		_velocity = _velocity.lerp(want, clampf(TURN * delta, 0.0, 1.0))
	global_position += _velocity * delta
	rotation = _velocity.angle()


func _on_body_entered(hit: Node) -> void:
	if hit.is_in_group("enemies") and hit.has_method("apply_damage"):
		var dealt: int = hit.apply_damage(_damage)
		if dealt > 0:
			FloatingText.spawn(hit.global_position, dealt, _crit)
		queue_free()
	elif hit.is_in_group("world"):
		queue_free()
