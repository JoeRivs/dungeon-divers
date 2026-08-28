extends CanvasLayer

## Screen-space run HUD: player health, gold, floor/room, a boss bar that
## shows only during boss fights, and a centre banner for run end.

@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthBar/Label
@onready var gold_label: Label = $GoldLabel
@onready var location_label: Label = $LocationLabel
@onready var boss_bar: ProgressBar = $BossBar
@onready var banner: Label = $Banner
@onready var roll_layer: CanvasLayer = $RollReveal
@onready var roll_root: Node2D = $RollReveal/Root
@onready var roll_die: Polygon2D = $RollReveal/Root/Die
@onready var roll_value: Label = $RollReveal/Root/Value


func _ready() -> void:
	boss_bar.visible = false
	banner.visible = false
	roll_layer.visible = false


func bind(health: Health) -> void:
	health.health_changed.connect(_on_health_changed)
	_on_health_changed(health.current_health, health.max_health)


func _on_health_changed(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "%d / %d" % [current, maximum]


func refresh_run() -> void:
	gold_label.text = "Gold: %d" % RunState.gold
	location_label.text = "Floor %d  -  Room %d" % [RunState.floor_index, RunState.room_index]


func bind_boss(boss: Node) -> void:
	var h: Health = boss.health
	boss_bar.visible = true
	boss_bar.max_value = h.max_health
	boss_bar.value = h.current_health
	h.health_changed.connect(func(current: int, maximum: int) -> void:
		boss_bar.max_value = maximum
		boss_bar.value = current
	)


func hide_boss() -> void:
	boss_bar.visible = false


func show_banner(text: String) -> void:
	banner.text = text
	banner.visible = true


## Big centre-screen reveal of a d20 room roll: pops in, holds ~1s, fades.
func show_roll(value: int, sides: int) -> void:
	roll_root.position = get_viewport().get_visible_rect().size * 0.5
	roll_die.polygon = Dice.shape(sides, 92.0)
	roll_value.text = str(value)

	# how good the roll is relative to the die you picked
	var ratio: float = float(value) / float(maxi(sides, 1))
	var tint := Color.WHITE
	if ratio <= 0.34:
		tint = Color(1.0, 0.40, 0.34)      # rolled low -> rough room
	elif ratio >= 0.80:
		tint = Color(0.5, 0.95, 0.5)       # rolled high -> easy room
	roll_die.color = Color(tint.r, tint.g, tint.b, 0.30)
	roll_value.add_theme_color_override("font_color", tint)

	roll_layer.visible = true
	roll_root.modulate.a = 0.0
	roll_root.scale = Vector2(0.55, 0.55)

	var tween := create_tween()
	tween.tween_property(roll_root, "scale", Vector2(1.08, 1.08), 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(roll_root, "modulate:a", 1.0, 0.14)
	tween.tween_property(roll_root, "scale", Vector2.ONE, 0.12)
	tween.tween_interval(1.0)
	tween.tween_property(roll_root, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func() -> void: roll_layer.visible = false)
