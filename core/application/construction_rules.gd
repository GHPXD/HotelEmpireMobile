class_name ConstructionRules
extends Resource
## Real-time construction choices. No premium currency or platform dependency.

@export var slots: int = 2
@export var queue_limit: int = 12
@export var onboarding_seconds: Dictionary[StringName, int] = {&"reception": 10, &"bedroom": 20, &"restaurant": 30, &"elevator": 60}
@export var early_seconds: int = 120
@export var mid_seconds: int = 600
@export var late_seconds: int = 1800
@export var mid_room_count: int = 8
@export var late_room_count: int = 24
@export var upgrade_seconds: Array[int] = [60, 180, 600, 1200]
@export var floor_seconds: int = 60
@export var floor_step_seconds: int = 15
@export var maximum_seconds: int = 14400

func build_ms(definition: RoomDefinition, rooms: Array[RoomState], jobs: Array[Dictionary]) -> int:
	var matching := false
	var count := rooms.size()
	for room in rooms:
		matching = matching or room.definition_id == definition.id
	for job in jobs:
		if job.kind == "build":
			count += 1
			matching = matching or job.definition_id == String(definition.id)
	if not matching and onboarding_seconds.has(definition.id):
		return onboarding_seconds[definition.id] * 1000
	return (early_seconds if count < mid_room_count else (mid_seconds if count < late_room_count else late_seconds)) * 1000

func upgrade_ms(target_level: int) -> int:
	return upgrade_seconds[clampi(target_level - 2, 0, upgrade_seconds.size() - 1)] * 1000

func floor_ms(target_floor: int) -> int:
	return mini(maximum_seconds, floor_seconds + target_floor * floor_step_seconds) * 1000
