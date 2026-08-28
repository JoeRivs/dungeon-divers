extends Node2D

## Keeps a small number of grunts alive, spawned on a ring around this
## node. Small-N by design - raise max_enemies later for tougher rooms.

const GRUNT_SCENE: PackedScene = preload("res://scenes/enemies/grunt.tscn")

@export var max_enemies: int = 3
@export var spawn_interval: float = 2.5
@export var spawn_radius: float = 240.0

var _time_left: float = 0.0


func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left > 0.0:
		return
	_time_left = spawn_interval

	if get_tree().get_nodes_in_group("enemies").size() >= max_enemies:
		return
	_spawn()


func _spawn() -> void:
	var grunt := GRUNT_SCENE.instantiate()
	add_child(grunt)
	var angle: float = randf() * TAU
	grunt.global_position = global_position + Vector2.RIGHT.rotated(angle) * spawn_radius
