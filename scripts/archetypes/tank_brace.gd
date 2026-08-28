extends Node2D

## Knight "Tank" archetype hook. Skill (default Q): Brace - a short window of
## heavy damage reduction at the cost of near-stillness, on a cooldown.

const DURATION: float = 1.5
const COOLDOWN: float = 4.0
const DR_BONUS: float = 0.6
const SLOW_MUL: float = 0.35

@onready var _player: Node = get_parent()

var _active: bool = false
var _time_left: float = 0.0
var _cooldown_left: float = 0.0


func _process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if _active:
		_time_left -= delta
		if _time_left <= 0.0:
			_end()


## Called by the player when the "skill" action is pressed.
func activate_skill() -> void:
	if _active or _cooldown_left > 0.0:
		return
	_active = true
	_time_left = DURATION
	_cooldown_left = COOLDOWN
	_player.stats.add_modifier(StatModifier.make(&"damage_reduction", DR_BONUS), &"brace")
	_player.stats.add_modifier(StatModifier.make(&"move_speed", 0.0, SLOW_MUL), &"brace")
	_tint(Color(0.7, 0.85, 1.0))


func _end() -> void:
	_active = false
	_player.stats.clear_source(&"brace")
	_tint(Color.WHITE)


func _tint(color: Color) -> void:
	var b := _player.get_node_or_null("Body")
	if b != null:
		b.modulate = color
