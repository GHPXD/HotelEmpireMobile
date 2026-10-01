class_name SpeedupRules
extends Resource
## Small authored grants; later mission/event sources extend the global economy.

@export var welcome: Dictionary = {"5m": 1}
@export var tutorial: Dictionary = {"15m": 1}

func reward(source: StringName) -> Dictionary:
	match source:
		&"welcome": return welcome.duplicate()
		&"tutorial": return tutorial.duplicate()
	return {}
