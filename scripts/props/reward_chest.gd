extends Area2D

## Spawns when a room is cleared. The upgrade pick does not open until the
## player walks into this - a deliberate beat so a mid-fight click can't
## grab a boon by accident. Shows the tier (as its die silhouette) so you
## know what's inside before you commit.

signal claimed

const BADGE_RADIUS: float = 20.0
const TIER_DIE := { 1: 20, 2: 12, 3: 8, 4: 4 }

@onready var glow: Polygon2D = $Glow
@onready var die_badge: Polygon2D = $DieBadge
@onready var tier_label: Label = $TierLabel

var _claimed: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var pulse := create_tween().set_loops()
	pulse.tween_property(glow, "modulate:a", 0.35, 0.9).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(glow, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)
	_check_initial_overlap.call_deferred()


## Safety net: body_entered doesn't fire for a body already inside the area
## when it spawns, so claim on the spot if the player is standing on it.
func _check_initial_overlap() -> void:
	await get_tree().physics_frame
	if _claimed:
		return
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			_on_body_entered(body)
			return


func setup(tier: int) -> void:
	var sides: int = TIER_DIE.get(tier, 20)
	die_badge.polygon = Dice.shape(sides, BADGE_RADIUS)
	tier_label.text = "TIER %d" % tier


func _on_body_entered(body: Node) -> void:
	if _claimed or not body.is_in_group("player"):
		return
	_claimed = true
	claimed.emit()
	var pop := create_tween()
	pop.tween_property(self, "scale", Vector2(1.3, 1.3), 0.12)
	pop.parallel().tween_property(self, "modulate:a", 0.0, 0.18)
	pop.tween_callback(queue_free)
