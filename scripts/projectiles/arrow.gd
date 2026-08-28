class_name Arrow
extends Area2D

## Arrow projectile, friendly or hostile. Reused via ProjectilePool -
## launch() activates it, deactivate() parks it off-screen and returns it.

signal despawned

const SPEED: float = 460.0
const LIFETIME: float = 2.0

## collision masks: world = bit 1 (1), player = bit 2 (2), enemy = bit 3 (4)
const MASK_FRIENDLY: int = 1 | 4       ## hits world + enemies
const MASK_HOSTILE: int = 1 | 2        ## hits world + player

const TINT_FRIENDLY := Color(1.0, 0.96, 0.6)
const TINT_HOSTILE := Color(1.0, 0.5, 0.4)

@onready var body: Polygon2D = $Body
@onready var shape: CollisionShape2D = $Shape

var _velocity: Vector2 = Vector2.ZERO
var _life_left: float = 0.0
var _active: bool = false
var _damage: int = 0
var _crit: bool = false
var _hostile: bool = false


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


func launch(from: Vector2, direction: Vector2, damage: int, crit: bool, hostile: bool = false) -> void:
	global_position = from
	_velocity = direction.normalized() * SPEED
	rotation = direction.angle()
	_damage = damage
	_crit = crit
	_hostile = hostile
	_life_left = LIFETIME
	_active = true
	visible = true
	body.color = TINT_HOSTILE if hostile else TINT_FRIENDLY
	# Deferred: launch()/deactivate() can be reached from inside a physics
	# callback (body_entered), where changing these is blocked. The _active
	# flag is the real gate; the physics state can lag a frame.
	shape.set_deferred("disabled", false)
	set_deferred("monitoring", true)
	set_deferred("collision_mask", MASK_HOSTILE if hostile else MASK_FRIENDLY)


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
	var victim_group := "player" if _hostile else "enemies"
	if hit.is_in_group(victim_group) and hit.has_method("apply_damage"):
		var dealt: int = hit.apply_damage(_damage)
		if dealt > 0:
			FloatingText.spawn(hit.global_position, dealt, _crit, _hostile)
		deactivate()
	elif hit.is_in_group("world"):
		deactivate()
