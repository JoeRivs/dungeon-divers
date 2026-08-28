class_name Health
extends Node

## Reusable hit-point pool. Left alone it uses its exported max_health
## (enemies). bind_stats() hands max_health control to a Stats component so
## class / archetype / upgrade modifiers drive it (the player).

signal health_changed(current: int, maximum: int)
signal died

@export var max_health: int = 100

var current_health: int
var is_dead: bool = false

var _stats: Stats = null


func _ready() -> void:
	if _stats == null:
		current_health = max_health
		health_changed.emit(current_health, max_health)


func bind_stats(stats: Stats) -> void:
	_stats = stats
	stats.changed.connect(_on_stats_changed)
	_apply_max(int(round(stats.get_stat(&"max_health"))), true)


func _on_stats_changed() -> void:
	_apply_max(int(round(_stats.get_stat(&"max_health"))), false)


func _apply_max(new_max: int, fill: bool) -> void:
	var delta: int = new_max - max_health
	max_health = maxi(new_max, 1)
	if fill:
		current_health = max_health
	else:
		if delta > 0:
			current_health += delta          # keep newly granted HP
		current_health = clampi(current_health, 0, max_health)
	health_changed.emit(current_health, max_health)


func set_current(hp: int) -> void:
	current_health = clampi(hp, 0, max_health)
	health_changed.emit(current_health, max_health)


## For enemies scaled by room difficulty: reset max and refill.
func set_max_health(value: int) -> void:
	max_health = maxi(value, 1)
	current_health = max_health
	is_dead = false
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
