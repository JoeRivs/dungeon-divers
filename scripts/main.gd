extends Node2D

## Room root: resets the projectile pool for the fresh scene and wires the
## HUD to the player's health.

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
	ProjectilePool.reset()
	hud.bind(player.health)
