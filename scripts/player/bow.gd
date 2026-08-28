class_name Bow
extends Node2D

## Ranged weapon. use() rolls damage through the wielder's stats, pulls a
## pooled arrow and launches it toward the aim direction.

const KIND := &"ranged"
const DAMAGE_DICE := Vector2i(1, 4)
const BASE_COOLDOWN: float = 0.45
const MUZZLE_OFFSET: float = 16.0

@onready var _wielder: Node = get_parent()

var _cooldown_left: float = 0.0


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)


func use(origin: Vector2, direction: Vector2) -> void:
	if _cooldown_left > 0.0:
		return
	_cooldown_left = _wielder.scaled_cooldown(BASE_COOLDOWN)

	var dmg: Dictionary = _wielder.compute_damage(DAMAGE_DICE)
	var arrow: Arrow = ProjectilePool.acquire_arrow()
	arrow.launch(origin + direction.normalized() * MUZZLE_OFFSET, direction, dmg.amount, dmg.crit)
