class_name RemoteConfigService
extends RefCounted
## Application-only knobs with local defaults, typed bounds and atomic updates.

const SCHEMA: int = 1
const SPEC: Dictionary = {
	"ui_refresh_seconds": {"default": 0.2, "min": 0.1, "max": 1.0, "integer": false, "owner": "presentation"},
	"offline_cap_seconds": {"default": 28800, "min": 3600, "max": 43200, "integer": true, "owner": "offline"},
	"rewarded_offline_multiplier": {"default": 1.5, "min": 1.0, "max": 2.0, "integer": false, "owner": "monetization"},
	"rewarded_timer_reduction_seconds": {"default": 60, "min": 10, "max": 300, "integer": true, "owner": "monetization"},
	"rewarded_cooldown_seconds": {"default": 300, "min": 60, "max": 1800, "integer": true, "owner": "monetization"},
}
var provider: RemoteConfigProvider = RemoteConfigProvider.new()
var values: Dictionary = {}
var revision: int = 0

func _init() -> void:
	for key: String in SPEC:
		values[key] = SPEC[key].default

func refresh() -> bool:
	var response := provider.fetch()
	return false if response.is_empty() else apply(response)

func apply(response: Dictionary) -> bool:
	if response.get("schema") != SCHEMA or not response.get("values") is Dictionary:
		return false
	var received_revision: Variant = response.get("revision")
	if not (received_revision is int or received_revision is float) or not is_finite(float(received_revision)):
		return false
	if float(received_revision) != floor(float(received_revision)) or received_revision <= revision or received_revision > 2147483647:
		return false
	var next := values.duplicate()
	for key: Variant in response.values:
		if not key is String or not SPEC.has(key):
			return false
		var value: Variant = response.values[key]
		var spec: Dictionary = SPEC[key]
		if not (value is int or value is float) or not is_finite(float(value)) or value < spec.min or value > spec.max:
			return false
		if spec.integer and float(value) != floor(float(value)):
			return false
		next[key] = int(value) if spec.integer else float(value)
	values = next
	revision = int(received_revision)
	return true
