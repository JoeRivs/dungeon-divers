extends CharacterBody2D

## Player-controlled adventurer. WASD to move, aim with the mouse.
## LMB = primary, RMB = secondary, Q = skill, Space = dodge - each is an
## Ability node mounted in a slot. The class picks the slot loadout; an
## archetype can override individual slots and/or mount a passive hook.
## Everything numeric reads out of $Stats.

signal attacked(kind: StringName, direction: Vector2)

const ACCELERATION: float = 2000.0
const FRICTION: float = 2200.0

const SLOT_ACTIONS := {
	&"primary": "attack_primary",
	&"secondary": "attack_secondary",
	&"skill": "skill",
}

@onready var body: Node2D = $Body
@onready var nose: Polygon2D = $Nose
@onready var health: Health = $Health
@onready var stats: Stats = $Stats

var _slots: Dictionary = {}             ## slot name -> Ability
var _hook: Node = null

var _aim_direction: Vector2 = Vector2.RIGHT
var _dash_velocity: Vector2 = Vector2.ZERO
var _dash_time_left: float = 0.0
var _iframe_time_left: float = 0.0
var _dead: bool = false

var _resource: float = 0.0
var _resource_max: float = 0.0
var _resource_regen: float = 0.0


func _ready() -> void:
	add_to_group("player")
	RunState.ensure_run()
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
	if is_instance_valid(_hook):
		_hook.queue_free()
	_hook = null
	for a in _slots.values():
		if is_instance_valid(a):
			a.queue_free()
	_slots.clear()

	var pc: PlayerClass = RunState.player_class
	if pc == null:
		return
	stats.add_modifiers(pc.base_modifiers, &"class")
	_apply_skin(pc)

	var arch: Archetype = pc.get_archetype(RunState.archetype_id)
	if arch != null:
		stats.add_modifiers(arch.modifiers, &"archetype")
		if arch.hook_scene != null:
			_hook = arch.hook_scene.instantiate()
			add_child(_hook)

	for slot in [&"primary", &"secondary", &"skill", &"dodge"]:
		var scene: PackedScene = _slot_scene(pc, arch, slot)
		if scene == null:
			continue
		var ability: Ability = scene.instantiate()
		add_child(ability)
		ability.setup(self)
		_slots[slot] = ability

	_resource_max = stats.get_stat(&"resource_max")
	_resource_regen = stats.get_stat(&"resource_regen")
	_resource = _resource_max if pc.resource_starts_full else 0.0

	# re-apply any forge rewires taken so far this run
	for f in RunState.forges:
		apply_forge(f)


func _slot_scene(pc: PlayerClass, arch: Archetype, slot: StringName) -> PackedScene:
	if arch != null:
		var override: PackedScene = arch.ability_for(slot)
		if override != null:
			return override
	return pc.ability_for(slot)


func _physics_process(delta: float) -> void:
	_iframe_time_left = maxf(_iframe_time_left - delta, 0.0)

	if _dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_mouse: Vector2 = get_global_mouse_position() - global_position
	if to_mouse.length() > 1.0:
		_aim_direction = to_mouse.normalized()
	nose.rotation = _aim_direction.angle()

	if _resource_max > 0.0:
		# regen can be negative (a decaying "momentum" pool); floor at 0
		_resource = clampf(_resource + _resource_regen * delta, 0.0, _resource_max)

	body.modulate.a = 0.45 if _iframe_time_left > 0.0 else 1.0

	if _dash_time_left > 0.0:
		_dash_time_left -= delta
		velocity = _dash_velocity
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

	if Input.is_action_just_pressed("dodge") and _slots.has(&"dodge"):
		_slots[&"dodge"].try_use(global_position, input_dir)


func _handle_actions() -> void:
	for slot in SLOT_ACTIONS:
		if Input.is_action_just_pressed(SLOT_ACTIONS[slot]) and _slots.has(slot):
			if _slots[slot].try_use(global_position, _aim_direction):
				attacked.emit(slot, _aim_direction)


## Textured classes show $Body/Sprite; the rest show a placeholder figure -
## the robed caster ($Body/Robe...) or the hooded rogue ($Body/Rogue).
func _apply_skin(pc: PlayerClass) -> void:
	var tex: Texture2D = pc.body_texture
	var sprite: Sprite2D = $Body/Sprite
	sprite.visible = tex != null
	if tex != null:
		sprite.texture = tex
	var rogue: bool = tex == null and pc.body_style == &"rogue"
	for poly in [$Body/Robe, $Body/Hood, $Body/Rune]:
		poly.visible = tex == null and not rogue
	$Body/Rogue.visible = rogue


## --- primitives the abilities call back into -------------------------------

func facing() -> Vector2:
	return _aim_direction


func dash(vel: Vector2, duration: float, iframes: float) -> void:
	_dash_velocity = vel
	_dash_time_left = duration
	_iframe_time_left = maxf(_iframe_time_left, iframes)


func blink(offset: Vector2, iframes: float) -> void:
	move_and_collide(offset)        # travels as far as it can, stops at walls
	_iframe_time_left = maxf(_iframe_time_left, iframes)


func compute_damage(dice: Vector2i, kind: StringName = &"melee") -> Dictionary:
	var raw: int = Dice.roll(dice.x, dice.y)
	var amount: int = int(round((raw + stats.attack_flat(kind)) * stats.attack_mult(kind)))
	return {"amount": maxi(amount, 1), "crit": Dice.is_max(raw, dice.x, dice.y)}


func scaled_cooldown(base: float) -> float:
	return base * stats.get_stat(&"cooldown_mult")


func resource_value() -> float:
	return _resource


func spend_resource(amount: float) -> void:
	_resource = maxf(_resource - amount, 0.0)


func gain_resource(amount: float) -> void:
	_resource = minf(_resource + amount, _resource_max)


func has_resource() -> bool:
	return _resource_max > 0.0


func resource_ratio() -> float:
	return _resource / _resource_max if _resource_max > 0.0 else 0.0


func slots() -> Dictionary:
	return _slots


## Route a forge rewire to whichever mounted slot holds its target ability.
func apply_forge(f: ForgeUpgrade) -> void:
	for slot in _slots:
		var ab = _slots[slot]
		if is_instance_valid(ab) and ab.ability_id == f.ability_id:
			ab.apply_forge(f.id)
			return


## Returns the damage actually taken (0 if dodging / dead / fully mitigated).
func apply_damage(amount: int) -> int:
	if _dead or _iframe_time_left > 0.0:
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
	# run restart is handled by the run shell (listens to health.died)
	_dead = true
	velocity = Vector2.ZERO
	body.modulate = Color(0.35, 0.35, 0.35)
