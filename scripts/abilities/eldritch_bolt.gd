extends Ability

## Warlock primary: a hitscan lightning arc that snaps to the nearest enemy
## in the aim cone and strikes it. No Soul cost. Fizzles harmlessly if
## nothing's in front of you.

const ARC_FX := preload("res://scenes/fx/lightning_arc.tscn")
const RANGE: float = 270.0
const HALF_ANGLE: float = 0.36        ## ~20 degrees of aim slack
const MUZZLE: float = 14.0

## Forked Bolt forge: after the main hit, jump to the nearest other enemy.
const FORK_RANGE: float = 150.0
const FORK_MULT: float = 0.5


func _perform(origin: Vector2, direction: Vector2) -> void:
	var dir: Vector2 = direction.normalized()
	var start: Vector2 = origin + dir * MUZZLE

	var target: Node = null
	var best: float = RANGE
	for e in wielder.get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or not e.has_method("apply_damage"):
			continue
		var to_e: Vector2 = e.global_position - origin
		var dist: float = to_e.length()
		if dist <= RANGE and dist < best and to_e.normalized().dot(dir) > cos(HALF_ANGLE):
			target = e
			best = dist

	var end_pt: Vector2 = target.global_position if target != null else start + dir * RANGE
	var arc := ARC_FX.instantiate()
	wielder.get_parent().add_child(arc)
	arc.play(start, end_pt, Color(0.85, 0.92, 1.0))

	if target != null:
		var dmg: Dictionary = wielder.compute_damage(damage_dice, damage_kind)
		var dealt: int = target.apply_damage(dmg.amount)
		if dealt > 0:
			FloatingText.spawn(target.global_position, dealt, dmg.crit)
		if forge_id == &"forked":
			_fork_from(target)


## Chain to the nearest enemy other than `from`, within FORK_RANGE, for a
## fraction of a fresh damage roll.
func _fork_from(from: Node) -> void:
	var next: Node = null
	var best: float = FORK_RANGE
	for e in wielder.get_tree().get_nodes_in_group("enemies"):
		if e == from or not is_instance_valid(e) or not e.has_method("apply_damage"):
			continue
		var dist: float = (e.global_position - from.global_position).length()
		if dist < best:
			next = e
			best = dist
	if next == null:
		return

	var arc := ARC_FX.instantiate()
	wielder.get_parent().add_child(arc)
	arc.play(from.global_position, next.global_position, Color(0.7, 0.85, 1.0))

	var dmg: Dictionary = wielder.compute_damage(damage_dice, damage_kind)
	var amount: int = maxi(int(round(dmg.amount * FORK_MULT)), 1)
	var dealt: int = next.apply_damage(amount)
	if dealt > 0:
		FloatingText.spawn(next.global_position, dealt, dmg.crit)
