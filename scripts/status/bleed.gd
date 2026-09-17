extends Node2D

## Stacking bleed DoT (the Bleeding Edge etching). Each hit adds a stack (and
## refreshes the duration); stacks cap out. Hemorrhage, if also taken, can
## detonate a maxed stack early for one heavy hit instead of letting it
## finish ticking - the combo payoff.

const TICK: float = 0.6
const MAX_STACKS: int = 4
const DURATION_TICKS: int = 5
const PER_STACK: int = 2

var stacks: int = 0
var _ticks_left: int = 0
var _t: float = 0.0


func add_stack() -> void:
	stacks = mini(stacks + 1, MAX_STACKS)
	_ticks_left = DURATION_TICKS


func is_maxed() -> bool:
	return stacks >= MAX_STACKS


## Hemorrhage: pop early for one heavy hit, then clear.
func burst(mult: float) -> int:
	var host := get_parent()
	if not is_instance_valid(host) or not host.has_method("apply_damage"):
		queue_free()
		return 0
	var amount: int = maxi(int(round(PER_STACK * stacks * mult)), 1)
	var dealt: int = host.apply_damage(amount)
	if dealt > 0:
		FloatingText.spawn(host.global_position + Vector2(0.0, -8.0), dealt, true)
	queue_free()
	return dealt


func _process(delta: float) -> void:
	_t += delta
	if _t < TICK:
		return
	_t = 0.0

	var host := get_parent()
	if not is_instance_valid(host) or not host.has_method("apply_damage"):
		queue_free()
		return

	var dealt: int = host.apply_damage(PER_STACK * stacks)
	if dealt > 0:
		FloatingText.spawn(host.global_position + Vector2(0.0, -6.0), dealt, false)

	_ticks_left -= 1
	if _ticks_left <= 0:
		queue_free()
