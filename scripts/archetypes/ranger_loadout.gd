extends Node2D

## Knight "Ranger" archetype hook. Fights at range: the bow becomes the
## primary attack (LMB), the blade drops to secondary (RMB). The speed /
## fragility trade lives in the archetype's stat modifiers.

@onready var _player: Node = get_parent()


func _ready() -> void:
	if _player.has_method("set_weapons"):
		_player.set_weapons(_player.bow, _player.sword)
