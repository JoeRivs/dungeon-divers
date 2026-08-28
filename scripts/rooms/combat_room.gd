extends Node2D

## A parametric combat room. setup() derives a threat budget from the rolled
## difficulty + floor and spends it on grunts and skeleton archers. Harder
## rooms (a low roll) split that budget across 2-3 timed WAVES - the next
## only spawns once the current one is dead. Clears when the last wave falls.

signal cleared
signal reward_claimed

const GRUNT := preload("res://scenes/enemies/grunt.tscn")
const ARCHER := preload("res://scenes/enemies/skeleton_archer.tscn")
const OGRE := preload("res://scenes/enemies/ogre.tscn")
const DOOR := preload("res://scenes/props/door.tscn")
const REWARD_CHEST := preload("res://scenes/props/reward_chest.tscn")

const MAX_PER_WAVE: int = 8
const WAVE_GAP: float = 1.0

## ogre = mini-tank: expensive, so it only turns up when the budget is fat
## (a low roll), and only rarely even then
const OGRE_COST: float = 2.5
const OGRE_MIN_BUDGET: float = 2.5
const OGRE_MAX_DIFFICULTY: int = 6
const OGRE_CHANCE: float = 0.28
const ARCHER_COST: float = 1.5
const GRUNT_COST: float = 1.0

@onready var arena: Node2D = $Arena

var _alive: int = 0
var _cleared: bool = false
var _doors: Array = []

var _difficulty: int = 12
var _wave: int = 0
var _wave_count: int = 1
var _wave_budget: float = 0.0
var _hp_mult: float = 1.0
var _dmg_mult: float = 1.0


func get_entry_point() -> Vector2:
	return Vector2(0.0, arena.half_height - 48.0)


func get_doors() -> Array:
	return _doors


## Drop a reward chest ~100px toward the exits from wherever the player is
## standing, so they always have to step to it (and it never spawns on top
## of them, which would swallow the body_entered).
func spawn_reward(tier: int) -> void:
	var chest := REWARD_CHEST.instantiate()
	add_child(chest)
	var here: Vector2 = Vector2.ZERO
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		here = player.global_position
	var spot := here + Vector2(0.0, -100.0)
	spot.x = clampf(spot.x, -arena.half_width + 60.0, arena.half_width - 60.0)
	spot.y = clampf(spot.y, -arena.half_height + 70.0, arena.half_height - 60.0)
	chest.global_position = spot
	chest.setup(tier)
	chest.claimed.connect(func() -> void: reward_claimed.emit())


func setup(difficulty: int, floor_index: int) -> void:
	_difficulty = difficulty
	var total: float = _threat_budget(difficulty, floor_index)
	_wave_count = _waves_for(difficulty)
	_wave_budget = maxf(total / float(_wave_count), 2.5)
	_hp_mult = 1.0 + 0.25 * float(floor_index - 1)
	_dmg_mult = 1.0 + 0.15 * float(floor_index - 1)
	_spawn_wave()


## Low rolled number = harder room = more waves.
func _waves_for(difficulty: int) -> int:
	if difficulty <= 4:
		return 3
	if difficulty <= 9:
		return 2
	return 1


func _spawn_wave() -> void:
	if _cleared or not is_inside_tree():
		return
	_wave += 1
	var budget: float = _wave_budget
	var slots: Array = _spawn_slots()
	var spawned: int = 0

	while budget >= 1.0 and spawned < MAX_PER_WAVE:
		var scene: PackedScene
		var cost: float
		if budget >= OGRE_MIN_BUDGET and _difficulty <= OGRE_MAX_DIFFICULTY and randf() < OGRE_CHANCE:
			scene = OGRE
			cost = OGRE_COST
		elif budget >= 1.5 and randf() < 0.4:
			scene = ARCHER
			cost = ARCHER_COST
		else:
			scene = GRUNT
			cost = GRUNT_COST

		var enemy := scene.instantiate()
		add_child(enemy)
		enemy.global_position = slots[(spawned + _wave) % slots.size()]
		if enemy.has_method("apply_threat"):
			enemy.apply_threat(_hp_mult, _dmg_mult)
		enemy.tree_exited.connect(_on_enemy_gone)
		enemy.scale = Vector2(0.5, 0.5)
		enemy.create_tween().tween_property(enemy, "scale", Vector2.ONE, 0.18) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_alive += 1
		budget -= cost
		spawned += 1

	if _alive == 0:
		_advance_or_finish()


func reveal_doors(options: Array) -> void:
	var slots: Array = _door_slots()
	for idx in mini(options.size(), slots.size()):
		var door := DOOR.instantiate()
		add_child(door)
		door.global_position = slots[idx]
		door.setup(options[idx])
		door.unlock()
		_doors.append(door)


func _on_enemy_gone() -> void:
	_alive -= 1
	if _alive <= 0 and not _cleared and is_inside_tree():
		_advance_or_finish()


func _advance_or_finish() -> void:
	if _cleared or not is_inside_tree():
		return
	if _wave < _wave_count:
		# short breather, then the next wave
		get_tree().create_timer(WAVE_GAP).timeout.connect(_spawn_wave)
	else:
		_finish()


func _finish() -> void:
	_cleared = true
	# deferred: the last enemy's tree_exited fires mid tree-teardown, and the
	# handler spawns doors - can't add_child until that settles.
	cleared.emit.call_deferred()


## difficulty is the rolled number (1..die). Low = many enemies. A d4 door
## can only roll 1-4, so it always lands deep in the danger zone.
func _threat_budget(difficulty: int, floor_index: int) -> float:
	var t: float = remap(float(clampi(difficulty, 1, 20)), 20.0, 1.0, 0.0, 8.0)
	return maxf(t, 0.0) * (1.0 + 0.3 * float(floor_index - 1))


func _spawn_slots() -> Array:
	var hw: float = arena.half_width - 80.0
	var hh: float = arena.half_height - 80.0
	return [
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(-hw, 0.0), Vector2(hw, 0.0),
		Vector2(0.0, -hh), Vector2(-hw * 0.4, hh * 0.2), Vector2(hw * 0.4, hh * 0.2),
	]


func _door_slots() -> Array:
	var y: float = -arena.half_height + 4.0
	return [Vector2(-230.0, y), Vector2(0.0, y), Vector2(230.0, y)]
