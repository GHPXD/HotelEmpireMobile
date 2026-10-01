class_name EmployeeProgress
extends RefCounted
## Per-employee state. Definitions and shared balancing resources stay immutable.

const RULES: EmployeeRules = preload("res://data/employee_rules.tres")
var xp: int = 0
var completed_tasks: int = 0
var traits: Array[StringName] = []
var duty_enabled: bool = true
var priority: StringName = &"oldest"
var dismiss_requested: bool = false

func level() -> int:
	return RULES.level_for(xp)

func efficiency(base: float = 1.0) -> float:
	return RULES.efficiency(xp, traits) * base

func walking(base: float) -> float:
	return base * (RULES.agile_walk if traits.has(&"agile") else 1.0)

func quality() -> int:
	return level() - 1 + (RULES.quality_bonus if traits.has(&"charismatic") or traits.has(&"meticulous") else 0)

func salary(base: int) -> int:
	return RULES.salary(base, xp, traits)

func award(role: StringName) -> bool:
	var previous := level()
	completed_tasks += 1
	xp = mini(RULES.thresholds[-1], xp + RULES.task_xp(role))
	return level() > previous

func snapshot() -> Dictionary:
	var names: Array[String] = []
	for trait_id in traits:
		names.append(String(trait_id))
	return {"xp": xp, "completed_tasks": completed_tasks, "traits": names, "duty_enabled": duty_enabled, "priority": String(priority), "dismiss_requested": dismiss_requested}

static func restore(data: Variant, role: StringName) -> EmployeeProgress:
	if not data is Dictionary or data.size() != 6:
		return null
	if not _integer(data.get("xp"), 0, RULES.thresholds[-1]) or not _integer(data.get("completed_tasks"), 0, 100000000):
		return null
	if not data.get("duty_enabled") is bool or not data.get("dismiss_requested") is bool or not data.get("priority") is String:
		return null
	if data.priority not in ["oldest", "nearest"] or (role == &"receptionist" and data.priority != "oldest"):
		return null
	if not data.get("traits") is Array:
		return null
	var result := EmployeeProgress.new()
	for value: Variant in data.traits:
		if not value is String:
			return null
		result.traits.append(StringName(value))
	if not RULES.valid_traits(role, result.traits):
		return null
	result.xp = int(data.xp)
	result.completed_tasks = int(data.completed_tasks)
	if result.xp != mini(RULES.thresholds[-1], result.completed_tasks * RULES.task_xp(role)):
		return null
	result.duty_enabled = data.duty_enabled
	result.priority = StringName(data.priority)
	result.dismiss_requested = data.dismiss_requested
	if result.dismiss_requested and result.duty_enabled:
		return null
	return result

static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)) and value >= minimum and value <= maximum
