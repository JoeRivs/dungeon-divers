extends Node2D

## Burn damage-over-time. apply() to (re)ignite a host; it ticks
## apply_damage then frees itself. One Burn per enemy - the caster
## refreshes rather than stacking.
##
## Two Pyromancer forge hooks, both opt-in via apply()'s trailing args:
## Wildfire (a kill by this burn's own tick spreads it to the nearest
## unburned enemy) and Backdraft (a kill by this burn's tick pays the
## wielder some Soul). Both only fire off a DEALT-BY-BURN kill, not any
## kill on a burning target.

const TICK: float = 0.5
const SPREAD_TICKS: int = 3          ## a spread catches for less/shorter
const SPREAD_RANGE: float = 140.0
const BACKDRAFT_REGEN: float = 6.0

var _ticks_left: int = 0
var _per_tick: int = 0
var _t: float = 0.0
var _wielder: Node = null
var _spread: bool = false
var _grant_regen: bool = false


func apply(_host: Node, total_ticks: int, per_tick: int, wielder: Node = null,
		spread: bool = false, grant_regen: bool = false) -> void:
	_ticks_left = maxi(_ticks_left, total_ticks)
	_per_tick = maxi(per_tick, _per_tick)
	if wielder != null:
		_wielder = wielder
	_spread = _spread or spread
	_grant_regen = _grant_regen or grant_regen


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

	var killed_it: bool = "health" in host and host.health.is_dead
	if killed_it:
		_on_kill(host)

	_ticks_left -= 1
	if _ticks_left <= 0 or killed_it:
		queue_free()


func _on_kill(host: Node) -> void:
	if _grant_regen and is_instance_valid(_wielder):
		_wielder.gain_resource(BACKDRAFT_REGEN)
	if _spread:
		_spread_to_nearest(host)


func _spread_to_nearest(host: Node) -> void:
	var nearest: Node = null
	var best: float = SPREAD_RANGE
	for e in host.get_tree().get_nodes_in_group("enemies"):
		if e == host or not is_instance_valid(e) or not e.has_method("apply_damage"):
			continue
		if e.get_node_or_null("Burn") != null:
			continue
		var dist: float = e.global_position.distance_to(host.global_position)
		if dist < best:
			nearest = e
			best = dist
	if nearest == null:
		return
	var spread_burn = load("res://scenes/status/burn.tscn").instantiate()
	spread_burn.name = "Burn"
	nearest.add_child.call_deferred(spread_burn)
	spread_burn.apply(nearest, SPREAD_TICKS, _per_tick, _wielder, true, _grant_regen)
