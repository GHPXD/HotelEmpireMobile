class_name RoomDefinition
extends Resource
## Immutable authored content. Live occupancy belongs to the hotel model.

@export var id: StringName
@export var display_name: String
@export var category: StringName
@export var width: int = 2
@export var build_cost: int = 500
@export var maintenance: int = 10
@export var capacity: int = 1
@export var queue_capacity: int = 12
@export var service_duration: float = 8.0
@export var price: int = 20
@export var need: StringName
@export var relief: float = 60.0
@export var color: Color = Color.WHITE
@export var upgrades: Array[UpgradeDefinition] = []
@export var specializations: Array[RoomSpecialization] = []
@export var required_objective: StringName
