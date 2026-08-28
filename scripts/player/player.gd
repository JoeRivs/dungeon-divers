extends CharacterBody2D

## Player-controlled adventurer.
## WASD move, aim with the mouse. LMB = primary weapon, RMB = secondary,
## Space = dodge, Q = archetype skill (if the archetype has one).
##
## Class + archetype are read from RunState on spawn: their stat modifiers
## are pushed onto $Stats and the archetype's hook scene is mounted as a
## child. Everything else (speed, damage, cooldowns, mitigation) reads back
## out of $Stats so upgrades and cards can move the numbers later.

signal attacked(kind: StringName, direction: Vector2)

const ACCELERATION: float = 2000.0
const FRICTION: float = 2200.0
const DODGE_SPEED: float = 620.0
const DODGE_DURATION: float = 0.18
const DODGE_COOLDOWN: float = 0.6

@onready var body: Sprite2D = $Body
@onready var nose: Polygon2D = $Nose
@onready var sword: Sword = $Sword
@onready var bow: Bow = $Bow
@onready var health: Health = $Health
@onready var stats: Stats = $Stats

var primary: Node                       ## responds to use(origin, direction)
var secondary: Node

var _hook: Node = null
var _aim_direction: Vector2 = Vector2.RIGHT
var _is_dodging: bool = false
var _is_invulnerable: bool = false
var _dodge_time_left: float = 0.0
var _dodge_cooldown_left: float = 0.0
var _dead: bool = false


func _ready() -> void:
	add_to_group("player")
	RunState.ensure_run()

	primary = sword
	secondary = bow
	_apply_loadout()

	health.bind_stats(stats)
	if RunState.current_health > 0:
		health.set_current(RunState.current_health)
	health.health_changed.connect(func(current: int, _maximum: int) -> void:
		RunState.set_health(current)
	)
	health.died.connect(_on_died)


func _apply_loadout() -> void:
	stats.clear_source(&"class")
	stats.clear_source(&"archetype")
	if _hook != null and is_instance_valid(_hook):
		_hook.queue_free()
		_hook = null

	var pc: PlayerClass = RunState.player_class
	if pc == null:
		return
	stats.add_modifiers(pc.base_modifiers, &"class")

	var arch: Archetype = pc.get_archetype(RunState.archetype_id)
	if arch == null:
		return
	stats.add_modifiers(arch.modifiers, &"archetype")
	if arch.hook_scene != null:
		_hook = arch.hook_scene.instantiate()
		add_child(_hook)


## Archetype hooks call this (e.g. Ranger swaps bow to primary).
func set_weapons(new_primary: Node, new_secondary: Node) -> void:
	primary = new_primary
	secondary = new_secondary


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
	var speed: float = stats.get_stat(&"move_speed")
	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(input_dir * speed, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

	if Input.is_action_just_pressed("dodge") and _dodge_cooldown_left <= 0.0:
		_start_dodge(input_dir)


func _handle_actions() -> void:
	if Input.is_action_just_pressed("attack_primary"):
		primary.use(global_position, _aim_direction)
		attacked.emit(&"primary", _aim_direction)
	if Input.is_action_just_pressed("attack_secondary"):
		secondary.use(global_position, _aim_direction)
		attacked.emit(&"secondary", _aim_direction)
	if Input.is_action_just_pressed("skill") and _hook != null and _hook.has_method("activate_skill"):
		_hook.activate_skill()


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


## Rolls attack damage through the player's offensive stats.
## Returns { amount: int, crit: bool }.
func compute_damage(dice: Vector2i) -> Dictionary:
	var raw: int = Dice.roll(dice.x, dice.y)
	var amount: int = int(round((raw + stats.get_stat(&"dice_bonus")) * stats.get_stat(&"damage_mult")))
	return {"amount": maxi(amount, 1), "crit": Dice.is_max(raw, dice.x, dice.y)}


func scaled_cooldown(base: float) -> float:
	return base * stats.get_stat(&"cooldown_mult")


## Returns the damage actually taken (0 if dodging / dead / fully mitigated).
func apply_damage(amount: int) -> int:
	if _dead or _is_invulnerable:
		return 0
	var taken: int = int(round(amount * (1.0 - stats.get_stat(&"damage_reduction"))))
	taken = maxi(taken, 0)
	if taken > 0:
		health.take_damage(taken)
		_flash()
	return taken


func _flash() -> void:
	body.modulate = Color(1.0, 0.4, 0.4)
	var tween := create_tween()
	tween.tween_property(body, "modulate", Color.WHITE, 0.15)


func _on_died() -> void:
	_dead = true
	velocity = Vector2.ZERO
	body.modulate = Color(0.35, 0.35, 0.35)
	await get_tree().create_timer(1.2).timeout
	RunState.start_new_run(RunState.player_class, RunState.archetype_id)
	get_tree().reload_current_scene()
