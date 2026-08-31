extends Ability

## Conjurer primary: looses three homing darts that fan out and auto-target
## the nearest enemies (one each, wrapping if there are fewer). No aim, no
## miss - reliable clump clearing. Each dart rolls its own damage.

const PROJ := preload("res://scenes/projectiles/missile_proj.tscn")
const COUNT: int = 3
const BARRAGE_COUNT: int = 6           ## Barrage forge
const SPREAD: float = 0.5
const MUZZLE: float = 14.0


func _perform(origin: Vector2, direction: Vector2) -> void:
	var dir: Vector2 = direction.normalized()
	var count: int = BARRAGE_COUNT if forge_id == &"barrage" else COUNT

	var enemies: Array = []
	for e in wielder.get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.has_method("apply_damage"):
			enemies.append(e)
	enemies.sort_custom(func(a, b):
		return origin.distance_squared_to(a.global_position) < origin.distance_squared_to(b.global_position)
	)

	for i in count:
		var dmg: Dictionary = wielder.compute_damage(damage_dice, damage_kind)
		var target: Node = enemies[i % enemies.size()] if not enemies.is_empty() else null
		var fan: Vector2 = dir.rotated(lerpf(-SPREAD, SPREAD, float(i) / float(maxi(count - 1, 1))))
		var missile := PROJ.instantiate()
		wielder.get_parent().add_child(missile)
		missile.setup(origin + dir * MUZZLE, fan, dmg.amount, dmg.crit, target)
