extends Ability

## Warlock secondary: a short-range cone that strikes the nearest enemy in
## front of you for spell damage and heals you for a fraction of it. Costs
## Soul.

const SLASH_FX := preload("res://scenes/fx/slash_effect.tscn")
# damage_dice (Vector2i(1, 6)) is exported on Ability
const REACH: float = 130.0
const HALF_ANGLE: float = 0.5          ## radians
const HEAL_FRACTION: float = 0.35
const VAMPIRIC_FONT_MULT: float = 2.0  ## Vampiric Font forge doubles the heal


func _perform(origin: Vector2, direction: Vector2) -> void:
	var dir: Vector2 = direction.normalized()

	var fx := SLASH_FX.instantiate()
	wielder.get_parent().add_child(fx)
	fx.global_position = origin + dir * 22.0
	fx.play(dir, REACH * 0.72, 30.0, Color(0.72, 0.32, 0.98, 0.8), 0.95)

	var best: Node = null
	var best_dist: float = REACH
	for e in wielder.get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or not e.has_method("apply_damage"):
			continue
		var to_e: Vector2 = e.global_position - origin
		var dist: float = to_e.length()
		if dist <= REACH and dist < best_dist and to_e.normalized().dot(dir) > cos(HALF_ANGLE):
			best = e
			best_dist = dist
	if best == null:
		return

	var dmg: Dictionary = wielder.compute_damage(damage_dice, damage_kind)
	var dealt: int = best.apply_damage(dmg.amount)
	if dealt > 0:
		FloatingText.spawn(best.global_position, dealt, dmg.crit)
		var frac: float = HEAL_FRACTION
		if forge_id == &"vampiric_font":
			frac *= VAMPIRIC_FONT_MULT
		wielder.health.heal(maxi(int(round(float(dealt) * frac)), 1))
