extends Area2D

## Sits in the middle of a Forge room. Walk into it to open the 1-of-3 forge
## pick. Same "don't fire on a body already overlapping at spawn" guard the
## reward chest uses. Stays put after use as decor.

signal used

@onready var glow: Polygon2D = $Glow

var _used: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var pulse := create_tween().set_loops()
	pulse.tween_property(glow, "modulate:a", 0.4, 1.0).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(glow, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE)
	_check_initial_overlap.call_deferred()


func _check_initial_overlap() -> void:
	await get_tree().physics_frame
	if _used:
		return
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			_on_body_entered(body)
			return


func _on_body_entered(body: Node) -> void:
	if _used or not body.is_in_group("player"):
		return
	_used = true
	set_deferred("monitoring", false)
	used.emit()
	var t := create_tween()
	t.tween_property(glow, "modulate:a", 0.0, 0.3)
	t.parallel().tween_property($Anvil, "modulate", Color(0.55, 0.55, 0.6), 0.3)
