extends Node2D

## Knight "Shadow" archetype hook. A dark silhouette of the player that
## hangs just behind you (never on top of you) and echoes every attack you
## make with a shadow slash. No collision layer - nothing can touch it.

const REST_DISTANCE: float = 34.0      ## where it wants to sit, behind your travel
const MIN_DISTANCE: float = 24.0       ## never closer than this to the player
const MAX_DISTANCE: float = 90.0       ## snap back if it lags too far
const FOLLOW_LERP: float = 0.14
const ECHO_DELAY: float = 0.13         ## how long after your swing the echo lands
const SLASH_RANGE: float = 44.0
const SLASH_DICE := Vector2i(1, 4)
const CLONE_DAMAGE_FACTOR: float = 0.6 ## echo hits for a fraction of your roll
const SHADOW_TINT := Color(0.08, 0.03, 0.16, 0.62)

@onready var ghost: Node2D = $Ghost
@onready var sprite: Sprite2D = $Ghost/Sprite

var _player: Node
var _anchor_dir: Vector2 = Vector2.DOWN


func _ready() -> void:
	_player = get_parent()

	var pbody: Sprite2D = _player.get_node("Body")
	sprite.texture = pbody.texture
	sprite.offset = pbody.offset
	sprite.scale = pbody.scale
	sprite.modulate = SHADOW_TINT

	ghost.global_position = _player.global_position + _anchor_dir * REST_DISTANCE
	_player.connect("attacked", _on_player_attacked)


func _physics_process(_delta: float) -> void:
	if _player.velocity.length() > 12.0:
		_anchor_dir = (-_player.velocity).normalized()

	var desired: Vector2 = _player.global_position + _anchor_dir * REST_DISTANCE
	ghost.global_position = ghost.global_position.lerp(desired, FOLLOW_LERP)

	# keep it in the "near me but not on me" band
	var to_clone: Vector2 = ghost.global_position - _player.global_position
	var dist: float = to_clone.length()
	if dist < MIN_DISTANCE:
		var dir: Vector2 = to_clone.normalized() if dist > 0.001 else _anchor_dir
		ghost.global_position = _player.global_position + dir * MIN_DISTANCE
	elif dist > MAX_DISTANCE:
		ghost.global_position = _player.global_position + to_clone.normalized() * MAX_DISTANCE


func _on_player_attacked(_kind: StringName, direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return
	_echo_slash(direction)


func _echo_slash(direction: Vector2) -> void:
	await get_tree().create_timer(ECHO_DELAY).timeout
	if not is_instance_valid(self) or not is_instance_valid(ghost):
		return

	var arc := Polygon2D.new()
	arc.color = Color(0.55, 0.25, 0.85, 0.55)
	arc.polygon = PackedVector2Array([Vector2(6, -5), Vector2(36, 0), Vector2(6, 5)])
	arc.rotation = direction.angle()
	ghost.add_child(arc)
	var tween := create_tween()
	tween.tween_property(arc, "modulate:a", 0.0, 0.18)
	tween.tween_callback(arc.queue_free)

	var dmg: Dictionary = _player.compute_damage(SLASH_DICE)
	var amount: int = maxi(int(round(dmg.amount * CLONE_DAMAGE_FACTOR)), 1)
	var origin: Vector2 = ghost.global_position
	var facing: Vector2 = direction.normalized()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy.has_method("apply_damage"):
			continue
		var offset: Vector2 = enemy.global_position - origin
		if offset.length() <= SLASH_RANGE and offset.normalized().dot(facing) > 0.25:
			var dealt: int = enemy.apply_damage(amount)
			if dealt > 0:
				FloatingText.spawn(enemy.global_position, dealt, dmg.crit)
