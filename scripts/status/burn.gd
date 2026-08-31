extends Node2D

## Burn damage-over-time. apply() to (re)ignite a host; it ticks apply_damage
## then frees itself. One Burn per enemy - the caster refreshes rather than
## stacking.

const TICK: float = 0.5

var _ticks_left: int = 0
var _per_tick: int = 0
var _t: float = 0.0


func apply(_host: Node, total_ticks: int, per_tick: int) -> void:
	_ticks_left = maxi(_ticks_left, total_ticks)
	_per_tick = maxi(per_tick, _per_tick)


func _process(delta: float) -> void:
	_t += delta
	if _t < TICK:
		return
	_t = 0.0

	var host := get_parent()
	if not is_instance_valid(host) or not host.has_method("apply_damage"):
		queue_free()
		return

	var dealt: int = host.apply_damage(_per_tick)
	if dealt > 0:
		FloatingText.spawn(host.global_position + Vector2(0.0, -6.0), dealt, false)

	_ticks_left -= 1
	if _ticks_left <= 0:
		queue_free()
