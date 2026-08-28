extends Node2D

## One floating combat number, shaped like a d4 (the attack die). Rises,
## fades, frees itself.

@onready var label: Label = $Label
@onready var d4: Polygon2D = $D4


func show_amount(amount: int, crit: bool, hostile: bool) -> void:
	label.text = str(amount)

	var tint: Color = Color(1.0, 0.45, 0.4) if hostile else Color(1, 1, 1)
	if crit:
		tint = Color(1.0, 0.82, 0.2)
	label.add_theme_color_override("font_color", tint)
	d4.color = Color(tint.r, tint.g, tint.b, 0.22)

	var rise: float = 42.0 if crit else 26.0
	scale = Vector2.ONE * (1.35 if crit else 1.0)

	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - rise, 0.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.45) \
		.set_ease(Tween.EASE_IN).set_delay(0.15)
	tween.tween_callback(queue_free)
