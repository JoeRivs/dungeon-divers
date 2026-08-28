extends CharacterBody2D

## Mini-tank. Slow, tough, hits hard with a long-telegraphed slam (it swells
## up before it lands, so it's dodgeable). Uncommon, and only turns up in the
## harder low-roll rooms.

const SPEED: float = 46.0
const ATTACK_RANGE: float = 40.0
const ATTACK_DICE := Vector2i(1, 6)
const ATTACK_WINDUP: float = 0.55
const ATTACK_COOLDOWN: float = 1.7

@onready var body: Polygon2D = $Body
@onready var health: Health = $Health
@onready var health_bar: Node = $EnemyHealthBar

var _player: Node2D = null
var _cooldown_left: float = 0.0
var _winding_up: bool = false
var _damage_mult: float = 1.0


func _ready() -> void:
	add_to_group("enemies")
	health.died.connect(_on_died)
	health_bar.bind(health)


func apply_threat(hp_mult: float, dmg_mult: float) -> void:
	_damage_mult = dmg_mult
	health.set_max_health(int(round(health.max_health * hp_mult)))


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)

	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			velocity = Vector2.ZERO
			return

	var to_player: Vector2 = _player.global_position - global_position
	var distance: float = to_player.length()

	if _winding_up:
		velocity = Vector2.ZERO
	elif distance > ATTACK_RANGE:
		velocity = to_player.normalized() * SPEED
	else:
		velocity = Vector2.ZERO
		if _cooldown_left <= 0.0:
			_slam()

	move_and_slide()


func _slam() -> void:
	_winding_up = true
	_cooldown_left = ATTACK_COOLDOWN
	body.modulate = Color(1.0, 0.65, 0.25)
	var swell := create_tween()
	swell.tween_property(body, "scale", Vector2(1.3, 1.3), ATTACK_WINDUP).set_trans(Tween.TRANS_CUBIC)

	await get_tree().create_timer(ATTACK_WINDUP).timeout
	if health.is_dead:
		return

	_winding_up = false
	body.modulate = Color.WHITE
	body.scale = Vector2.ONE
	if is_instance_valid(_player) \
			and global_position.distance_to(_player.global_position) <= ATTACK_RANGE + 16.0 \
			and _player.has_method("apply_damage"):
		var raw: int = Dice.roll(ATTACK_DICE.x, ATTACK_DICE.y)
		var rolled: int = maxi(int(round(raw * _damage_mult)), 1)
		var dealt: int = _player.apply_damage(rolled)
		if dealt > 0:
			FloatingText.spawn(_player.global_position, dealt,
					Dice.is_max(raw, ATTACK_DICE.x, ATTACK_DICE.y), true)


func apply_damage(amount: int) -> int:
	health.take_damage(amount)
	if health.is_dead:
		return amount
	body.modulate = Color.WHITE
	var tween := create_tween()
	tween.tween_property(body, "modulate", Color(0.5, 0.53, 0.58), 0.12)
	return amount


func _on_died() -> void:
	queue_free()
