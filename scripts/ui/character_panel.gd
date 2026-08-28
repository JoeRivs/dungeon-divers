extends CanvasLayer

## Tab / Esc -> pause and show the build: class + archetype, the four
## attributes, the combat stats they derive into, and every upgrade taken.
## Rebuilt each time it opens so it always reflects current state.

const HEADER_COLOR := Color(1.0, 0.86, 0.4)
const DIM_COLOR := Color(0.7, 0.72, 0.78)

@onready var list: VBoxContainer = $Panel/Margin/Scroll/List

var _player: Node = null


func _ready() -> void:
	visible = false


func bind(player: Node) -> void:
	_player = player


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.is_pressed() and not event.is_echo()):
		return
	if event.keycode == KEY_TAB or (visible and event.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		if visible:
			_close()
		elif not get_tree().paused:      # don't open over another pause (upgrade pick, ...)
			_open()


func _open() -> void:
	_populate()
	visible = true
	get_tree().paused = true


func _close() -> void:
	visible = false
	get_tree().paused = false


func _populate() -> void:
	for c in list.get_children():
		c.queue_free()

	var s: Node = _player.get_node("Stats")

	_row("%s  —  %s" % [RunState.player_class.display_name, _archetype_name()], 26, HEADER_COLOR)
	_row("Floor %d · Room %d · %d gold" % [RunState.floor_index, RunState.room_index, RunState.gold], 15, DIM_COLOR)
	_gap()

	_row("ATTRIBUTES", 18, HEADER_COLOR)
	_row("Might     %d" % roundi(s.get_stat(&"might")))
	_row("Finesse   %d" % roundi(s.get_stat(&"finesse")))
	_row("Vitality  %d" % roundi(s.get_stat(&"vitality")))
	_row("Focus     %d" % roundi(s.get_stat(&"focus")))
	_gap()

	_row("COMBAT", 18, HEADER_COLOR)
	_dmg_row("Melee  (Might)  ", s, Sword.DAMAGE_DICE, &"melee")
	_dmg_row("Ranged (Finesse)", s, Bow.DAMAGE_DICE, &"ranged")
	_row("Max HP           %d" % roundi(s.get_stat(&"max_health")))
	_row("Move speed       %d" % roundi(s.get_stat(&"move_speed")))
	_row("Cooldown         %+d%%" % roundi((s.get_stat(&"cooldown_mult") - 1.0) * 100.0))
	_row("Damage reduction %d%%" % roundi(s.get_stat(&"damage_reduction") * 100.0))
	_gap()

	_row("UPGRADES (%d)" % RunState.upgrades.size(), 18, HEADER_COLOR)
	if RunState.upgrades.is_empty():
		_row("none yet", 14, DIM_COLOR)
	else:
		var seen: Dictionary = {}
		var order: Array = []
		for u in RunState.upgrades:
			if not seen.has(u.id):
				seen[u.id] = { "u": u, "n": 0 }
				order.append(u.id)
			seen[u.id]["n"] += 1
		for id in order:
			var e: Dictionary = seen[id]
			var times: String = "  ×%d" % e["n"] if e["n"] > 1 else ""
			_row("T%d  %s%s — %s" % [e["u"].tier, e["u"].display_name, times, e["u"].description], 14)


## One damage line: dice notation + flat + multiplier + the average a hit
## actually lands for (exact over the die faces, with the round + min-1).
func _dmg_row(label: String, s: Node, dice: Vector2i, kind: StringName) -> void:
	var flat: int = roundi(s.attack_flat(kind))
	var mult: float = s.attack_mult(kind)
	var flat_txt: String = " %+d" % flat if flat != 0 else ""
	_row("%s  %dd%d%s  ×%.2f   avg %.1f" % [label, dice.x, dice.y, flat_txt, mult, _avg_hit(s, dice, kind)])


func _avg_hit(s: Node, dice: Vector2i, kind: StringName) -> float:
	var flat: float = s.attack_flat(kind)
	var mult: float = s.attack_mult(kind)
	if dice.x == 1:
		var sum: float = 0.0
		for face in range(1, dice.y + 1):
			sum += maxf(round((float(face) + flat) * mult), 1.0)
		return sum / float(dice.y)
	var mean_roll: float = float(dice.x) * (float(dice.y) + 1.0) / 2.0
	return maxf((mean_roll + flat) * mult, 1.0)


func _archetype_name() -> String:
	var a: Archetype = RunState.player_class.get_archetype(RunState.archetype_id)
	return a.display_name if a != null else "?"


func _row(text: String, size: int = 16, color: Color = Color.WHITE) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	list.add_child(label)


func _gap() -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	list.add_child(spacer)
