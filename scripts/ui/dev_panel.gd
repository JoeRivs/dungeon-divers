extends CanvasLayer

## Dev tool: instantly apply any Boon / Forge / Etching to the current
## character for testing, no grinding required. F1 to toggle, Esc to
## close. Everything here bypasses the normal gates (room clears, Forge
## rooms, kill XP) - it's a testing shortcut, not part of the real loop.

const HEADER_COLOR := Color(1.0, 0.86, 0.4)
const DIM_COLOR := Color(0.7, 0.72, 0.78)
const TAKEN_COLOR := Color(0.55, 0.62, 0.55)

@onready var list: VBoxContainer = $Panel/Margin/Scroll/List

var _player: Node = null
var _hud: CanvasLayer = null


func _ready() -> void:
	visible = false


func bind(player: Node, hud: CanvasLayer) -> void:
	_player = player
	_hud = hud


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.is_pressed() and not event.is_echo()):
		return
	if event.keycode == KEY_F1 or (visible and event.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		if visible:
			_close()
		elif not get_tree().paused:
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

	if not is_instance_valid(_player):
		_row("no player bound", 14, DIM_COLOR)
		return

	_row("DEV TOOL  —  F1 / Esc to close", 20, HEADER_COLOR)
	_row("Click applies instantly, no room/kill gate. Green = already taken "
		+ "(re-clicking is a safe no-op).", 12, DIM_COLOR)
	_gap()

	_row("EXTRAS", 16, HEADER_COLOR)
	_button("+100 XP", _cheat_xp)
	_button("+50 Gold", _cheat_gold)
	_button("Heal to full", _cheat_heal)
	_button("Clear ALL picks (boons + forges + etchings, fresh loadout)", _cheat_clear)
	_gap()

	_row("BOONS  (%d - repeats allowed, matches the real pool)" % Upgrades._all().size(),
		16, HEADER_COLOR)
	for u in Upgrades._all():
		_button("T%d  %s  —  %s" % [u.tier, u.display_name, u.description],
			_apply_upgrade.bind(u))
	_gap()

	_row("FORGES  (%d)" % Forges._all().size(), 16, HEADER_COLOR)
	for f in Forges._all():
		_forge_button(f)
	_gap()

	_row("ETCHINGS  (%d)" % Etchings._all().size(), 16, HEADER_COLOR)
	for e in Etchings._all():
		_etching_button(e)


func _forge_button(f: ForgeUpgrade) -> void:
	var taken: bool = RunState.forges.any(func(x): return x.id == f.id)
	var lock: String = "  [%s only]" % f.requires_archetype if f.requires_archetype != &"" else ""
	var label: String = "%s%s (%s)%s  —  %s" % [
		"[TAKEN] " if taken else "", f.display_name, f.ability_id, lock, f.description]
	_button(label, func() -> void:
		if not RunState.forges.any(func(x): return x.id == f.id):
			RunState.forges.append(f)
		_player.apply_forge(f)
		_populate(), taken)


func _etching_button(e: Etching) -> void:
	var taken: bool = RunState.etchings.any(func(x): return x.id == e.id)
	var gates: Array = []
	if e.requires_forge != &"":
		gates.append("needs Forge %s" % e.requires_forge)
	if e.requires_etching != &"":
		gates.append("needs Etching %s" % e.requires_etching)
	if e.requires_archetype != &"":
		gates.append("%s only" % e.requires_archetype)
	var gate_txt: String = "  [%s]" % ", ".join(gates) if not gates.is_empty() else ""
	var label: String = "%s%s (%s)%s  —  %s" % [
		"[TAKEN] " if taken else "", e.display_name, e.ability_id, gate_txt, e.description]
	_button(label, func() -> void:
		if not RunState.etchings.any(func(x): return x.id == e.id):
			RunState.etchings.append(e)
		_player.apply_etching(e)
		_populate(), taken)


func _apply_upgrade(u: Upgrade) -> void:
	_player.stats.add_modifiers(u.modifiers, &"upgrade")
	var tag := String(u.special)
	if tag.begins_with("gold"):
		RunState.gold += tag.substr(4).to_int()
	elif tag.begins_with("heal"):
		_player.health.heal(tag.substr(4).to_int())
	RunState.upgrades.append(u)
	_refresh_hud()


func _cheat_xp() -> void:
	RunState.gain_xp(100)
	_refresh_hud()


func _cheat_gold() -> void:
	RunState.gold += 50
	_refresh_hud()


func _cheat_heal() -> void:
	_player.health.heal(9999)


func _cheat_clear() -> void:
	RunState.upgrades.clear()
	RunState.forges.clear()
	RunState.etchings.clear()
	_player.stats.clear_source(&"upgrade")
	_player._apply_loadout()
	_refresh_hud()
	_populate()


func _refresh_hud() -> void:
	if is_instance_valid(_hud):
		_hud.refresh_run()


func _button(text: String, on_press: Callable, dim: bool = false) -> void:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_size_override("font_size", 13)
	if dim:
		b.add_theme_color_override("font_color", TAKEN_COLOR)
	b.pressed.connect(on_press)
	list.add_child(b)


func _row(text: String, size: int = 16, color: Color = Color.WHITE) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	list.add_child(label)


func _gap() -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	list.add_child(spacer)
