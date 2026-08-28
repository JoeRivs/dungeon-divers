extends CharacterBody2D

## Player-controlled adventurer.
## WASD to move, aim with the mouse, LMB swings the sword, RMB fires the
## bow, Space dodges (a short burst with brief i-frames).

const SPEED: float = 220.0
const ACCELERATION: float = 2000.0
const FRICTION: float = 2200.0

const DODGE_SPEED: float = 620.0
const DODGE_DURATION: float = 0.18
const DODGE_COOLDOWN: float = 0.6

@onready var body: Polygon2D = $Body
@onready var nose: Polygon2D = $Nose
@onready var sword: Sword = $Sword
@onready var bow: Bow = $Bow
@onready var health: Health = $Health

var _aim_direction: Vector2 = Vector2.RIGHT
var _is_dodging: bool = false
var _is_invulnerable: bool = false
var _dodge_time_left: float = 0.0
var _dodge_cooldown_left: float = 0.0
var _dead: bool = false


func _ready() -> void:
	add_to_group("player")
	health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	if _dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_mouse: Vector2 = get_global_mouse_position() - global_position
	if to_mouse.length() > 1.0:
		_aim_direction = to_mouse.normalized()
	nose.rotation = _aim_direction.angle()

	_dodge_cooldown_left = maxf(_dodge_cooldown_left - delta, 0.0)

	if _is_dodging:
		_dodge_time_left -= delta
		if _dodge_time_left <= 0.0:
			_end_dodge()
	else:
		_handle_movement(delta)
		_handle_actions()

	move_and_slide()


func _handle_movement(delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(input_dir * SPEED, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

	if Input.is_action_just_pressed("dodge") and _dodge_cooldown_left <= 0.0:
		_start_dodge(input_dir)


func _handle_actions() -> void:
	if Input.is_action_just_pressed("attack_sword"):
		sword.swing(_aim_direction)
	if Input.is_action_just_pressed("attack_bow"):
		bow.fire(global_position, _aim_direction)


func _start_dodge(input_dir: Vector2) -> void:
	var dir: Vector2 = input_dir if input_dir != Vector2.ZERO else _aim_direction
	_is_dodging = true
	_is_invulnerable = true
	_dodge_time_left = DODGE_DURATION
	velocity = dir.normalized() * DODGE_SPEED
	body.modulate = Color(1, 1, 1, 0.4)


func _end_dodge() -> void:
	_is_dodging = false
	_is_invulnerable = false
	_dodge_cooldown_left = DODGE_COOLDOWN
	body.modulate = Color.WHITE


## Returns the damage actually applied (0 if dodging / dead), so the
## attacker knows whether to pop a damage number.
func apply_damage(amount: int) -> int:
	if _dead or _is_invulnerable:
		return 0
	health.take_damage(amount)
	_flash()
	return amount


func _flash() -> void:
	body.modulate = Color(1.0, 0.4, 0.4)
	var tween := create_tween()
	tween.tween_property(body, "modulate", Color.WHITE, 0.15)


func _on_died() -> void:
	_dead = true
	velocity = Vector2.ZERO
	body.modulate = Color(0.35, 0.35, 0.35)
	await get_tree().create_timer(1.2).timeout
	get_tree().reload_current_scene()
