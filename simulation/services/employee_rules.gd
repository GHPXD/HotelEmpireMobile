class_name EmployeeRules
extends Resource
## Bounded progression and transparent recruitment trade-offs for two core roles.

@export var thresholds: Array[int] = [0, 60, 180, 360, 600]
@export var receptionist_xp: int = 6
@export var cleaner_xp: int = 10
@export var level_efficiency: float = 0.08
@export var level_salary: float = 0.05
@export var agile_efficiency: float = 1.12
@export var agile_walk: float = 1.15
@export var meticulous_efficiency: float = 0.90
@export var quality_bonus: int = 3
@export var agile_hire: float = 0.20
@export var quality_hire: float = 0.15
@export var agile_salary: float = 0.12
@export var charismatic_salary: float = 0.05
@export var meticulous_salary: float = 0.08

func level_for(xp: int) -> int:
	var result := 1
	for index in range(1, thresholds.size()):
		if xp >= thresholds[index]:
			result = index + 1
	return result

func task_xp(role: StringName) -> int:
	return receptionist_xp if role == &"receptionist" else cleaner_xp

func valid_traits(role: StringName, traits: Array[StringName]) -> bool:
	if role not in [&"receptionist", &"cleaner"] or traits.size() > 2:
		return false
	var allowed: Array[StringName] = [&"agile"]
	allowed.append(&"charismatic" if role == &"receptionist" else &"meticulous")
	var seen: Array[StringName] = []
	for trait_id in traits:
		if trait_id not in allowed or trait_id in seen:
			return false
		seen.append(trait_id)
	return true

func hire_cost(base: int, traits: Array[StringName]) -> int:
	return ceili(snappedf(base * (1.0 + (agile_hire if traits.has(&"agile") else 0.0) + (quality_hire if traits.has(&"charismatic") or traits.has(&"meticulous") else 0.0)), 0.000001))

func salary(base: int, xp: int, traits: Array[StringName]) -> int:
	var multiplier := 1.0 + (level_for(xp) - 1) * level_salary
	multiplier += agile_salary if traits.has(&"agile") else 0.0
	multiplier += charismatic_salary if traits.has(&"charismatic") else 0.0
	multiplier += meticulous_salary if traits.has(&"meticulous") else 0.0
	# Stabilize floating-point percentages before rounding to whole Cash units.
	return ceili(snappedf(base * multiplier, 0.000001))

func efficiency(xp: int, traits: Array[StringName]) -> float:
	return (1.0 + (level_for(xp) - 1) * level_efficiency) * (agile_efficiency if traits.has(&"agile") else 1.0) * (meticulous_efficiency if traits.has(&"meticulous") else 1.0)

func profiles(role: StringName) -> Array[Array]:
	var quality: StringName = &"charismatic" if role == &"receptionist" else &"meticulous"
	return [[], [&"agile"], [quality], [&"agile", quality]]
