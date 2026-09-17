class_name Weaken
extends Node2D

## Debuff: the host takes bonus damage from everything while this is up.
## A shared synergy primitive - whichever forge applies it, ANY other source
## of damage on that enemy benefits, so it's meant to be the connective
## tissue between otherwise-unrelated picks.

const DURATION: float = 3.0

var mult: float = 1.0
var _t: float = 0.0


## Static helper: apply/refresh Weaken on `target`. Multiple applications
## take the stronger of the two rather than stacking multiplicatively.
static func apply_to(target: Node, extra_mult: float, duration: float = DURATION) -> void:
	if not is_instance_valid(target):
		return
	var w = target.get_node_or_null("Weaken")
	if w == null:
		w = load("res://scenes/status/weaken.tscn").instantiate()
		w.name = "Weaken"
		w.mult = 1.0 + extra_mult
		w._t = duration
		target.add_child.call_deferred(w)
	else:
		w.mult = maxf(w.mult, 1.0 + extra_mult)
		w._t = duration


## Static helper: the multiplier to fold into a damage roll before it's dealt.
static func multiplier_on(target: Node) -> float:
	if not is_instance_valid(target):
		return 1.0
	var w = target.get_node_or_null("Weaken")
	return w.mult if is_instance_valid(w) else 1.0


func _process(delta: float) -> void:
	_t -= delta
	if _t <= 0.0:
		queue_free()
