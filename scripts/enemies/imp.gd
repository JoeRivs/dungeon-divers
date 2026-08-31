extends CharacterBody2D

## Small, fast, twitchy. Weaves toward you, darts in for a quick bite, then
## peels away before you can retaliate. Low HP - the threat is that it's
## hard to hit, not that any one bite hurts.

const SLASH_FX := preload("res://scenes/fx/slash_effect.tscn")

const SPEED: float = 132.0
const WEAVE_AMP: float = 0.9
const WEAVE_HZ: float = 3.2
const BITE_RANGE: float = 46.0
const BITE_WINDUP: float = 0.14
const BITE_DASH: float = 220.0
const BITE_DASH_TIME: float = 0.14
const RETREAT_TIME: float = 0.55
const COOLDOWN: float = 1.0
const ATTACK_DICE := Vector2i(1, 3)

enum { APPROACH, BITE, RETREAT }

@onready var body: Polygon2D = $Body
@onready var health: Health = $Health
@onready var health_bar: Node = $EnemyHealthBar

var _player: Node2D = null
var _state: int = APPROACH
var _timer: float = 0.0
var _cooldown_left: float = 0.0
var _bite_dir: Vector2 = Vector2.RIGHT
var _bit: bool = false
var _phase: float = 0.0
var _damage_mult: float = 1.0


func _ready() -> void:
	add_to_group("enemies")
	health.died.connect(_on_died)
	health_bar.bind(health)
	_phase = randf() * TAU


func apply_threat(hp_mult: float, dmg_mult: float) -> void:
	_damage_mult = dmg_mult
	health.set_max_health(int(round(health.max_health * hp_mult)))


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	_timer -= delta
	_phase += delta

	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			velocity = Vector2.ZERO
			return

	var to_player: Vector2 = _player.global_position - global_position
	var dist: float = to_player.length()
	var dir: Vector2 = to_player / maxf(dist, 0.001)

	match _state:
		APPROACH:
			var weave: Vector2 = dir.orthogonal() * sin(_phase * WEAVE_HZ) * WEAVE_AMP
			velocity = (dir + weave).normalized() * SPEED
			if dist <= BITE_RANGE and _cooldown_left <= 0.0:
				_state = BITE
				_timer = BITE_WINDUP
				_bit = false
				body.modulate = Color(1.0, 0.7, 0.9)
		BITE:
			if _timer > 0.0:
				velocity = Vector2.ZERO
			else:
				if not _bit:
					_bite_dir = dir
					_bit = true
					_slash(dir)
					if dist <= BITE_RANGE + 12.0 and _player.has_method("apply_damage"):
						var raw: int = Dice.roll(ATTACK_DICE.x, ATTACK_DICE.y)
						var rolled: int = maxi(int(round(raw * _damage_mult)), 1)
						var dealt: int = _player.apply_damage(rolled)
						if dealt > 0:
							FloatingText.spawn(_player.global_position, dealt,
									Dice.is_max(raw, ATTACK_DICE.x, ATTACK_DICE.y), true)
					_timer = BITE_DASH_TIME
				velocity = _bite_dir * BITE_DASH
				if _timer <= 0.0:
					_state = RETREAT
					_timer = RETREAT_TIME
					_cooldown_left = COOLDOWN
					body.modulate = Color.WHITE
		RETREAT:
			velocity = -dir * SPEED * 0.9
			if _timer <= 0.0:
				_state = APPROACH

	move_and_slide()


func _slash(dir: Vector2) -> void:
	var fx := SLASH_FX.instantiate()
	get_parent().add_child(fx)
	fx.global_position = global_position + dir * 10.0
	fx.play(dir, 26.0, 16.0, Color(1.0, 0.5, 0.7, 0.8), 1.6)


func apply_damage(amount: int) -> int:
	health.take_damage(amount)
	if health.is_dead:
		return amount
	body.modulate = Color.WHITE
	create_tween().tween_property(body, "modulate", Color(0.9, 0.4, 0.6), 0.1)
	return amount


func _on_died() -> void:
	queue_free()
