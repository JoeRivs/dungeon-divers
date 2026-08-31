extends CharacterBody2D

## Basic melee enemy: walks straight at the player and, once in reach,
## telegraphs briefly then hits them. Easy to dodge through the windup.
## TODO: lift these stats into an EnemyType resource in res://data/.

const SLASH_FX := preload("res://scenes/fx/slash_effect.tscn")

const SPEED: float = 78.0
const ATTACK_RANGE: float = 26.0
const ATTACK_DICE := Vector2i(1, 4)   ## 1d4
const ATTACK_WINDUP: float = 0.25
const ATTACK_COOLDOWN: float = 1.1

@onready var body: Polygon2D = $Body
@onready var health: Health = $Health
@onready var health_bar: Node = $EnemyHealthBar

var _player: Node2D = null
var _attack_cooldown_left: float = 0.0
var _winding_up: bool = false
var _damage_mult: float = 1.0


func _ready() -> void:
	add_to_group("enemies")
	health.died.connect(_on_died)
	health_bar.bind(health)


## Room difficulty / floor scaling, applied right after spawn.
func apply_threat(hp_mult: float, dmg_mult: float) -> void:
	_damage_mult = dmg_mult
	health.set_max_health(int(round(health.max_health * hp_mult)))


func _physics_process(delta: float) -> void:
	_attack_cooldown_left = maxf(_attack_cooldown_left - delta, 0.0)

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
		if _attack_cooldown_left <= 0.0:
			_start_attack()

	move_and_slide()


func _start_attack() -> void:
	_winding_up = true
	_attack_cooldown_left = ATTACK_COOLDOWN
	body.modulate = Color(1.0, 0.85, 0.3)

	await get_tree().create_timer(ATTACK_WINDUP).timeout
	if health.is_dead:
		return

	_winding_up = false
	body.modulate = Color.WHITE
	if not is_instance_valid(_player):
		return

	var dir: Vector2 = (_player.global_position - global_position).normalized()
	_slash(dir)

	if global_position.distance_to(_player.global_position) <= ATTACK_RANGE + 10.0 \
			and _player.has_method("apply_damage"):
		var raw: int = Dice.roll(ATTACK_DICE.x, ATTACK_DICE.y)
		var rolled: int = maxi(int(round(raw * _damage_mult)), 1)
		var dealt: int = _player.apply_damage(rolled)
		if dealt > 0:
			FloatingText.spawn(_player.global_position, dealt,
					Dice.is_max(raw, ATTACK_DICE.x, ATTACK_DICE.y), true)


func _slash(dir: Vector2) -> void:
	var fx := SLASH_FX.instantiate()
	get_parent().add_child(fx)
	fx.global_position = global_position + dir * 12.0
	fx.play(dir, 34.0, 20.0, Color(1.0, 0.55, 0.4, 0.8), 1.5)


func apply_damage(amount: int) -> int:
	health.take_damage(amount)
	if health.is_dead:
		return amount
	body.modulate = Color.WHITE
	var tween := create_tween()
	tween.tween_property(body, "modulate", Color(0.85, 0.2, 0.2), 0.12)
	return amount


func _on_died() -> void:
	queue_free()
