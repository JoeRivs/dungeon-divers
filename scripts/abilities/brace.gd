extends Ability

## Tank skill: a short window of heavy damage reduction at the cost of
## near-stillness.

const DURATION: float = 1.5
const DR_BONUS: float = 0.6
const SLOW_MUL: float = 0.35

var _active_left: float = 0.0


func _process(delta: float) -> void:
	super(delta)
	if _active_left > 0.0:
		_active_left -= delta
		if _active_left <= 0.0:
			_end()


func _perform(_origin: Vector2, _direction: Vector2) -> void:
	_active_left = DURATION
	wielder.stats.add_modifier(StatModifier.make(&"damage_reduction", DR_BONUS), &"brace")
	wielder.stats.add_modifier(StatModifier.make(&"move_speed", 0.0, SLOW_MUL), &"brace")
	_tint(Color(0.7, 0.85, 1.0))


func _end() -> void:
	wielder.stats.clear_source(&"brace")
	_tint(Color.WHITE)


func _tint(color: Color) -> void:
	var body := wielder.get_node_or_null("Body")
	if body != null:
		body.modulate = color
