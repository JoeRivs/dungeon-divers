extends Ability

## Occultist primary: a hitscan lightning arc that snaps to (or, forged,
## pierces through) enemies in the aim cone. No Soul cost. Fizzles
## harmlessly if nothing's in front of you.

const ARC_FX := preload("res://scenes/fx/lightning_arc.tscn")
const RANGE: float = 270.0
const HALF_ANGLE: float = 0.36        ## ~20 degrees of aim slack
const MUZZLE: float = 14.0

## Forked Bolt forge: after the main hit, jump to the nearest other enemy.
const FORK_RANGE: float = 150.0
const FORK_MULT: float = 0.5

## Static Charge etching: a bolted kill leaves a small damaging pulse.
const PULSE_RANGE: float = 70.0
const PULSE_DMG: int = 3

## Arc Reach forge: much longer range/cone, and prefers the weakest enemy
## in range instead of the nearest - a sniper picking off stragglers.
const ARC_REACH_RANGE_MULT: float = 1.6
const ARC_REACH_ANGLE_MULT: float = 1.8

## Executioner's Bolt forge: bonus damage on a low-HP target.
const EXECUTE_THRESHOLD: float = 0.3
const EXECUTE_MULT: float = 2.0

## Charged Shot forge: every Nth cast is free and hits much harder.
const CHARGED_EVERY: int = 4
const CHARGED_MULT: float = 2.0

## Soul Siphon forge: a bolt kill refunds Soul.
const SIPHON_AMOUNT: float = 12.0

var _cast_count: int = 0


func _perform(origin: Vector2, direction: Vector2) -> void:
	var dir: Vector2 = direction.normalized()
	var start: Vector2 = origin + dir * MUZZLE
	var range: float = RANGE * (ARC_REACH_RANGE_MULT if has_forge(&"arc_reach") else 1.0)
	var half_angle: float = HALF_ANGLE * (ARC_REACH_ANGLE_MULT if has_forge(&"arc_reach") else 1.0)

	_cast_count += 1
	var charged: bool = has_forge(&"charged_shot") and _cast_count % CHARGED_EVERY == 0

	if has_forge(&"piercing_bolt"):
		_pierce_line(origin, start, dir, range, half_angle, charged)
	else:
		_snap_single(origin, start, dir, range, half_angle, charged)

	if charged:
		cooldown_left = 0.0


## Default targeting: nearest enemy in the cone (Arc Reach: weakest instead).
## Snaps and strikes once, then may fork (Forked Bolt).
func _snap_single(origin: Vector2, start: Vector2, dir: Vector2, range: float,
		half_angle: float, charged: bool) -> void:
	var target: Node = _pick_target(origin, dir, range, half_angle)
	var end_pt: Vector2 = target.global_position if target != null else start + dir * range
	_zap(start, end_pt)
	if target == null:
		return

	var dmg: Dictionary = wielder.compute_damage(damage_dice, damage_kind)
	var amount: int = dmg.amount
	if charged:
		amount = int(round(amount * CHARGED_MULT))
	amount = _apply_execute(target, amount)
	amount = weakened(target, amount)
	var dealt: int = target.apply_damage(amount)
	if dealt > 0:
		FloatingText.spawn(target.global_position, dealt, dmg.crit or charged)
	_on_bolt_landed(target)

	if has_forge(&"forked"):
		var jumps: int = 2 if has_etching(&"overcharge_chain") else 1
		_fork_from(target, [target], jumps)


## Piercing Bolt forge: the bolt is a line, not a snap - hits everyone in
## the cone along it, once each. If Forked Bolt is ALSO held, the line
## doesn't just stop at the cone's edge: the last enemy it caught chains on
## to one more straggler outside it - "clear the room, then reach the one
## that wasn't even in the line."
func _pierce_line(origin: Vector2, start: Vector2, dir: Vector2, range: float,
		half_angle: float, charged: bool) -> void:
	_zap(start, start + dir * range)
	var hits: Array = _all_in_cone(origin, dir, range, half_angle)
	for target in hits:
		var dmg: Dictionary = wielder.compute_damage(damage_dice, damage_kind)
		var amount: int = dmg.amount
		if charged:
			amount = int(round(amount * CHARGED_MULT))
		amount = _apply_execute(target, amount)
		amount = weakened(target, amount)
		var dealt: int = target.apply_damage(amount)
		if dealt > 0:
			FloatingText.spawn(target.global_position, dealt, dmg.crit or charged)
		_on_bolt_landed(target)

	if has_forge(&"forked") and not hits.is_empty():
		var jumps: int = 2 if has_etching(&"overcharge_chain") else 1
		_fork_from(hits[-1], hits.duplicate(), jumps)


func _apply_execute(target: Node, amount: int) -> int:
	if not has_forge(&"executioners_bolt") or not ("health" in target):
		return amount
	var h = target.health
	if h.max_health > 0 and float(h.current_health) / float(h.max_health) <= EXECUTE_THRESHOLD:
		return int(round(amount * EXECUTE_MULT))
	return amount


func _on_bolt_landed(target: Node) -> void:
	_maybe_pulse(target)
	if has_forge(&"soul_siphon") and "health" in target and target.health.is_dead:
		wielder.gain_resource(SIPHON_AMOUNT)


func _zap(from: Vector2, to: Vector2) -> void:
	var arc := ARC_FX.instantiate()
	wielder.get_parent().add_child(arc)
	arc.play(from, to, Color(0.85, 0.92, 1.0))


func _pick_target(origin: Vector2, dir: Vector2, range: float, half_angle: float) -> Node:
	var prefer_weakest: bool = has_forge(&"arc_reach")
	var best_target: Node = null
	var best_score: float = range if not prefer_weakest else 2.0
	for e in wielder.get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or not e.has_method("apply_damage"):
			continue
		var to_e: Vector2 = e.global_position - origin
		var dist: float = to_e.length()
		if dist > range or to_e.normalized().dot(dir) <= cos(half_angle):
			continue
		if prefer_weakest and ("health" in e) and e.health.max_health > 0:
			var ratio: float = float(e.health.current_health) / float(e.health.max_health)
			if ratio < best_score:
				best_target = e
				best_score = ratio
		elif not prefer_weakest and dist < best_score:
			best_target = e
			best_score = dist
	return best_target


func _all_in_cone(origin: Vector2, dir: Vector2, range: float, half_angle: float) -> Array:
	var out: Array = []
	for e in wielder.get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or not e.has_method("apply_damage"):
			continue
		var to_e: Vector2 = e.global_position - origin
		var dist: float = to_e.length()
		if dist <= range and to_e.normalized().dot(dir) > cos(half_angle):
			out.append(e)
	out.sort_custom(func(a, b) -> bool:
		return origin.distance_squared_to(a.global_position) < origin.distance_squared_to(b.global_position)
	)
	return out


## Chain to the nearest OTHER enemy (excluding `exclude`) within FORK_RANGE,
## for a fraction of a fresh damage roll, up to `jumps_left` times. Base
## Forked Bolt = 1 jump; Overcharge Chain etching bumps that to 2.
func _fork_from(from: Node, exclude: Array, jumps_left: int) -> void:
	if jumps_left <= 0:
		return
	var next: Node = _nearest_enemy_to(from.global_position, exclude, FORK_RANGE)
	if next == null:
		return

	_zap(from.global_position, next.global_position)
	var dmg: Dictionary = wielder.compute_damage(damage_dice, damage_kind)
	var amount: int = maxi(int(round(dmg.amount * FORK_MULT)), 1)
	amount = _apply_execute(next, amount)
	amount = weakened(next, amount)
	var dealt: int = next.apply_damage(amount)
	if dealt > 0:
		FloatingText.spawn(next.global_position, dealt, dmg.crit)
	_on_bolt_landed(next)

	exclude.append(next)
	_fork_from(next, exclude, jumps_left - 1)


func _nearest_enemy_to(pos: Vector2, exclude: Array, range: float) -> Node:
	var nearest: Node = null
	var best: float = range
	for e in wielder.get_tree().get_nodes_in_group("enemies"):
		if e in exclude or not is_instance_valid(e) or not e.has_method("apply_damage"):
			continue
		var dist: float = (e.global_position - pos).length()
		if dist < best:
			nearest = e
			best = dist
	return nearest


func _maybe_pulse(target: Node) -> void:
	if not has_etching(&"static_charge"):
		return
	if not ("health" in target) or not target.health.is_dead:
		return
	var at: Vector2 = target.global_position
	for e in wielder.get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or not e.has_method("apply_damage"):
			continue
		if e.global_position.distance_to(at) > PULSE_RANGE:
			continue
		var dealt: int = e.apply_damage(PULSE_DMG)
		if dealt > 0:
			FloatingText.spawn(e.global_position, dealt, false)
