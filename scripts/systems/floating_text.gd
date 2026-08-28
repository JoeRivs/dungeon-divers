extends Node

## Autoload (FloatingText). Spawns a floating number in world space, backed by
## the silhouette of the die it rolled on (sides). Damage defaults to d4.
## TODO: pool these if counts ever climb - fine per-event at small N.

const SCENE: PackedScene = preload("res://scenes/ui/damage_number.tscn")


func spawn(world_pos: Vector2, amount: int, crit: bool = false, hostile: bool = false, sides: int = 4) -> void:
	var number := SCENE.instantiate()
	add_child(number)
	number.global_position = world_pos + Vector2(randf_range(-6.0, 6.0), -16.0)
	number.show_amount(amount, crit, hostile, sides)
