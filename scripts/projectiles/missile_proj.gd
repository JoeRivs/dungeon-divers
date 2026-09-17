extends Area2D

## A homing dart (Magic Missile). Curves toward its assigned target and
## can't really miss; self-frees on hit or lifetime. If the target dies
## mid-flight it just flies straight.

const SPEED: float = 340.0
const TURN: float = 7.0
const LIFETIME: float = 1.6

## Volatile Missiles forge: a small explosion on hit.
const VOLATILE_RADIUS: float = 46.0
const VOLATILE_FRACTION: float = 0.5

var _velocity: Vector2 = Vector2.ZERO
var _life: float = LIFETIME
var _damage: int = 0
var _crit: bool = false
var _target: Node = null
var _turn_mult: float = 1.0
var _pierce_left: int = 0        ## Penetrating Missiles = 1, + Ricochet etching = 2
var _volatile: bool = false
var _weaken_on_hit: bool = false ## Critical Mass etching


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(from: Vector2, initial_dir: Vector2, damage: int, crit: bool, target: Node,
		turn_mult: float = 1.0, pierce_hits: int = 0, volatile: bool = false,
		weaken_on_hit: bool = false) -> void:
	global_position = from
	_velocity = initial_dir.normalized() * SPEED
	_damage = damage
	_crit = crit
	_target = target
	_turn_mult = turn_mult
	_pierce_left = pierce_hits
	_volatile = volatile
	_weaken_on_hit = weaken_on_hit


func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	if is_instance_valid(_target):
		var want: Vector2 = (_target.global_position - global_position).normalized() * SPEED
		_velocity = _velocity.lerp(want, clampf(TURN * _turn_mult * delta, 0.0, 1.0))
	global_position += _velocity * delta
	rotation = _velocity.angle()


func _on_body_entered(hit: Node) -> void:
	if hit.is_in_group("enemies") and hit.has_method("apply_damage"):
		var amount: int = maxi(int(round(_damage * Weaken.multiplier_on(hit))), 1)
		var dealt: int = hit.apply_damage(amount)
		if dealt > 0:
			FloatingText.spawn(hit.global_position, dealt, _crit)
		if _volatile:
			_explode(hit)
		if _pierce_left > 0:
			_pierce_left -= 1
			_target = null   # stop homing, keep flying straight through
			return
		queue_free()
	elif hit.is_in_group("world"):
		queue_free()


func _explode(from_hit: Node) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == from_hit or not is_instance_valid(e) or not e.has_method("apply_damage"):
			continue
		if e.global_position.distance_to(global_position) > VOLATILE_RADIUS:
			continue
		var amount: int = maxi(int(round(_damage * VOLATILE_FRACTION * Weaken.multiplier_on(e))), 1)
		var dealt: int = e.apply_damage(amount)
		if dealt > 0:
			FloatingText.spawn(e.global_position, dealt, false)
		if _weaken_on_hit:
			Weaken.apply_to(e, 0.2)
