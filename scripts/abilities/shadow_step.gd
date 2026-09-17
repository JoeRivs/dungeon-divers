extends Ability

## Warlock dodge: an instant blink in the aim / move direction, stopping at
## walls, with brief i-frames. No mana. You keep moving through it.

const BLINK_DIST: float = 108.0
const IFRAMES: float = 0.34
const PUFF_COLOR := Color(0.35, 0.15, 0.5, 0.6)

## Umbral Step forge (class-shared): landing lashes out at anything close by
## and marks it Weaken - pairs with any damage source in the kit, not just
## this ability.
const UMBRAL_RADIUS: float = 70.0
const UMBRAL_DICE := Vector2i(1, 4)
const UMBRAL_WEAKEN: float = 0.25

## Cinder Step etching (requires Umbral Step): the burst also ignites.
const CINDER_TICKS: int = 3
const CINDER_DMG: int = 2

## Quickened Step etching: a flat cooldown cut, no forge needed - useful
## the moment you pick a class, before you've found a single Forge room.
const QUICKENED_CUT: float = 0.22


func _perform(_origin: Vector2, direction: Vector2) -> void:
	var dir: Vector2 = direction if direction != Vector2.ZERO else wielder.facing()
	_puff(wielder.global_position)
	wielder.blink(dir.normalized() * BLINK_DIST, IFRAMES)
	_puff(wielder.global_position)
	if has_forge(&"umbral_step"):
		_umbral_burst()


func _umbral_burst() -> void:
	var at: Vector2 = wielder.global_position
	for e in wielder.get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or not e.has_method("apply_damage"):
			continue
		if e.global_position.distance_to(at) > UMBRAL_RADIUS:
			continue
		var dmg: Dictionary = wielder.compute_damage(UMBRAL_DICE, &"spell")
		var dealt: int = e.apply_damage(dmg.amount)
		if dealt > 0:
			FloatingText.spawn(e.global_position, dealt, dmg.crit)
		Weaken.apply_to(e, UMBRAL_WEAKEN)
		if has_etching(&"cinder_step"):
			_ignite(e)


func _ignite(enemy: Node) -> void:
	var burn := enemy.get_node_or_null("Burn")
	if burn == null:
		burn = load("res://scenes/status/burn.tscn").instantiate()
		burn.name = "Burn"
		enemy.add_child.call_deferred(burn)
	burn.apply(enemy, CINDER_TICKS, CINDER_DMG)


func _on_etching(id: StringName) -> void:
	if id == &"quickened_step":
		base_cooldown = maxf(base_cooldown - QUICKENED_CUT, 0.1)


func _puff(at: Vector2) -> void:
	var puff := Polygon2D.new()
	puff.color = PUFF_COLOR
	puff.z_index = 2
	var pts: PackedVector2Array = []
	for i in 8:
		pts.append(Vector2.RIGHT.rotated(TAU * float(i) / 8.0) * 15.0)
	puff.polygon = pts
	wielder.get_parent().add_child(puff)
	puff.global_position = at
	var tween := puff.create_tween()
	tween.tween_property(puff, "modulate:a", 0.0, 0.2)
	tween.tween_callback(puff.queue_free)
