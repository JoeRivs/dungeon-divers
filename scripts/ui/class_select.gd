extends Control

## Start screen. Two steps: pick a class, then pick an archetype within it.
## Esc backs out to the class list.

const CLASS_BLURB := {
	&"knight": "Melee bruiser. Sword and bow, a committed dodge-roll. Sturdy, no arcane knack.",
	&"warlock": "Ranged caster. Eldritch Bolt, a life-draining strike, a Hex burst, and a blink. Spends Soul.",
	&"duelist": "Fast, fragile hit-and-run melee. Momentum builds as you land hits and dash, then dumps into a scaling finisher. Bleeds away if you stop fighting.",
}
const ARCH_BLURB := {
	&"shadow": "A hitless echo of you trails behind, mirroring every strike.",
	&"tank": "Heavy plate. Brace (Q) shrugs off a burst; you move like a drawbridge.",
	&"ranger": "Bow to the front. Fast and lethal at range, thin on armour.",
	&"occultist": "Single-target lightning, free to cast. Nimble, average frame — the reference caster.",
	&"pyromancer": "Fireball — a slow lob that bursts and burns, and it costs Soul. Deepest pool, fastest regen, sturdier and quicker so you can fight up close.",
	&"conjurer": "Magic Missiles — three homing darts, no aim, no miss. Plant and turtle: heaviest armor, slowest feet.",
	&"bladedancer": "The all-rounder. Momentum decays slower, so you land a heavy Finisher just about every fight.",
	&"assassin": "Ambush — your first hit on a fresh enemy lands double and pays bonus Momentum. Glassy; open hard, finish fast.",
	&"windblade": "Primary becomes Whirl, a 360° spin that hits the whole pack and floods Momentum. Fastest feet.",
}

@onready var title: Label = $Layout/Title
@onready var hint: Label = $Layout/Hint
@onready var cards: HBoxContainer = $Layout/Cards

var _chosen_class: PlayerClass = null


func _ready() -> void:
	_show_classes()


func _show_classes() -> void:
	_chosen_class = null
	title.text = "Choose a class"
	hint.text = "click a card, or press  1 / 2 / 3"
	_clear()
	var list := Classes.all()
	for i in list.size():
		var pc: PlayerClass = list[i]
		_add_card("%d\n\n%s\n\n%s" % [i + 1, pc.display_name.to_upper(), CLASS_BLURB.get(pc.id, "")],
			_pick_class.bind(pc))


func _show_archetypes() -> void:
	title.text = "Choose your %s" % _chosen_class.display_name
	hint.text = "1 / 2 / 3 to pick  ·  Esc to go back"
	_clear()
	for i in _chosen_class.archetypes.size():
		var arch: Archetype = _chosen_class.archetypes[i]
		_add_card("%d\n\n%s\n\n%s\n\n%s" % [
			i + 1, arch.display_name.to_upper(), ARCH_BLURB.get(arch.id, ""), _spread(arch),
		], _pick_archetype.bind(arch.id))


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.is_pressed() and not event.is_echo()):
		return
	if event.keycode == KEY_ESCAPE and _chosen_class != null:
		get_viewport().set_input_as_handled()
		_show_classes()
		return
	var idx: int = { KEY_1: 0, KEY_2: 1, KEY_3: 2 }.get(event.keycode, -1)
	if idx >= 0 and idx < cards.get_child_count():
		get_viewport().set_input_as_handled()
		cards.get_child(idx).emit_signal("pressed")


func _pick_class(pc: PlayerClass) -> void:
	_chosen_class = pc
	_show_archetypes()


func _pick_archetype(archetype_id: StringName) -> void:
	RunState.start_new_run(_chosen_class, archetype_id)
	get_tree().change_scene_to_file("res://scenes/run.tscn")


func _add_card(text: String, on_press: Callable) -> void:
	var card := Button.new()
	card.custom_minimum_size = Vector2(250, 320)
	card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_theme_font_size_override("font_size", 16)
	card.text = text
	card.pressed.connect(on_press)
	cards.add_child(card)
	if cards.get_child_count() == 1:
		card.grab_focus()


func _clear() -> void:
	for c in cards.get_children():
		c.queue_free()


func _spread(arch: Archetype) -> String:
	return "Might %d   Finesse %d\nVitality %d   Focus %d" % [
		_attr(arch, &"might"), _attr(arch, &"finesse"),
		_attr(arch, &"vitality"), _attr(arch, &"focus"),
	]


func _attr(arch: Archetype, key: StringName) -> int:
	var value: float = 10.0
	for m in _chosen_class.base_modifiers:
		if m.stat == key:
			value += m.add
	for m in arch.modifiers:
		if m.stat == key:
			value += m.add
	return roundi(value)
