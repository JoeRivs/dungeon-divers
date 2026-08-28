class_name Health
extends Node

## Reusable hit-point pool. Attach as a child node; other systems call
## take_damage() / heal() and react to the signals instead of poking at
## the numbers directly.

signal health_changed(current: int, maximum: int)
signal died

@export var max_health: int = 100

var current_health: int
var is_dead: bool = false


func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


func take_damage(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	current_health = maxi(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		is_dead = true
		died.emit()


func heal(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	current_health = mini(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
