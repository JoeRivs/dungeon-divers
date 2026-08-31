extends CharacterBody2D

## Mini-tank. Slow and tough. Its attack is a heavy LUNGE: it plants, swells
## up for a long telegraph, then hurls itself at where you were - big damage
## if it connects, and it's wide open on the recovery afterwards. Uncommon,
## and only in the harder low-roll rooms.

const SLASH_FX := preload("res://scenes/fx/slash_effect.tscn")

const SPEED: float = 46.0            ## chase
const STOP_RANGE: float = 92.0       ## close enough - stop and prepare
const LUNGE_TRIGGER: float = 168.0   ## start winding up within this
const WINDUP_TIME: float = 0.62      ## the telegraph
const LUNGE_SPEED: float = 440.0
const LUNGE_TIME: float = 0.34
const LUNGE_HIT_RANGE: float = 38.0
const RECOVER_TIME: float = 0.8
const COOLDOWN: float = 1.9
const ATTACK_DICE := Vector2i(2, 6)  ## 2d6 - hits hard
const RECOVER_VULN: float = 1.6      ## damage taken multiplier while recovering

enum { CHASE, WINDUP, LUNGE, RECOVER }

@onready var body: Polygon2D = $Body
@onready var health: Health = $Health
@onready var health_bar: Node = $EnemyHealthBar

var _player: Node2D = null
var _state: int = CHASE
var _timer: float = 0.0
var _cooldown_left: float = 0.0
var _lunge_dir: Vector2 = Vector2.RIGHT
var _lunge_hit: bool = false
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
	_timer -= delta

	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			velocity = Vector2.ZERO
			return

	var to_player: Vector2 = _player.global_position - global_position
	var distance: float = to_player.length()

	match _state:
		CHASE:
			body.modulate = Color.WHITE
			if distance <= LUNGE_TRIGGER and _cooldown_left <= 0.0:
				_enter_windup()
			elif distance > STOP_RANGE:
				velocity = to_player.normalized() * SPEED
			else:
				velocity = Vector2.ZERO
		WINDUP:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_enter_lunge(to_player.normalized())
		LUNGE:
			velocity = _lunge_dir * LUNGE_SPEED
			_try_lunge_hit(distance)
			if _timer <= 0.0 or is_on_wall():
				_enter_recover()
		RECOVER:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_state = CHASE

	move_and_slide()


func _enter_windup() -> void:
	_state = WINDUP
	_timer = WINDUP_TIME
	_cooldown_left = COOLDOWN
	body.modulate = Color(1.0, 0.6, 0.2)
	var swell := create_tween()
	swell.tween_property(body, "scale", Vector2(1.35, 1.12), WINDUP_TIME).set_trans(Tween.TRANS_CUBIC)


func _enter_lunge(dir: Vector2) -> void:
	_state = LUNGE
	_timer = LUNGE_TIME
	_lunge_hit = false
	_lunge_dir = dir if dir != Vector2.ZERO else _lunge_dir
	body.modulate = Color(1.0, 0.38, 0.14)
	body.scale = Vector2(1.15, 1.32)


func _enter_recover() -> void:
	_state = RECOVER
	_timer = RECOVER_TIME
	body.scale = Vector2.ONE
	body.modulate = Color(0.62, 0.62, 0.7)   # washed out = punish window


func _try_lunge_hit(distance: float) -> void:
	if _lunge_hit or distance > LUNGE_HIT_RANGE or not _player.has_method("apply_damage"):
		return
	_lunge_hit = true

	var fx := SLASH_FX.instantiate()
	get_parent().add_child(fx)
	fx.global_position = global_position + _lunge_dir * 20.0
	fx.play(_lunge_dir, 58.0, 40.0, Color(1.0, 0.42, 0.2, 0.88), 1.7)

	var raw: int = Dice.roll(ATTACK_DICE.x, ATTACK_DICE.y)
	var rolled: int = maxi(int(round(raw * _damage_mult)), 1)
	var dealt: int = _player.apply_damage(rolled)
	if dealt > 0:
		FloatingText.spawn(_player.global_position, dealt,
				Dice.is_max(raw, ATTACK_DICE.x, ATTACK_DICE.y), true)


func apply_damage(amount: int) -> int:
	var taken: int = amount
	if _state == RECOVER:
		taken = int(round(amount * RECOVER_VULN))
	health.take_damage(taken)
	if health.is_dead:
		return taken
	if _state != RECOVER:
		body.modulate = Color.WHITE
		var tween := create_tween()
		tween.tween_property(body, "modulate", Color(0.5, 0.53, 0.58), 0.12)
	return taken


func _on_died() -> void:
	queue_free()
