class_name AnalyticsService
extends RefCounted
## Bounded, non-blocking lifecycle telemetry. No PII or receipts accepted.

const MAX_PENDING: int = 128
const EVENTS: Array[StringName] = [&"app_open", &"session_start", &"session_end", &"background", &"resume", &"manual_work", &"tutorial_progress"]
const PROPERTIES: Array[String] = ["load_status", "hotel_index", "device_tier", "duration_seconds", "kind", "phase", "result", "stage"]
var provider: AnalyticsProvider = AnalyticsProvider.new()
var pending: Array[Dictionary] = []
var next_id: int = 1

func record(name: StringName, properties: Dictionary = {}) -> bool:
	if name not in EVENTS:
		return false
	for key: Variant in properties:
		var value: Variant = properties[key]
		if not key is String or key not in PROPERTIES or not (value is String or value is int or value is float or value is bool):
			return false
		if value is String and value.length() > 64:
			return false
		if value is float and not is_finite(value):
			return false
	var event := {"schema": 1, "id": next_id, "name": String(name), "properties": properties.duplicate()}
	next_id += 1
	if pending.size() >= MAX_PENDING:
		pending.pop_front()
	pending.append(event)
	return true

func flush(limit: int = 16) -> void:
	for index in mini(maxi(0, limit), pending.size()):
		if not provider.send(pending[0]):
			return
		pending.pop_front()
