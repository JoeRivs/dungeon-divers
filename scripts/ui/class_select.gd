extends Control

## Start screen. Pick a build, then the run begins. One class (Knight) for
## now, so the choices are its three archetypes; this grows into a real
## class grid when more classes exist.

const BLURBS := {
	&"shadow": "A hitless echo of you trails a few frames behind, mirroring every strike.",
	&"tank": "Heavy plate. Brace (Q) to shrug off a burst — but you move like a drawbridge.",
	&"ranger": "Bow to the front. Fast and lethal at range, thin on armour.",
}

@onready var cards: HBoxContainer = $Layout/Cards


func _ready() -> void:
	var knight := Classes.knight()
	for i in knight.archetypes.size():
		var arch: Archetype = knight.archetypes[i]
		var card := Button.new()
		card.custom_minimum_size = Vector2(250, 320)
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_theme_font_size_override("font_size", 16)
		card.text = "%d\n\n%s\n\n%s\n\n%s" % [
			i + 1, arch.display_name.to_upper(), BLURBS.get(arch.id, ""), _spread(knight, arch),
		]
		card.pressed.connect(_pick.bind(knight, arch.id))
		cards.add_child(card)
	if cards.get_child_count() > 0:
		cards.get_child(0).grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.is_pressed() and not event.is_echo()):
		return
	var idx: int = { KEY_1: 0, KEY_2: 1, KEY_3: 2 }.get(event.keycode, -1)
	var knight := Classes.knight()
	if idx >= 0 and idx < knight.archetypes.size():
		get_viewport().set_input_as_handled()
		_pick(knight, knight.archetypes[idx].id)


func _pick(knight: PlayerClass, archetype_id: StringName) -> void:
	RunState.start_new_run(knight, archetype_id)
	get_tree().change_scene_to_file("res://scenes/run.tscn")


func _spread(knight: PlayerClass, arch: Archetype) -> String:
	return "Might %d   Finesse %d\nVitality %d   Focus %d" % [
		_attr(knight, arch, &"might"), _attr(knight, arch, &"finesse"),
		_attr(knight, arch, &"vitality"), _attr(knight, arch, &"focus"),
	]


func _attr(knight: PlayerClass, arch: Archetype, key: StringName) -> int:
	var value: float = 10.0
	for m in knight.base_modifiers:
		if m.stat == key:
			value += m.add
	for m in arch.modifiers:
		if m.stat == key:
			value += m.add
	return roundi(value)
