extends Node2D

## One floating combat/roll number, backed by the silhouette of the die it
## came from (d4 triangle, d20 hexagon, ...). Rises, fades, frees itself.

const DIE_RADIUS: float = 16.0

@onready var label: Label = $Label
@onready var die: Polygon2D = $Die


func show_amount(amount: int, crit: bool, hostile: bool, sides: int = 4) -> void:
	label.text = str(amount)
	die.polygon = Dice.shape(sides, DIE_RADIUS)

	var tint: Color = Color(1.0, 0.45, 0.4) if hostile else Color(1, 1, 1)
	if crit:
		tint = Color(1.0, 0.82, 0.2)
	label.add_theme_color_override("font_color", tint)
	die.color = Color(tint.r, tint.g, tint.b, 0.22)

	var rise: float = 42.0 if crit else 26.0
	scale = Vector2.ONE * (1.35 if crit else 1.0)

	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - rise, 0.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.45) \
		.set_ease(Tween.EASE_IN).set_delay(0.15)
	tween.tween_callback(queue_free)
