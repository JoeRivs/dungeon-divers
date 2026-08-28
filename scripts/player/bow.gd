class_name Bow
extends Node2D

## Ranged weapon. fire() pulls a pooled arrow and launches it toward the
## aim direction.

const COOLDOWN: float = 0.45
const MUZZLE_OFFSET: float = 16.0

var _cooldown_left: float = 0.0


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)


func fire(origin: Vector2, direction: Vector2) -> void:
	if _cooldown_left > 0.0:
		return
	_cooldown_left = COOLDOWN
	var arrow: Arrow = ProjectilePool.acquire_arrow()
	arrow.launch(origin + direction.normalized() * MUZZLE_OFFSET, direction)
