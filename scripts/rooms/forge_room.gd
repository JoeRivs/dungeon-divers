extends Node2D

## A no-combat room. Drop in, walk to the anvil, pick 1 of 3 forge rewires,
## then the exits open. Mirrors the room interface the run shell expects
## (setup / get_entry_point / get_doors / reveal_doors) minus the fighting.

signal cleared          ## unused here - the run shell drives us via forge_requested
signal reward_claimed   ## interface parity
signal forge_requested

const ANVIL := preload("res://scenes/props/forge_anvil.tscn")
const DOOR := preload("res://scenes/props/door.tscn")

@onready var arena: Node2D = $Arena

var _doors: Array = []


func is_forge_room() -> bool:
	return true


func get_entry_point() -> Vector2:
	return Vector2(0.0, arena.half_height - 48.0)


func get_doors() -> Array:
	return _doors


func setup(_difficulty: int, _floor_index: int) -> void:
	arena.build(420.0, 300.0, [])
	var anvil := ANVIL.instantiate()
	add_child(anvil)
	anvil.global_position = Vector2(0.0, -40.0)
	anvil.used.connect(func() -> void: forge_requested.emit())


func reveal_doors(options: Array) -> void:
	var y: float = -arena.half_height + 4.0
	var slots: Array = [Vector2(-230.0, y), Vector2(0.0, y), Vector2(230.0, y)]
	for idx in mini(options.size(), slots.size()):
		var door := DOOR.instantiate()
		add_child(door)
		door.global_position = slots[idx]
		door.setup(options[idx])
		door.unlock()
		_doors.append(door)
