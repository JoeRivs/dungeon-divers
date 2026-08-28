extends Node

## Minimal reuse pool (autoload: ProjectilePool) so firing the bow never
## instantiate()s in the hot path. Arrows live as children of this node
## and move in world space regardless of parent.

const ARROW_SCENE: PackedScene = preload("res://scenes/projectiles/arrow.tscn")

var _free: Array[Arrow] = []
var _all: Array[Arrow] = []


func acquire_arrow() -> Arrow:
	if _free.is_empty():
		var arrow: Arrow = ARROW_SCENE.instantiate() as Arrow
		add_child(arrow)
		_all.append(arrow)
		arrow.despawned.connect(_on_arrow_despawned.bind(arrow))
		return arrow
	return _free.pop_back()


func reset() -> void:
	for arrow in _all:
		arrow.deactivate()


func _on_arrow_despawned(arrow: Arrow) -> void:
	if arrow not in _free:
		_free.append(arrow)
