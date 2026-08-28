extends Node2D

## Room root: ensures a run exists, resets the projectile pool for the fresh
## scene, and wires the HUD to the player's health.
##
## Debug: number keys 1 / 2 / 3 switch the Knight archetype (shadow / tank /
## ranger) and reload the room. Placeholder until a class-select screen.

const DEBUG_ARCHETYPES := {
	KEY_1: &"shadow",
	KEY_2: &"tank",
	KEY_3: &"ranger",
}

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
	RunState.ensure_run()
	ProjectilePool.reset()
	hud.bind(player.health)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if DEBUG_ARCHETYPES.has(event.keycode):
			RunState.set_archetype(DEBUG_ARCHETYPES[event.keycode])
			get_tree().reload_current_scene()
