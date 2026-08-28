extends Node2D

## The run shell. Persists the player, camera and HUD; swaps rooms in and out
## of RoomHost. Drives the Hades-style loop: clear a room -> reward -> pick a
## door -> next room; N combat rooms then a boss; clear the last floor's boss
## to win. Death or victory returns to the class-select screen.

const COMBAT_ROOM := preload("res://scenes/rooms/combat_room.tscn")
const BOSS_ROOM := preload("res://scenes/rooms/boss_room.tscn")
const CLASS_SELECT := "res://scenes/ui/class_select.tscn"

const ROOMS_PER_FLOOR: int = 10
const MAX_FLOORS: int = 2
const FADE_TIME: float = 0.22

## door dice, weighted: d20 / d12 common, d8 uncommon, d4 rare - so the
## harder (tier 3/4) rooms are the exception, not the norm
const DOOR_DICE: Array[int] = [20, 12, 8, 4]
const DOOR_DICE_WEIGHT: Array[float] = [16.0, 7.0, 1.8, 0.45]

@onready var room_host: Node2D = $RoomHost
@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var fade: ColorRect = $Fade/Rect
@onready var upgrade_picker: CanvasLayer = $UpgradePicker
@onready var character_panel: CanvasLayer = $CharacterPanel

var _room: Node = null
var _over: bool = false


func _ready() -> void:
	RunState.ensure_run()
	hud.bind(player.health)
	character_panel.bind(player)
	player.health.died.connect(_on_player_died)

	fade.color.a = 1.0
	# opening room is a gentle freebie
	var opener := RoomOption.from_die(12)
	RunState.current_room_difficulty = opener.roll()
	RunState.current_room_tier = opener.tier()
	_load_room(COMBAT_ROOM)
	_fade(0.0)


func _load_room(scene: PackedScene) -> void:
	if _room != null and is_instance_valid(_room):
		_room.queue_free()

	_room = scene.instantiate()
	room_host.add_child(_room)
	_room.cleared.connect(_on_room_cleared)
	_room.setup(RunState.current_room_difficulty, RunState.floor_index)

	player.global_position = _room.get_entry_point()
	player.velocity = Vector2.ZERO
	ProjectilePool.reset()

	if _room.has_method("get_boss") and _room.get_boss() != null:
		hud.bind_boss(_room.get_boss())
	hud.refresh_run()


func _on_room_cleared() -> void:
	if _over:
		return
	hud.hide_boss()
	# a chest appears; the pick waits until the player walks into it, so a
	# mid-fight click can't grab a boon by accident.
	_room.reward_claimed.connect(_on_reward_claimed, CONNECT_ONE_SHOT)
	_room.spawn_reward(RunState.current_room_tier)


func _on_reward_claimed() -> void:
	await _offer_upgrade()
	_open_doors()


## Pause, show 3 options at this room's tier, apply the pick.
func _offer_upgrade() -> void:
	var choices: Array[Upgrade] = Upgrades.draw(RunState.current_room_tier, 3)
	if choices.is_empty():
		return

	get_tree().paused = true
	var picked: Upgrade = await upgrade_picker.present(choices)
	get_tree().paused = false

	if picked != null:
		_apply_upgrade(picked)


func _apply_upgrade(u: Upgrade) -> void:
	player.stats.add_modifiers(u.modifiers, &"upgrade")
	# special tags carry their amount, e.g. "gold15" / "heal12"
	var tag := String(u.special)
	if tag.begins_with("gold"):
		RunState.gold += tag.substr(4).to_int()
	elif tag.begins_with("heal"):
		player.health.heal(tag.substr(4).to_int())
	RunState.upgrades.append(u)
	hud.refresh_run()


func _open_doors() -> void:
	if _room.has_method("get_boss"):
		RunState.floor_index += 1
		RunState.rooms_cleared_this_floor = 0
		if RunState.floor_index > MAX_FLOORS:
			_end_run("VICTORY")
			return
		_room.reveal_doors(_door_choices())
		_arm_doors()
		return

	RunState.rooms_cleared_this_floor += 1
	var options: Array
	if RunState.rooms_cleared_this_floor >= ROOMS_PER_FLOOR:
		options = [RoomOption.boss()]
	else:
		options = _door_choices()
	_room.reveal_doors(options)
	_arm_doors()


## 2-3 doors, each die rolled independently against the weights (duplicates
## allowed), so most stretches are all d20/d12 and a d8 - let alone a d4 -
## is a genuine event.
func _door_choices() -> Array:
	var count: int = 3 if randf() < 0.35 else 2
	var out: Array = []
	for i in count:
		out.append(RoomOption.from_die(_weighted_die()))
	return out


func _weighted_die() -> int:
	var total: float = 0.0
	for w in DOOR_DICE_WEIGHT:
		total += w
	var roll: float = randf() * total
	for i in DOOR_DICE_WEIGHT.size():
		roll -= DOOR_DICE_WEIGHT[i]
		if roll <= 0.0:
			return DOOR_DICE[i]
	return DOOR_DICE[0]


func _arm_doors() -> void:
	for door in _room.get_doors():
		door.chosen.connect(_on_door_chosen, CONNECT_ONE_SHOT)


func _on_door_chosen(option: RoomOption) -> void:
	# the roll happens now, on commit - not before
	var rolled: int = option.roll()
	hud.show_roll(rolled, option.die_sides)

	RunState.current_room_difficulty = rolled
	RunState.current_room_tier = option.tier()
	RunState.room_index += 1

	await _fade(1.0)
	await get_tree().create_timer(1.1).timeout  # hold on the roll over black
	_load_room(BOSS_ROOM if option.is_boss else COMBAT_ROOM)
	await _fade(0.0)


func _end_run(banner: String) -> void:
	_over = true
	hud.show_banner(banner)
	await get_tree().create_timer(2.5).timeout
	get_tree().paused = false
	get_tree().change_scene_to_file(CLASS_SELECT)


func _on_player_died() -> void:
	if not _over:
		_end_run("YOU DIED")


func _fade(target_alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade, "color:a", target_alpha, FADE_TIME)
	await tween.finished
