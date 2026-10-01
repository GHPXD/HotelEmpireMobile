class_name ProgressClock
extends RefCounted
## Application clock for persisted jobs. Active time is monotonic; only boot and
## resume consume wall-clock absence. Domain receives times, never OS APIs.

const VERSION: int = 1
const MAX_TIMESTAMP_SECONDS: int = 253402300799
const MAX_TIMESTAMP_MS: int = MAX_TIMESTAMP_SECONDS * 1000
const MAX_ABSENCE_MS: int = 7 * 24 * 60 * 60 * 1000
var wall_source: Callable = func() -> int: return int(Time.get_unix_time_from_system() * 1000.0)
var monotonic_source: Callable = func() -> int: return Time.get_ticks_msec()
var initialized: bool = false
var suspended: bool = false
var _time_ms: int = 0
var _wall_watermark_ms: int = 0
var _last_ticks_ms: int = 0

func begin(data: Dictionary = {}, legacy_saved_utc: int = -1) -> Dictionary:
	var wall := _wall()
	if wall < 0 or (not data.is_empty() and not valid(data)):
		return {"error": "save.error.invalid"}
	var previous := wall
	var watermark := wall
	if not data.is_empty():
		previous = int(data.time_ms)
		watermark = int(data.wall_watermark_ms)
	elif legacy_saved_utc >= 0:
		if legacy_saved_utc > MAX_TIMESTAMP_SECONDS:
			return {"error": "save.error.invalid"}
		previous = legacy_saved_utc * 1000
		watermark = previous
	var absence := maxi(0, wall - watermark)
	var elapsed := mini(absence, MAX_ABSENCE_MS)
	_time_ms = mini(MAX_TIMESTAMP_MS, previous + elapsed)
	_wall_watermark_ms = maxi(watermark, wall)
	_last_ticks_ms = monotonic_source.call()
	initialized = true
	suspended = false
	return {"error": "", "elapsed_ms": elapsed, "rollback": wall < watermark, "capped": absence > elapsed}

func now_ms() -> int:
	if not initialized or suspended:
		return _time_ms
	var ticks: int = monotonic_source.call()
	_time_ms = mini(MAX_TIMESTAMP_MS, _time_ms + maxi(0, ticks - _last_ticks_ms))
	_last_ticks_ms = maxi(ticks, _last_ticks_ms)
	return _time_ms

func suspend() -> void:
	if not initialized or suspended:
		return
	now_ms()
	_observe_wall()
	suspended = true

func resume() -> Dictionary:
	if not initialized:
		return {"error": "save.error.invalid"}
	if not suspended:
		return {"error": "", "elapsed_ms": 0, "rollback": false, "capped": false}
	var wall := _wall()
	if wall < 0:
		return {"error": "save.error.invalid"}
	var absence := maxi(0, wall - _wall_watermark_ms)
	var elapsed := mini(absence, MAX_ABSENCE_MS)
	var rollback := wall < _wall_watermark_ms
	_time_ms = mini(MAX_TIMESTAMP_MS, _time_ms + elapsed)
	_wall_watermark_ms = maxi(_wall_watermark_ms, wall)
	_last_ticks_ms = monotonic_source.call()
	suspended = false
	return {"error": "", "elapsed_ms": elapsed, "rollback": rollback, "capped": absence > elapsed}

func snapshot() -> Dictionary:
	now_ms()
	if not suspended:
		_observe_wall()
	return {"version": VERSION, "time_ms": _time_ms, "wall_watermark_ms": _wall_watermark_ms}

func _observe_wall() -> void:
	var wall := _wall()
	if wall >= 0:
		_wall_watermark_ms = maxi(_wall_watermark_ms, wall)

func _wall() -> int:
	var value: Variant = wall_source.call()
	return int(value) if _milliseconds(value) else -1

static func valid(data: Variant) -> bool:
	return data is Dictionary and data.size() == 3 and _milliseconds(data.get("version")) and data.version == VERSION and _milliseconds(data.get("time_ms")) and _milliseconds(data.get("wall_watermark_ms"))

static func _milliseconds(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)) and value >= 0 and value <= MAX_TIMESTAMP_MS
