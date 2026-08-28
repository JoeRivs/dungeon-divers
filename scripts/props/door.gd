extends Area2D

## A room exit. You choose the DIE, not a number: the badge is that die's
## silhouette (d4 triangle ... d20 hexagon) and the label shows the upgrade
## tier it leads to. The difficulty number is rolled only when you walk
## through. Starts locked (dim, no collision); unlock() arms it.

signal chosen(option: RoomOption)

const BADGE_RADIUS: float = 21.0

@onready var glow: Polygon2D = $Glow
@onready var die_badge: Polygon2D = $DieBadge
@onready var diff_label: Label = $DiffLabel
@onready var reward_label: Label = $RewardLabel

var option: RoomOption
var _armed: bool = false


func _ready() -> void:
	monitoring = false
	glow.visible = false
	body_entered.connect(_on_body_entered)


func setup(opt: RoomOption) -> void:
	option = opt
	die_badge.polygon = Dice.shape(opt.die_sides, BADGE_RADIUS)

	# lower die = more danger = warmer badge
	var danger: float = 1.0 - float(opt.die_sides) / 20.0
	if opt.is_boss:
		die_badge.color = Color(0.95, 0.32, 0.32, 0.4)
	else:
		die_badge.color = Color(0.5 + danger * 0.45, 0.8 - danger * 0.4, 1.0 - danger * 0.55, 0.32)

	diff_label.text = "BOSS" if opt.is_boss else "d%d" % opt.die_sides
	reward_label.text = "TIER %d" % opt.tier()


func unlock() -> void:
	_armed = true
	monitoring = true
	glow.visible = true
	modulate = Color(1, 1, 1, 1)


func _on_body_entered(b: Node) -> void:
	if _armed and b.is_in_group("player"):
		_armed = false
		chosen.emit(option)
