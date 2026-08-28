class_name Sword
extends Area2D

## Melee weapon. swing() sweeps a short arc in front of the wielder and
## damages every enemy caught in the arc once per swing.

const DAMAGE_DICE := Vector2i(1, 4)   ## 1d4
const ARC: float = 1.4          ## total sweep, radians
const SWING_TIME: float = 0.18
const COOLDOWN: float = 0.35

@onready var blade: Polygon2D = $Blade
@onready var shape: CollisionShape2D = $Shape

var _swinging: bool = false
var _cooldown_left: float = 0.0
var _hit: Array[Node] = []


func _ready() -> void:
	monitoring = false
	shape.disabled = true
	blade.visible = false


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if not _swinging:
		return
	for target in get_overlapping_bodies():
		if target in _hit:
			continue
		if target.is_in_group("enemies") and target.has_method("apply_damage"):
			var rolled: int = Dice.roll(DAMAGE_DICE.x, DAMAGE_DICE.y)
			var dealt: int = target.apply_damage(rolled)
			if dealt > 0:
				FloatingText.spawn(target.global_position, dealt,
						Dice.is_max(rolled, DAMAGE_DICE.x, DAMAGE_DICE.y))
			_hit.append(target)


func swing(direction: Vector2) -> void:
	if _swinging or _cooldown_left > 0.0:
		return
	_swinging = true
	_cooldown_left = COOLDOWN
	_hit.clear()

	var base: float = direction.angle()
	rotation = base - ARC * 0.5
	monitoring = true
	shape.disabled = false
	blade.visible = true

	var tween := create_tween()
	tween.tween_property(self, "rotation", base + ARC * 0.5, SWING_TIME)
	tween.tween_callback(_end_swing)


func _end_swing() -> void:
	_swinging = false
	monitoring = false
	shape.disabled = true
	blade.visible = false
