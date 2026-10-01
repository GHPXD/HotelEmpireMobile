class_name RoomState
extends RefCounted

var id: int
var definition_id: StringName
var column: int
var floor_index: int
var occupant: int = -1
var dirty: bool = false
## -1 denotes unknown legacy dirty history; oldest scheduling handles it first.
var dirty_since: float = -1.0
var cleaning_quality_bonus: int = 0
var cleaning_by: int = -1
var repairing_by: int = -1
var condition: int = 100
var users: Array[int] = []
var queue := ServiceQueue.new()
var income: int = 0
var level: int = 1
var price_percent: int = 100

func upgrade() -> UpgradeDefinition:
	return null if level == 1 else definition().upgrades[level - 2]

func next_upgrade() -> UpgradeDefinition:
	return null if level > definition().upgrades.size() else definition().upgrades[level - 1]

func capacity() -> int:
	return definition().capacity + (upgrade().capacity_bonus if upgrade() != null else 0)

func price() -> int:
	return scaled_price(definition().price + (upgrade().price_bonus if upgrade() != null else 0))

func scaled_price(base: int) -> int:
	return maxi(1, roundi(base * price_percent / 100.0)) if base > 0 else 0

func lodging_value_delta(profile: GuestArchetype, percent: int = -1) -> float:
	if definition().category != &"lodging":
		return 0.0
	return (100 - (price_percent if percent < 0 else percent)) * profile.lodging_value_weight

func maintenance() -> int:
	return definition().maintenance + (upgrade().maintenance_bonus if upgrade() != null else 0)

func duration() -> float:
	var work_rules: PlayerWorkRules = preload("res://data/player_work.tres")
	return definition().service_duration * (upgrade().duration_multiplier if upgrade() != null else 1.0) * (1.0 + (100 - condition) / 100.0 * work_rules.maximum_slowdown)

func wear(amount: int) -> void:
	condition = clampi(condition - amount, 0, 100)

func speed_multiplier() -> float:
	return upgrade().speed_multiplier if upgrade() != null else 1.0

func satisfaction_bonus() -> float:
	return upgrade().satisfaction_bonus if upgrade() != null else 0.0

func definition() -> RoomDefinition:
	return HotelCatalog.room(definition_id)

func center() -> float:
	return float(column) + float(definition().width) / 2.0

func busy() -> bool:
	return occupant >= 0 or cleaning_by >= 0 or repairing_by >= 0 or not users.is_empty() or not queue.members.is_empty()
