extends CanvasLayer

## Screen-space player HUD. bind() wires it to the player's Health.

@onready var health_bar: ProgressBar = $HealthBar
@onready var label: Label = $HealthBar/Label


func bind(health: Health) -> void:
	health.health_changed.connect(_on_health_changed)
	_on_health_changed(health.current_health, health.max_health)


func _on_health_changed(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	label.text = "%d / %d" % [current, maximum]
