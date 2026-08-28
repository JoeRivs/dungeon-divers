extends Node2D

## Little bar that floats above an enemy's head. bind() is called by the
## enemy with its Health component.

@onready var fill: Polygon2D = $Fill


func bind(health: Health) -> void:
	health.health_changed.connect(_on_health_changed)
	_on_health_changed(health.current_health, health.max_health)


func _on_health_changed(current: int, maximum: int) -> void:
	var ratio: float = 0.0 if maximum <= 0 else float(current) / float(maximum)
	fill.scale.x = clampf(ratio, 0.0, 1.0)
