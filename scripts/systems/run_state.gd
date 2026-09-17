extends Node

## Autoload (RunState). Everything that must survive a room change lives
## here: the chosen class + archetype, gold, carried HP, and where you are
## in the run. Rooms come and go; this does not.

signal run_started

## Fires once per level gained (can fire more than once for a big XP dump -
## the run shell queues and shows one pick per level, back to back).
signal leveled_up(new_level: int)

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

## forge rewires taken this run, + per-floor Forge-room scheduling
var forges: Array[ForgeUpgrade] = []
var forge_offered_this_floor: bool = false
var forge_room_target: int = 4        ## offer the Forge door after this many rooms

## kill XP -> level -> Etching picks. Etchings are small MECHANIC mods (never
## flat stat boosts) layered onto a weapon/ability, some gated behind a Forge
## you're already holding or an earlier Etching on the same ability - the
## synergy layer between the boon trickle and the rare Forge rewire.
var xp: int = 0
var level: int = 1
var xp_next: int = 60
var etchings: Array[Etching] = []


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
	forges = []
	forge_offered_this_floor = false
	forge_room_target = randi_range(3, 7)
	xp = 0
	level = 1
	xp_next = _xp_for_level(1)
	etchings = []
	run_started.emit()


## Called by a room on load so standalone testing works with no run set up.
func ensure_run() -> void:
	if player_class == null:
		start_new_run(Classes.knight(), &"shadow")


func set_health(hp: int) -> void:
	current_health = hp


func set_archetype(aid: StringName) -> void:
	archetype_id = aid


## Called by an enemy's death handler. Can trigger more than one level on a
## single big kill (e.g. a boss) - leveled_up fires once per level crossed.
func gain_xp(amount: int) -> void:
	if amount <= 0:
		return
	xp += amount
	while xp >= xp_next:
		xp -= xp_next
		level += 1
		xp_next = _xp_for_level(level)
		leveled_up.emit(level)


func _xp_for_level(lv: int) -> int:
	return int(round(50.0 + float(lv) * 26.0))
