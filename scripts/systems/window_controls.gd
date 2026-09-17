extends Node

## Autoload. F11 toggles fullscreen <-> windowed from anywhere - class
## select, mid-run, even while paused on a panel. That's the only piece
## resolution handling actually needed: `window/stretch/mode="canvas_items"`
## + `aspect="expand"` (project.godot) already makes every scene reflow to
## whatever size the window ends up at, so there's no separate "resolution
## system" to build - just a way to ask the OS for a bigger window.


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo() \
			and event.physical_keycode == KEY_F11:
		get_viewport().set_input_as_handled()
		var win := get_window()
		win.mode = Window.MODE_WINDOWED if win.mode == Window.MODE_FULLSCREEN \
			else Window.MODE_FULLSCREEN
