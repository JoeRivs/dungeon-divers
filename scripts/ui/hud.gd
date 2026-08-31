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
@onready var mana_bar: ProgressBar = $ManaBar
@onready var ability_row: HBoxContainer = $Abilities

const SLOT_KEYS := { &"primary": "LMB", &"secondary": "RMB", &"skill": "Q", &"dodge": "SPC" }
const SLOT_ORDER: Array[StringName] = [&"primary", &"secondary", &"skill", &"dodge"]

var _player: Node = null
var _slot_labels: Dictionary = {}


func _ready() -> void:
	boss_bar.visible = false
	banner.visible = false
	roll_layer.visible = false
	mana_bar.visible = false


func bind(health: Health) -> void:
	health.health_changed.connect(_on_health_changed)
	_on_health_changed(health.current_health, health.max_health)


func bind_player(player: Node) -> void:
	_player = player
	mana_bar.visible = player.has_resource()
	for c in ability_row.get_children():
		c.queue_free()
	_slot_labels.clear()
	var slots: Dictionary = player.slots()
	for slot in SLOT_ORDER:
		if not slots.has(slot):
			continue
		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		lbl.add_theme_constant_override("outline_size", 4)
		ability_row.add_child(lbl)
		_slot_labels[slot] = lbl


func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		return
	if mana_bar.visible:
		mana_bar.value = _player.resource_ratio() * 100.0
	var slots: Dictionary = _player.slots()
	for slot in _slot_labels:
		var ability = slots.get(slot)
		var lbl: Label = _slot_labels[slot]
		if not is_instance_valid(ability):
			lbl.text = ""
			continue
		var key: String = SLOT_KEYS.get(slot, "?")
		if ability.cooldown_left > 0.05:
			lbl.text = "%s %s  %.1fs" % [key, ability.display_name, ability.cooldown_left]
			lbl.modulate = Color(0.55, 0.56, 0.62)
		elif not ability.can_use():
			lbl.text = "%s %s" % [key, ability.display_name]
			lbl.modulate = Color(0.62, 0.5, 0.72)
		else:
			lbl.text = "%s %s" % [key, ability.display_name]
			lbl.modulate = Color.WHITE


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
