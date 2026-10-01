class_name GameController
extends RefCounted
## Single application owner of the active hotel; presentation sends commands.

signal session_changed
signal simulation_advanced
signal lifecycle_changed(background: bool)
signal player_work_changed(kind: String, phase: String, result: String)
signal guide_advanced(stage: int)
signal staff_changed(event: Dictionary)

var session: HotelSession
var saves: SaveService
var background: bool = false
var accumulator: float = 0.0
var boot_status: String = ""
var last_error: String = ""
var onboarding := OnboardingService.new()
var enable_onboarding: bool = true

func _init(save_service: SaveService = null) -> void:
	saves = save_service if save_service != null else SaveService.new()

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
		background = false
		accumulator = 0.0
		session_changed.emit()
		if boot_status == "new" and enable_onboarding:
			checkpoint(&"profile_created")
	return last_error

func advance(delta: float) -> void:
	if session == null or background or delta <= 0.0 or not is_finite(delta):
		return
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
	saves.advance_autosave(delta, session)
	if advanced:
		simulation_advanced.emit()

func enter_background() -> String:
	if background or session == null:
		return last_error
	background = true
	accumulator = 0.0
	last_error = saves.checkpoint(session, &"background")
	lifecycle_changed.emit(true)
	return last_error

func resume() -> void:
	if not background or session == null:
		return
	background = false
	accumulator = 0.0
	# Aggregated offline settlement is added with timers in Sprint 5.
	lifecycle_changed.emit(false)

func checkpoint(reason: StringName = &"command") -> String:
	if session == null:
		return "save.error.invalid"
	if onboarding.observe(session):
		guide_advanced.emit(onboarding.stage)
	if onboarding.enabled:
		saves.app_state["onboarding"] = onboarding.snapshot()
	last_error = saves.checkpoint(session, reason)
	return last_error

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
		return {"room": null, "error": "error.command"}
	var error := session.hotel.build_error(definition, column, floor_index)
	if not error.is_empty():
		return {"room": null, "error": error}
	var room := session.hotel.build(definition, column, floor_index, session.time)
	return {"room": room, "error": checkpoint(&"construction")}

func add_floor() -> String:
	var error := session.hotel.add_floor(session.time)
	return checkpoint(&"floor") if error.is_empty() else error

func hire(definition: EmployeeDefinition, traits: Array[StringName] = []) -> String:
	var error := session.hire(definition, traits)
	return checkpoint(&"staff") if error.is_empty() else error

func upgrade(id: int) -> String:
	var error := session.upgrade_room(id)
	return checkpoint(&"upgrade") if error.is_empty() else error

func demolish(id: int) -> String:
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
