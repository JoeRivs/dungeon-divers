extends Node2D

## Floor-boss room. Bigger arena, one boss (scaled by floor). Clears when the
## boss dies; reveal_doors() then opens the single exit to the next floor.

signal cleared
signal reward_claimed

const BOSS := preload("res://scenes/enemies/boss_brute.tscn")
const DOOR := preload("res://scenes/props/door.tscn")
const REWARD_CHEST := preload("res://scenes/props/reward_chest.tscn")

@onready var arena: Node2D = $Arena

var _boss: Node = null
var _doors: Array = []


func get_entry_point() -> Vector2:
	return Vector2(0.0, arena.half_height - 48.0)


func get_doors() -> Array:
	return _doors


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


func get_boss() -> Node:
	return _boss


func setup(_difficulty: int, floor_index: int) -> void:
	# fixed, roomy arena with two pillars to break the boss's charge
	arena.build(540.0, 360.0, [
		RoomLayout.block(Vector2(-175.0, -30.0), Vector2(72.0, 72.0)),
		RoomLayout.block(Vector2(175.0, -30.0), Vector2(72.0, 72.0)),
	])

	_boss = BOSS.instantiate()
	add_child(_boss)
	_boss.global_position = Vector2(0.0, -arena.half_height * 0.4)
	if _boss.has_method("apply_threat"):
		_boss.apply_threat(1.0 + 0.4 * float(floor_index - 1), 1.0 + 0.2 * float(floor_index - 1))
	_boss.tree_exited.connect(_on_boss_gone)


func reveal_doors(options: Array) -> void:
	if options.is_empty():
		return
	var door := DOOR.instantiate()
	add_child(door)
	door.global_position = Vector2(0.0, -arena.half_height + 4.0)
	door.setup(options[0])
	door.unlock()
	_doors.append(door)


func _on_boss_gone() -> void:
	# deferred: tree_exited fires mid teardown; the handler spawns a door.
	cleared.emit.call_deferred()
