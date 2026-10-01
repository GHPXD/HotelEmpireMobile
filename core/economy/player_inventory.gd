class_name PlayerInventory
extends RefCounted
## Account-level consumables. Application is the writer; receipts and spend IDs
## survive hotel changes. Static resources are never used as mutable stock.

const VERSION: int = 1
const MAX_ITEMS: int = 1000000
const DEFINITIONS: Array[SpeedupDefinition] = [preload("res://data/speedups/5m.tres"), preload("res://data/speedups/15m.tres"), preload("res://data/speedups/1h.tres")]
const RULES: SpeedupRules = preload("res://data/speedup_rules.tres")
const SOURCES: Array[String] = ["welcome", "tutorial"]
var revision: int = 0
var _grants: Dictionary = {}
var _spent: Dictionary = {"5m": 0, "15m": 0, "1h": 0}
var _next_spend_id: int = 1

static func definition(id: StringName) -> SpeedupDefinition:
	for item in DEFINITIONS:
		if item.id == id:
			return item
	return null

func quantity(id: StringName) -> int:
	if definition(id) == null:
		return 0
	var total := 0
	for grant: Dictionary in _grants.values():
		total += int(grant.get(String(id), 0))
	return total - int(_spent[String(id)])

func next_operation_id() -> int:
	return _next_spend_id

func claimed(source: StringName) -> bool:
	return _grants.has(String(source))

func claim_reward(source: StringName) -> bool:
	if String(source) not in SOURCES or claimed(source):
		return false
	var reward := RULES.reward(source)
	if not _valid_counts(reward, false):
		return false
	for item in DEFINITIONS:
		if quantity(item.id) + int(reward.get(String(item.id), 0)) > MAX_ITEMS:
			return false
	_grants[String(source)] = reward
	revision += 1
	return true

func spend_error(id: StringName, operation_id: int) -> String:
	if operation_id < _next_spend_id:
		return "speedup.error.duplicate"
	if operation_id != _next_spend_id or definition(id) == null:
		return "speedup.error.invalid"
	return "speedup.error.empty" if quantity(id) <= 0 else ""

func spend(id: StringName, operation_id: int) -> String:
	var error := spend_error(id, operation_id)
	if not error.is_empty():
		return error
	_spent[String(id)] = int(_spent[String(id)]) + 1
	_next_spend_id += 1
	revision += 1
	return ""

func snapshot() -> Dictionary:
	return {"version": VERSION, "grants": _grants.duplicate(true), "spent": _spent.duplicate(), "next_spend_id": _next_spend_id}

func restore(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 4 or not _integer(data.get("version"), VERSION, VERSION) or not data.get("grants") is Dictionary or not _valid_counts(data.get("spent"), true):
		return false
	if not _integer(data.get("next_spend_id"), 1, MAX_ITEMS * DEFINITIONS.size() + 1) or data.grants.size() > SOURCES.size():
		return false
	var earned := {"5m": 0, "15m": 0, "1h": 0}
	for source: Variant in data.grants:
		if not source is String or source not in SOURCES or not _valid_counts(data.grants[source], false):
			return false
		for item in DEFINITIONS:
			earned[String(item.id)] += int(data.grants[source].get(String(item.id), 0))
	var used := 0
	for item in DEFINITIONS:
		var key := String(item.id)
		if int(earned[key]) > MAX_ITEMS or int(data.spent[key]) > int(earned[key]):
			return false
		used += int(data.spent[key])
	if used + 1 != int(data.next_spend_id):
		return false
	var grants: Dictionary = {}
	for source: String in data.grants:
		var counts: Dictionary = {}
		for key: String in data.grants[source]:
			counts[key] = int(data.grants[source][key])
		grants[source] = counts
	var spent: Dictionary = {}
	for item in DEFINITIONS:
		spent[String(item.id)] = int(data.spent[String(item.id)])
	_grants = grants
	_spent = spent
	_next_spend_id = int(data.next_spend_id)
	revision += 1
	return true

static func valid(data: Variant) -> bool:
	return PlayerInventory.new().restore(data)

static func _valid_counts(data: Variant, complete: bool) -> bool:
	if not data is Dictionary or data.size() > DEFINITIONS.size() or (complete and data.size() != DEFINITIONS.size()) or (not complete and data.is_empty()):
		return false
	for key: Variant in data:
		if not key is String or definition(StringName(key)) == null or not _integer(data[key], 0 if complete else 1, MAX_ITEMS):
			return false
	return true

static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)) and value >= minimum and value <= maximum
