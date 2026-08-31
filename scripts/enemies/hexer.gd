extends CharacterBody2D

## Ranged zoner. Holds mid-distance, strafes, and drops telegraphed ground
## AoEs AHEAD of where you're moving - so walking in a straight line gets you
## cooked; you have to break stride to dodge. Squishy and slow: close the gap
## and it folds.

const GROUND_AOE := preload("res://scenes/fx/ground_aoe.tscn")

const SPEED: float = 78.0
const NEAR: float = 165.0            ## back off if the player is inside this
const FAR: float = 330.0             ## drift closer past this
const CAST_COOLDOWN: float = 2.0
const CAST_WINDUP: float = 0.35      ## the caster's own tell before the marker drops
const AOE_RADIUS: float = 72.0
const AOE_WINDUP: float = 0.7        ## the ground marker's fill time
const CAST_DICE := Vector2i(1, 6)
const LEAD_TIME: float = 0.55        ## seconds of player movement to aim ahead by
const STRAFE_FLIP: float = 1.3       ## how often the mid-range strafe reverses

@onready var body: Polygon2D = $Body
@onready var health: Health = $Health
@onready var health_bar: Node = $EnemyHealthBar

var _player: Node2D = null
var _cast_cd: float = 1.0
var _casting: bool = false
var _damage_mult: float = 1.0
var _strafe_sign: float = 1.0
var _strafe_left: float = STRAFE_FLIP


func _ready() -> void:
	add_to_group("enemies")
	health.died.connect(_on_died)
	health_bar.bind(health)


func apply_threat(hp_mult: float, dmg_mult: float) -> void:
	_damage_mult = dmg_mult
	health.set_max_health(int(round(health.max_health * hp_mult)))


func _physics_process(delta: float) -> void:
	_cast_cd = maxf(_cast_cd - delta, 0.0)
	_strafe_left -= delta
	if _strafe_left <= 0.0:
		_strafe_left = STRAFE_FLIP
		_strafe_sign = -_strafe_sign

	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			velocity = Vector2.ZERO
			return

	var to_player: Vector2 = _player.global_position - global_position
	var dist: float = to_player.length()
	var dir: Vector2 = to_player / maxf(dist, 0.001)

	if _casting:
		velocity = Vector2.ZERO           # rooted while winding up - the tell
	elif dist < NEAR:
		velocity = -dir * SPEED
	elif dist > FAR:
		velocity = dir * SPEED
	else:
		velocity = dir.orthogonal() * _strafe_sign * SPEED * 0.7

	if not _casting and _cast_cd <= 0.0 and dist <= FAR + 30.0:
		_cast()

	move_and_slide()


func _cast() -> void:
	_casting = true
	_cast_cd = CAST_COOLDOWN
	body.modulate = Color(0.75, 0.5, 1.0)

	await get_tree().create_timer(CAST_WINDUP).timeout
	if health.is_dead:
		return
	_casting = false
	body.modulate = Color.WHITE

	var raw: int = Dice.roll(CAST_DICE.x, CAST_DICE.y)
	var dmg: int = maxi(int(round(raw * _damage_mult)), 1)
	var aoe := GROUND_AOE.instantiate()
	get_parent().add_child(aoe)
	aoe.setup(_predicted_mark(), AOE_RADIUS, dmg, AOE_WINDUP)


## Aim where the player is heading, not where they stand.
func _predicted_mark() -> Vector2:
	if not is_instance_valid(_player):
		return global_position
	var vel: Vector2 = Vector2.ZERO
	if _player is CharacterBody2D:
		vel = (_player as CharacterBody2D).velocity
	return _player.global_position + vel * LEAD_TIME


func apply_damage(amount: int) -> int:
	health.take_damage(amount)
	if health.is_dead:
		return amount
	body.modulate = Color.WHITE
	create_tween().tween_property(body, "modulate", Color(0.6, 0.4, 0.8), 0.12)
	return amount


func _on_died() -> void:
	queue_free()
