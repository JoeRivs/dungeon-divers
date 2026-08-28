extends CanvasLayer

## Hades-style "pick 1 of 3" overlay. present() shows the cards and awaits a
## choice (mouse click or keys 1/2/3), returns the chosen Upgrade. Runs while
## the tree is paused (process_mode = Always on the scene root).

signal _picked(upgrade: Upgrade)

@onready var cards: HBoxContainer = $Cards

var _choices: Array = []


func _ready() -> void:
	visible = false


func present(choices: Array) -> Upgrade:
	_choices = choices
	for child in cards.get_children():
		child.queue_free()

	for i in choices.size():
		var u: Upgrade = choices[i]
		var button := Button.new()
		button.custom_minimum_size = Vector2(240, 220)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 18)
		button.text = "%d\n\n%s\n\n%s\n\n— Tier %d —" % [i + 1, u.display_name, u.description, u.tier]
		button.pressed.connect(_choose.bind(u))
		cards.add_child(button)

	visible = true
	if cards.get_child_count() > 0:
		cards.get_child(0).grab_focus()

	var chosen: Upgrade = await _picked
	visible = false
	return chosen


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var idx: int = -1
		match event.keycode:
			KEY_1: idx = 0
			KEY_2: idx = 1
			KEY_3: idx = 2
		if idx >= 0 and idx < _choices.size():
			get_viewport().set_input_as_handled()
			_choose(_choices[idx])


func _choose(upgrade: Upgrade) -> void:
	_picked.emit(upgrade)
