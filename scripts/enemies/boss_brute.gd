extends CharacterBody2D

## Floor boss. Chases at a walk; mid range it CHARGES; point blank it SLAMs;
## and from beyond charge range it lobs a telegraphed BOULDER at your feet,
## so kiting at distance isn't free. Summons a grunt + an archer on a timer.

const GRUNT_SCENE := preload("res://scenes/enemies/grunt.tscn")
const ARCHER_SCENE := preload("res://scenes/enemies/skeleton_archer.tscn")
const GROUND_AOE := preload("res://scenes/fx/ground_aoe.tscn")

const WALK_SPEED: float = 66.0
const CHARGE_SPEED: float = 440.0
const CONTACT_RANGE: float = 52.0
const CHARGE_RANGE: float = 340.0

const CHARGE_WINDUP: float = 0.55
const CHARGE_TIME: float = 0.55
const SLAM_WINDUP: float = 0.6
const SLAM_RADIUS: float = 130.0
const RECOVER: float = 0.9
const CHARGE_GAP: float = 2.0
const SUMMON_INTERVAL: float = 10.0

const BOULDER_WINDUP: float = 0.65
const BOULDER_RADIUS: float = 92.0
const BOULDER_AOE_WINDUP: float = 0.55
const BOULDER_GAP: float = 4.0

const CHARGE_DICE := Vector2i(2, 4)
const SLAM_DICE := Vector2i(1, 6)
const BOULDER_DICE := Vector2i(2, 6)

enum State { CHASE, CHARGE_WINDUP, CHARGING, SLAM_WINDUP, BOULDER_CAST, RECOVER }

@onready var body: Polygon2D = $Body
@onready var health: Health = $Health

var _player: Node2D = null
var _state: int = State.CHASE
var _timer: float = 0.0
var _charge_gap_left: float = 0.0
var _boulder_gap_left: float = 1.0
var _summon_left: float = SUMMON_INTERVAL
var _charge_dir: Vector2 = Vector2.ZERO
var _charge_hit_done: bool = false
var _damage_mult: float = 1.0


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	health.died.connect(_on_died)


func apply_threat(hp_mult: float, dmg_mult: float) -> void:
	_damage_mult = dmg_mult
	health.set_max_health(int(round(health.max_health * hp_mult)))


func _physics_process(delta: float) -> void:
	_timer -= delta
	_charge_gap_left = maxf(_charge_gap_left - delta, 0.0)
	_boulder_gap_left = maxf(_boulder_gap_left - delta, 0.0)
	_summon_left -= delta

	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			velocity = Vector2.ZERO
			return

	match _state:
		State.CHASE:
			_chase()
		State.CHARGE_WINDUP:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_charge_dir = _to_player().normalized()
				_charge_hit_done = false
				_state = State.CHARGING
				_timer = CHARGE_TIME
				body.modulate = Color(1.0, 0.45, 0.25)
		State.CHARGING:
			velocity = _charge_dir * CHARGE_SPEED
			_try_contact_hit(CHARGE_DICE)
			if _timer <= 0.0 or is_on_wall():
				_state = State.RECOVER
				_timer = RECOVER
				_charge_gap_left = CHARGE_GAP
				body.modulate = Color(0.7, 0.7, 0.8)
		State.SLAM_WINDUP:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_do_slam()
		State.BOULDER_CAST:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_lob_boulder()
		State.RECOVER:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_state = State.CHASE
				body.modulate = Color.WHITE

	move_and_slide()

	if _summon_left <= 0.0 and _state == State.CHASE:
		_summon_left = SUMMON_INTERVAL
		_summon()


func _chase() -> void:
	body.modulate = Color.WHITE
	var dist: float = _to_player().length()
	if dist <= CONTACT_RANGE:
		_state = State.SLAM_WINDUP
		_timer = SLAM_WINDUP
		body.modulate = Color(1.0, 0.8, 0.2)
	elif dist <= CHARGE_RANGE and _charge_gap_left <= 0.0:
		_state = State.CHARGE_WINDUP
		_timer = CHARGE_WINDUP
		body.modulate = Color(1.0, 0.6, 0.3)
	elif dist > CHARGE_RANGE:
		# kiting out of reach - lob a boulder, or amble closer while it's on cd
		if _boulder_gap_left <= 0.0:
			_state = State.BOULDER_CAST
			_timer = BOULDER_WINDUP
			body.modulate = Color(0.8, 0.5, 1.0)
		else:
			velocity = _to_player().normalized() * (WALK_SPEED * 0.55)
	else:
		velocity = _to_player().normalized() * WALK_SPEED


func _to_player() -> Vector2:
	return _player.global_position - global_position


func _try_contact_hit(dice: Vector2i) -> void:
	if _charge_hit_done:
		return
	if _to_player().length() <= CONTACT_RANGE and _player.has_method("apply_damage"):
		_charge_hit_done = true
		_deal(dice)


func _do_slam() -> void:
	_spawn_ring()
	if _to_player().length() <= SLAM_RADIUS and _player.has_method("apply_damage"):
		_deal(SLAM_DICE)
	_state = State.RECOVER
	_timer = RECOVER
	body.modulate = Color(0.7, 0.7, 0.8)


func _deal(dice: Vector2i) -> void:
	var raw: int = Dice.roll(dice.x, dice.y)
	var amount: int = maxi(int(round(raw * _damage_mult)), 1)
	var dealt: int = _player.apply_damage(amount)
	if dealt > 0:
		FloatingText.spawn(_player.global_position, dealt, Dice.is_max(raw, dice.x, dice.y), true)


func _lob_boulder() -> void:
	var mark: Vector2 = _player.global_position if is_instance_valid(_player) else global_position
	var raw: int = Dice.roll(BOULDER_DICE.x, BOULDER_DICE.y)
	var dmg: int = maxi(int(round(raw * _damage_mult)), 1)
	var aoe := GROUND_AOE.instantiate()
	get_parent().add_child(aoe)
	aoe.setup(mark, BOULDER_RADIUS, dmg, BOULDER_AOE_WINDUP)

	_boulder_gap_left = BOULDER_GAP
	_state = State.RECOVER
	_timer = RECOVER * 0.55
	body.modulate = Color(0.7, 0.7, 0.8)


func _spawn_ring() -> void:
	var ring := Polygon2D.new()
	ring.color = Color(1.0, 0.7, 0.3, 0.4)
	var pts: PackedVector2Array = []
	for i in 20:
		pts.append(Vector2.RIGHT.rotated(TAU * i / 20.0) * SLAM_RADIUS)
	ring.polygon = pts
	ring.scale = Vector2.ZERO
	add_child(ring)
	var tween := create_tween()
	tween.tween_property(ring, "scale", Vector2.ONE, 0.25)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.3)
	tween.tween_callback(ring.queue_free)


func apply_damage(amount: int) -> int:
	health.take_damage(amount)
	if health.is_dead:
		return amount
	var flashed := body.modulate
	body.modulate = Color.WHITE
	create_tween().tween_property(body, "modulate", flashed, 0.1)
	return amount


func _summon() -> void:
	for pair in [[GRUNT_SCENE, Vector2(-44, 34)], [ARCHER_SCENE, Vector2(44, 34)]]:
		var add := (pair[0] as PackedScene).instantiate()
		get_parent().add_child(add)
		add.global_position = global_position + (pair[1] as Vector2)
		if add.has_method("apply_threat"):
			add.apply_threat(1.0, _damage_mult)


func _on_died() -> void:
	queue_free()
