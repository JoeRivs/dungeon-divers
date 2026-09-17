extends Ability

## Conjurer primary: looses three homing darts that fan out and auto-target
## the nearest enemies (one each, wrapping if there are fewer). No aim, no
## miss - reliable clump clearing. Each dart rolls its own damage.

const PROJ := preload("res://scenes/projectiles/missile_proj.tscn")
const COUNT: int = 3
const BARRAGE_COUNT: int = 6           ## Barrage forge
const SPREAD: float = 0.5
const MUZZLE: float = 14.0

const HOMING_TURN_MULT: float = 2.2    ## Homing Instinct forge
const TWIN_CAST_COST: float = 18.0     ## Twin Cast forge - extra Soul per volley

## Overwhelm forge: consecutive volleys aimed entirely at ONE enemy (nobody
## else on screen) stack a focus bonus - the "delete the boss" build,
## opposite of Barrage's spread-across-the-room philosophy.
const OVERWHELM_PER_STACK: float = 0.18
const OVERWHELM_MAX_STACKS: int = 5

var _overwhelm_target: Node = null
var _overwhelm_stacks: int = 0


func _perform(origin: Vector2, direction: Vector2) -> void:
	var dir: Vector2 = direction.normalized()
	var count: int = BARRAGE_COUNT if has_forge(&"barrage") else COUNT
	var turn_mult: float = HOMING_TURN_MULT if has_forge(&"homing_instinct") else 1.0
	var pierce_hits: int = 0
	if has_forge(&"penetrating_missiles"):
		pierce_hits = 2 if has_etching(&"ricochet") else 1
	var volatile: bool = has_forge(&"volatile_missiles")
	var weaken_on_hit: bool = volatile and has_etching(&"critical_mass")

	var enemies: Array = []
	for e in wielder.get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.has_method("apply_damage"):
			enemies.append(e)
	enemies.sort_custom(func(a, b):
		return origin.distance_squared_to(a.global_position) < origin.distance_squared_to(b.global_position)
	)

	var overwhelm_mult: float = _update_overwhelm(enemies)

	var volleys: int = 2 if has_forge(&"twin_cast") else 1
	for v in volleys:
		if v > 0:
			wielder.spend_resource(TWIN_CAST_COST)
		_fire_volley(origin, dir, count, enemies, turn_mult, pierce_hits, volatile,
			weaken_on_hit, overwhelm_mult)


func _fire_volley(origin: Vector2, dir: Vector2, count: int, enemies: Array,
		turn_mult: float, pierce_hits: int, volatile: bool, weaken_on_hit: bool,
		overwhelm_mult: float) -> void:
	for i in count:
		var dmg: Dictionary = wielder.compute_damage(damage_dice, damage_kind)
		var target: Node = enemies[i % enemies.size()] if not enemies.is_empty() else null
		var amount: int = int(round(dmg.amount * overwhelm_mult))
		var fan: Vector2 = dir.rotated(lerpf(-SPREAD, SPREAD, float(i) / float(maxi(count - 1, 1))))
		var missile := PROJ.instantiate()
		wielder.get_parent().add_child(missile)
		missile.setup(origin + dir * MUZZLE, fan, amount, dmg.crit, target, turn_mult,
			pierce_hits, volatile, weaken_on_hit)


func _update_overwhelm(enemies: Array) -> float:
	if not has_forge(&"overwhelm"):
		return 1.0
	if enemies.size() == 1 and enemies[0] == _overwhelm_target:
		_overwhelm_stacks = mini(_overwhelm_stacks + 1, OVERWHELM_MAX_STACKS)
	elif enemies.size() == 1:
		_overwhelm_target = enemies[0]
		_overwhelm_stacks = 1
	else:
		_overwhelm_target = null
		_overwhelm_stacks = 0
	return 1.0 + OVERWHELM_PER_STACK * float(_overwhelm_stacks)
