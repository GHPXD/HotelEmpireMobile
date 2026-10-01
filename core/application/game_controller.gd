class_name GameController
extends RefCounted
## Single application owner of the active hotel; presentation sends commands.

signal session_changed
signal simulation_advanced
signal lifecycle_changed(background: bool)
signal player_work_changed(kind: String, phase: String, result: String)
signal guide_advanced(stage: int)
signal staff_changed(event: Dictionary)
signal construction_changed(events: Array[Dictionary])

var session: HotelSession
var saves: SaveService
var background: bool = false
var accumulator: float = 0.0
var boot_status: String = ""
var last_error: String = ""
var onboarding := OnboardingService.new()
var enable_onboarding: bool = true
var progress_clock: ProgressClock
var construction: ConstructionService
var return_construction: Array[Dictionary] = []

func _init(save_service: SaveService = null, clock_service: ProgressClock = null) -> void:
	saves = save_service if save_service != null else SaveService.new()
	progress_clock = clock_service if clock_service != null else ProgressClock.new()
	if clock_service == null:
		var wall_clock: Callable = saves.clock
		progress_clock.wall_source = func() -> int: return int(wall_clock.call()) * 1000

func boot() -> String:
	var result := saves.boot()
	boot_status = result.status
	last_error = result.error
	if last_error.is_empty():
		session = result.session
		if saves.app_state.has("onboarding"):
			onboarding.restore(saves.app_state.onboarding)
		elif boot_status == "new" and enable_onboarding:
			session.economy.cash = session.player_work.rules.mobile_starting_cash
			onboarding.start()
		var clock_state: Dictionary = saves.app_state.get("progress_clock", {})
		var clock_result := progress_clock.begin(clock_state, result.saved_at_utc if clock_state.is_empty() and boot_status in ["loaded", "recovered"] else -1)
		if not clock_result.error.is_empty():
			return _boot_failed(clock_result.error)
		construction = ConstructionService.new(session.hotel)
		if saves.app_state.has("construction") and not construction.restore(saves.app_state.construction, progress_clock.now_ms()):
			return _boot_failed("save.error.invalid")
		background = false
		accumulator = 0.0
		return_construction = _advance_construction(false)
		session_changed.emit()
		# Migration and offline completion become durable before gameplay resumes.
		checkpoint(&"profile_created" if boot_status == "new" else &"profile_resumed")
	return last_error

func _boot_failed(error: String) -> String:
	last_error = error
	saves.write_blocked = true
	saves.last_error = error
	session = null
	construction = null
	return error

func advance(delta: float) -> void:
	if session == null or background or delta <= 0.0 or not is_finite(delta):
		return
	_advance_construction()
	# Preserve the fixed tick and cap catch-up after a delayed foreground frame.
	accumulator += minf(delta, 0.25) * session.speed
	var advanced := false
	var work_revision: int = session.player_work.revision
	var work_kind: String = session.player_work.job.get("kind", "")
	var staff_revision := session.employees.revision
	while accumulator + SimulationRules.TIME_EPSILON >= session.rules.tick:
		session.tick(session.rules.tick)
		accumulator = maxf(0.0, accumulator - session.rules.tick)
		advanced = true
	if session.player_work.revision != work_revision:
		checkpoint(&"player_work_transition")
		player_work_changed.emit(work_kind, session.player_work.job.get("phase", ""), session.player_work.last_result)
	if session.employees.revision != staff_revision:
		if session.player_work.revision == work_revision:
			checkpoint(&"staff_transition")
		staff_changed.emit(session.employees.last_event.duplicate())
	elif session.player_work.revision == work_revision and onboarding.observe(session):
		guide_advanced.emit(onboarding.stage)
		checkpoint(&"onboarding")
	_store_modules()
	saves.advance_autosave(delta, session)
	if advanced:
		simulation_advanced.emit()

func enter_background() -> String:
	if background or session == null:
		return last_error
	_advance_construction(false)
	background = true
	progress_clock.suspend()
	accumulator = 0.0
	last_error = checkpoint(&"background")
	lifecycle_changed.emit(true)
	return last_error

func resume() -> void:
	if not background or session == null:
		return
	var clock_result := progress_clock.resume()
	if not clock_result.error.is_empty():
		last_error = clock_result.error
		return
	background = false
	accumulator = 0.0
	return_construction = _advance_construction(false)
	checkpoint(&"resume")
	lifecycle_changed.emit(false)

func checkpoint(reason: StringName = &"command") -> String:
	if session == null:
		return "save.error.invalid"
	if onboarding.observe(session):
		guide_advanced.emit(onboarding.stage)
	_store_modules()
	last_error = saves.checkpoint(session, reason)
	return last_error

func _store_modules() -> void:
	if onboarding.enabled:
		saves.app_state["onboarding"] = onboarding.snapshot()
	if progress_clock.initialized and construction != null:
		saves.app_state["progress_clock"] = progress_clock.snapshot()
		saves.app_state["construction"] = construction.snapshot()

func _advance_construction(persist: bool = true) -> Array[Dictionary]:
	construction.advance(progress_clock.now_ms(), session.time)
	var events := construction.take_events()
	if not events.is_empty():
		if persist:
			checkpoint(&"construction_completed")
		construction_changed.emit(events)
	return events

func start_player_work(kind: String, target_id: int) -> String:
	var error := session.player_work.start(session, kind, target_id)
	if not error.is_empty():
		return "work.error." + error
	player_work_changed.emit(kind, "travel", "started")
	return checkpoint(&"player_work_start")

func start_room_service(order_id: int) -> String:
	var error := session.player_work.start_order(session, order_id)
	if not error.is_empty():
		return "work.error." + error
	player_work_changed.emit("room_service", "travel_source", "started")
	return checkpoint(&"player_work_start")

func cancel_player_work() -> String:
	var kind: String = session.player_work.job.get("kind", "")
	if not session.player_work.cancel(session):
		return "work.error.no_task"
	player_work_changed.emit(kind, "", "cancelled")
	return checkpoint(&"player_work_cancel")

func return_player() -> String:
	var error := session.player_work.return_to_lobby(session)
	return checkpoint(&"player_return") if error.is_empty() else "work.error." + error

func set_guide_skipped(skipped: bool) -> String:
	onboarding.start()
	onboarding.skipped = skipped
	return checkpoint(&"onboarding")

func build(definition: RoomDefinition, column: int, floor_index: int) -> Dictionary:
	if session == null:
		return {"job": null, "error": "error.command"}
	_advance_construction()
	var result := construction.enqueue_build(definition, column, floor_index, progress_clock.now_ms(), session.time)
	if result.error.is_empty():
		result.error = checkpoint(&"construction")
	construction_changed.emit(construction.take_events())
	return result

func add_floor() -> String:
	_advance_construction()
	var result := construction.enqueue_floor(progress_clock.now_ms(), session.time)
	var error: String = result.error
	construction_changed.emit(construction.take_events())
	return checkpoint(&"floor") if error.is_empty() else error

func hire(definition: EmployeeDefinition, traits: Array[StringName] = []) -> String:
	var error := session.hire(definition, traits)
	return checkpoint(&"staff") if error.is_empty() else error

func upgrade(id: int) -> String:
	_advance_construction()
	var result := construction.enqueue_upgrade(id, progress_clock.now_ms(), session.time)
	var error: String = result.error
	construction_changed.emit(construction.take_events())
	return checkpoint(&"upgrade") if error.is_empty() else error

func cancel_construction(id: int) -> String:
	_advance_construction()
	var error := construction.cancel(id, progress_clock.now_ms(), session.time)
	construction_changed.emit(construction.take_events())
	return checkpoint(&"construction_cancelled") if error.is_empty() else error

func demolish(id: int) -> String:
	if construction.job_for_room(id) != null:
		return "construction.error.upgrading"
	var error := session.demolish(id)
	return checkpoint(&"demolish") if error.is_empty() else error

func set_tariff(id: int, percent: int) -> String:
	var error := session.set_room_tariff(id, percent)
	return checkpoint(&"tariff") if error.is_empty() else error

func configure_employee(id: int, destination: int) -> String:
	var error := session.configure_employee(id, destination)
	return checkpoint(&"assignment") if error.is_empty() else error

func set_employee_duty(id: int, enabled: bool) -> String:
	var error := session.set_employee_duty(id, enabled)
	return checkpoint(&"staff_duty") if error.is_empty() else error

func set_employee_priority(id: int, priority: StringName) -> String:
	var error := session.set_employee_priority(id, priority)
	return checkpoint(&"staff_priority") if error.is_empty() else error

func dismiss_employee(id: int) -> String:
	var error := session.dismiss_employee(id)
	return checkpoint(&"staff_dismissal") if error.is_empty() else error

func toggle_open() -> void:
	session.opened = not session.opened
	checkpoint(&"operation")

func toggle_pause() -> void:
	session.speed = 1 if session.speed == 0 else 0
	checkpoint(&"pause")
