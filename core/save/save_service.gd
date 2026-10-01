class_name SaveService
extends RefCounted
## Application owns persistence. Domain snapshot/migrations remain authoritative.

signal checkpoint_completed(reason: StringName)
signal checkpoint_failed(error_key: String)

const VERSION: int = 1
const DEFAULT_PATH: String = "user://mobile-profile.json"
const AUTOSAVE_SECONDS: float = 30.0
var path: String = DEFAULT_PATH
var legacy_path: String = SaveStore.DEFAULT_PATH
var clock: Callable = func() -> int: return int(Time.get_unix_time_from_system())
var last_saved_utc: int = 0
var app_state: Dictionary = {}
var write_blocked: bool = false
var last_error: String = ""
var autosave_elapsed: float = 0.0
## Injectable only at the persistence boundary, e.g. deterministic storage faults.
var writer: Callable = AtomicJSONStore.write

func boot() -> Dictionary:
	write_blocked = false
	last_error = ""
	autosave_elapsed = 0.0
	var has_mobile := FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak")
	if has_mobile:
		for candidate in [path, path + ".bak"]:
			var loaded := AtomicJSONStore.read(candidate)
			if loaded.error.is_empty():
				var restored := restore(loaded.data)
				# Do not downgrade a save from a newer application.
				if restored.error == "save.error.version":
					return _failed(restored.error)
				if restored.error.is_empty():
					last_saved_utc = restored.saved_at_utc
					app_state = restored.app_state
					return {"session": restored.session, "error": "", "status": "loaded" if candidate == path else "recovered", "saved_at_utc": last_saved_utc}
		return _failed("save.error.recovery_required")
	for candidate in [legacy_path, legacy_path + ".bak"]:
		if FileAccess.file_exists(candidate):
			var legacy := SaveStore.load_session(candidate)
			if legacy.error.is_empty():
				# Legacy saves do not have a wall clock; do not invent offline earnings.
				last_saved_utc = clock.call()
				app_state = {}
				return {"session": legacy.session, "error": "", "status": "legacy", "saved_at_utc": last_saved_utc}
	if FileAccess.file_exists(legacy_path) or FileAccess.file_exists(legacy_path + ".bak"):
		return _failed("save.error.recovery_required")
	last_saved_utc = clock.call()
	app_state = {}
	return {"session": HotelSession.new(), "error": "", "status": "new", "saved_at_utc": last_saved_utc}

func _failed(error_key: String) -> Dictionary:
	write_blocked = true
	last_error = error_key
	return {"session": null, "error": error_key, "status": "failed", "saved_at_utc": 0}

func checkpoint(session: HotelSession, reason: StringName = &"autosave", modules: Variant = null, publish: bool = true) -> String:
	if write_blocked:
		return last_error
	if modules != null and not modules is Dictionary:
		return "save.error.invalid"
	var timestamp: int = clock.call()
	var envelope := {"format": "hotel_empire_mobile", "version": VERSION,
		"saved_at_utc": timestamp, "hotel": SessionSnapshot.capture(session),
		"app_state": app_state.duplicate(true) if modules == null else modules.duplicate(true)}
	last_error = writer.call(envelope, path, _valid_envelope)
	if last_error.is_empty():
		last_saved_utc = timestamp
		autosave_elapsed = 0.0
		if modules != null:
			app_state = modules.duplicate(true)
		if publish:
			checkpoint_completed.emit(reason)
	else:
		checkpoint_failed.emit(last_error)
	return last_error

func advance_autosave(delta: float, session: HotelSession) -> void:
	if write_blocked or delta <= 0.0 or not is_finite(delta):
		return
	autosave_elapsed += delta
	if autosave_elapsed >= AUTOSAVE_SECONDS:
		# Retry after an interval, not every frame when storage is unavailable.
		autosave_elapsed = 0.0
		checkpoint(session)

static func restore(data: Variant) -> Dictionary:
	if not data is Dictionary or data.get("format") != "hotel_empire_mobile":
		return {"session": null, "error": "save.error.invalid"}
	if not _integer(data.get("version"), 1, 2147483647):
		return {"session": null, "error": "save.error.invalid"}
	if data.version != VERSION:
		return {"session": null, "error": "save.error.version"}
	if data.get("hotel") is Dictionary and _integer(data.hotel.get("version"), SessionSnapshot.VERSION + 1, 2147483647):
		return {"session": null, "error": "save.error.version"}
	var timestamp: Variant = data.get("saved_at_utc")
	if not _integer(timestamp, 0, 253402300799) or not data.get("app_state") is Dictionary or not _primitive(data.app_state):
		return {"session": null, "error": "save.error.invalid"}
	if data.app_state.get("onboarding") is Dictionary and _integer(data.app_state.onboarding.get("version"), 2, 2147483647):
		return {"session": null, "error": "save.error.version"}
	if data.app_state.has("onboarding") and not OnboardingService.valid(data.app_state.onboarding):
		return {"session": null, "error": "save.error.invalid"}
	for module: String in ["progress_clock", "construction", "player_inventory"]:
		var maximum_version := ConstructionService.VERSION if module == "construction" else 1
		if data.app_state.get(module) is Dictionary and _integer(data.app_state[module].get("version"), maximum_version + 1, 2147483647):
			return {"session": null, "error": "save.error.version"}
	var has_clock: bool = data.app_state.has("progress_clock")
	if data.app_state.has("player_inventory"):
		if not PlayerInventory.valid(data.app_state.player_inventory):
			return {"session": null, "error": "save.error.invalid"}
		if data.app_state.player_inventory.grants.has("tutorial") and (not data.app_state.has("onboarding") or int(data.app_state.onboarding.stage) != OnboardingService.STEPS.size()):
			return {"session": null, "error": "save.error.invalid"}
	if has_clock != data.app_state.has("construction") or (has_clock and not ProgressClock.valid(data.app_state.progress_clock)):
		return {"session": null, "error": "save.error.invalid"}
	var hotel := SessionSnapshot.restore(data.get("hotel"))
	if not hotel.error.is_empty():
		return {"session": null, "error": "save.error.invalid"}
	if data.app_state.has("onboarding") and not data.app_state.onboarding.completed_at.is_empty() and float(data.app_state.onboarding.completed_at.back()) > hotel.session.time + SimulationRules.TIME_EPSILON:
		return {"session": null, "error": "save.error.invalid"}
	if has_clock:
		var construction := ConstructionService.new(hotel.session.hotel)
		if not construction.restore(data.app_state.construction, int(data.app_state.progress_clock.time_ms)):
			return {"session": null, "error": "save.error.invalid"}
	return {"session": hotel.session, "error": "", "saved_at_utc": int(timestamp), "app_state": data.app_state.duplicate(true)}

static func _valid_envelope(data: Variant) -> bool:
	return restore(data).error.is_empty()

static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= minimum and value <= maximum

static func _primitive(value: Variant, depth: int = 0) -> bool:
	if depth > 32:
		return false
	if value == null or value is bool or value is String or value is int:
		return true
	if value is float:
		return is_finite(value)
	if value is Array:
		for item: Variant in value:
			if not _primitive(item, depth + 1):
				return false
		return true
	if value is Dictionary:
		for key: Variant in value:
			if not key is String or not _primitive(value[key], depth + 1):
				return false
		return true
	return false
