extends Node

## Autoload (FloatingText). Spawns a floating damage number in world space.
## TODO: pool these if hit counts ever climb - fine per-hit at small N.

const SCENE: PackedScene = preload("res://scenes/ui/damage_number.tscn")


func spawn(world_pos: Vector2, amount: int, crit: bool = false, hostile: bool = false) -> void:
	var number := SCENE.instantiate()
	add_child(number)
	number.global_position = world_pos + Vector2(randf_range(-6.0, 6.0), -16.0)
	number.show_amount(amount, crit, hostile)
