extends Node

## Autoload (RunState). Everything that must survive a room change lives
## here: the chosen class + archetype, gold, carried HP, and where you are
## in the run. Rooms come and go; this does not.

signal run_started

var player_class: PlayerClass = null
var archetype_id: StringName = &""
var gold: int = 0
var current_health: int = -1          ## -1 = "unset, spawn at full"
var floor_index: int = 1
var room_index: int = 1
var rooms_cleared_this_floor: int = 0
var current_room_difficulty: int = 14
var current_room_tier: int = 1
var upgrades: Array[Upgrade] = []


func start_new_run(pc: PlayerClass, aid: StringName = &"") -> void:
	player_class = pc
	archetype_id = aid if aid != &"" else pc.default_archetype
	gold = 0
	current_health = -1
	floor_index = 1
	room_index = 1
	rooms_cleared_this_floor = 0
	current_room_difficulty = 14
	current_room_tier = 1
	upgrades = []
	run_started.emit()


## Called by a room on load so standalone testing works with no run set up.
func ensure_run() -> void:
	if player_class == null:
		start_new_run(Classes.knight(), &"shadow")


func set_health(hp: int) -> void:
	current_health = hp


func set_archetype(aid: StringName) -> void:
	archetype_id = aid
