extends CharacterBody2D

## Ranged enemy. Kites the player - backs off if you close, chases if you
## run, and while you're in its band it strafes and looses hostile arrows
## after a short draw.

const SPEED: float = 92.0
const NEAR: float = 155.0        ## closer than this -> retreat
const FAR: float = 290.0         ## farther than this -> advance
const SHOOT_COOLDOWN: float = 1.5
const DRAW_TIME: float = 0.35
const SHOOT_DICE := Vector2i(1, 4)
const MUZZLE: float = 14.0

@onready var body: Polygon2D = $Body
@onready var health: Health = $Health
@onready var health_bar: Node = $EnemyHealthBar

var _player: Node2D = null
var _shoot_cd: float = 0.0
var _drawing: bool = false
var _damage_mult: float = 1.0


func _ready() -> void:
	add_to_group("enemies")
	health.died.connect(_on_died)
	health_bar.bind(health)


func apply_threat(hp_mult: float, dmg_mult: float) -> void:
	_damage_mult = dmg_mult
	health.set_max_health(int(round(health.max_health * hp_mult)))


func _physics_process(delta: float) -> void:
	_shoot_cd = maxf(_shoot_cd - delta, 0.0)

	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			velocity = Vector2.ZERO
			return

	var to_player: Vector2 = _player.global_position - global_position
	var distance: float = to_player.length()
	var dir: Vector2 = to_player / maxf(distance, 0.001)

	if _drawing:
		velocity = Vector2.ZERO
	elif distance < NEAR:
		velocity = -dir * SPEED
	elif distance > FAR:
		velocity = dir * SPEED
	else:
		velocity = dir.orthogonal() * SPEED * 0.6
		if _shoot_cd <= 0.0:
			_shoot()

	move_and_slide()


func _shoot() -> void:
	_drawing = true
	_shoot_cd = SHOOT_COOLDOWN
	body.modulate = Color(1.0, 0.9, 0.45)

	await get_tree().create_timer(DRAW_TIME).timeout
	if health.is_dead:
		return
	_drawing = false
	body.modulate = Color.WHITE

	if not is_instance_valid(_player):
		return
	var aim: Vector2 = (_player.global_position - global_position).normalized()
	var raw: int = Dice.roll(SHOOT_DICE.x, SHOOT_DICE.y)
	var amount: int = maxi(int(round(raw * _damage_mult)), 1)
	var arrow: Arrow = ProjectilePool.acquire_arrow()
	arrow.launch(global_position + aim * MUZZLE, aim, amount,
			Dice.is_max(raw, SHOOT_DICE.x, SHOOT_DICE.y), true)


func apply_damage(amount: int) -> int:
	health.take_damage(amount)
	if health.is_dead:
		return amount
	body.modulate = Color.WHITE
	var tween := create_tween()
	tween.tween_property(body, "modulate", Color(0.9, 0.9, 0.98), 0.12)
	return amount


func _on_died() -> void:
	queue_free()
