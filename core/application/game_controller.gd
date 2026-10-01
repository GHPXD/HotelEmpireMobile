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
signal speedup_used(item_id: StringName, applied_ms: int)

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
var inventory: PlayerInventory
var _speedup_busy: bool = false
var _pending_lifecycle: int = -1

func _init(save_service: SaveService = null, clock_service: ProgressClock = null) -> void:
	saves = save_service if save_service != null else SaveService.new()
	progress_clock = clock_service if clock_service != null else ProgressClock.new()
	if clock_service == null:
		var wall_clock: Callable = saves.clock
		progress_clock.wall_source = func() -> int: return int(wall_clock.call()) * 1000

func boot() -> String:
	if _speedup_busy:
		return "speedup.error.busy"
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
		inventory = PlayerInventory.new()
		if saves.app_state.has("player_inventory") and not inventory.restore(saves.app_state.player_inventory):
			return _boot_failed("save.error.invalid")
		inventory.claim_reward(&"welcome")
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
	inventory = null
	return error

func advance(delta: float) -> void:
	if session == null or background or _speedup_busy or delta <= 0.0 or not is_finite(delta):
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
	if _speedup_busy:
		_pending_lifecycle = 1
		return ""
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
	if _speedup_busy:
		_pending_lifecycle = 0
		return
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
	if _speedup_busy:
		return "speedup.error.busy"
	if session == null:
		return "save.error.invalid"
	if onboarding.observe(session):
		guide_advanced.emit(onboarding.stage)
	if inventory != null and onboarding.enabled and onboarding.stage == OnboardingService.STEPS.size():
		inventory.claim_reward(&"tutorial")
	_store_modules()
	last_error = saves.checkpoint(session, reason)
	return last_error

func _store_modules() -> void:
	if onboarding.enabled:
		saves.app_state["onboarding"] = onboarding.snapshot()
	if inventory != null:
		saves.app_state["player_inventory"] = inventory.snapshot()
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

func use_speedup(job_id: int, item_id: StringName, operation_id: int) -> String:
	if _speedup_busy:
		return "speedup.error.busy"
	if session == null or inventory == null:
		return "error.command"
	if background:
		return "speedup.error.background"
	var error := inventory.spend_error(item_id, operation_id)
	if not error.is_empty():
		return error
	_advance_construction()
	var now_ms := progress_clock.now_ms()
	_store_modules()
	_speedup_busy = true
	var plan := ConstructionSpeedupPlan.prepare(session, construction, inventory, onboarding, saves.app_state, progress_clock.snapshot(), job_id, item_id, operation_id, now_ms)
	if not plan.error.is_empty():
		_end_speedup_transaction()
		return plan.error
	# Observers see completion only after the same command reaches live state.
	last_error = saves.checkpoint(plan.session, &"speedup", plan.modules, false)
	if not last_error.is_empty():
		var failure := last_error
		_end_speedup_transaction()
		return failure
	var item := PlayerInventory.definition(item_id)
	var applied := construction.accelerate(job_id, item.seconds * 1000, now_ms, session.time)
	assert(applied.error.is_empty(), "Validated synchronous speedup diverged from its durable plan")
	var inventory_restored := inventory.restore(plan.inventory.snapshot())
	assert(inventory_restored)
	var previous_stage := onboarding.stage
	var guide_restored := onboarding.restore(plan.onboarding.snapshot())
	assert(guide_restored)
	var events := construction.take_events()
	_end_speedup_transaction()
	saves.checkpoint_completed.emit(&"speedup")
	if onboarding.stage != previous_stage:
		guide_advanced.emit(onboarding.stage)
	construction_changed.emit(events)
	speedup_used.emit(item_id, int(plan.applied_ms))
	return ""

func transaction_active() -> bool:
	return _speedup_busy

func _end_speedup_transaction() -> void:
	_speedup_busy = false
	var pending := _pending_lifecycle
	_pending_lifecycle = -1
	if pending == 1:
		enter_background()
	elif pending == 0:
		resume()

func start_player_work(kind: String, target_id: int) -> String:
	if _speedup_busy:
		return "speedup.error.busy"
	var error := session.player_work.start(session, kind, target_id)
	if not error.is_empty():
		return "work.error." + error
	player_work_changed.emit(kind, "travel", "started")
	return checkpoint(&"player_work_start")

func start_room_service(order_id: int) -> String:
	if _speedup_busy:
		return "speedup.error.busy"
	var error := session.player_work.start_order(session, order_id)
	if not error.is_empty():
		return "work.error." + error
	player_work_changed.emit("room_service", "travel_source", "started")
	return checkpoint(&"player_work_start")

func cancel_player_work() -> String:
	if _speedup_busy:
		return "speedup.error.busy"
	var kind: String = session.player_work.job.get("kind", "")
	if not session.player_work.cancel(session):
		return "work.error.no_task"
	player_work_changed.emit(kind, "", "cancelled")
	return checkpoint(&"player_work_cancel")

func return_player() -> String:
	if _speedup_busy:
		return "speedup.error.busy"
	var error := session.player_work.return_to_lobby(session)
	return checkpoint(&"player_return") if error.is_empty() else "work.error." + error

func set_guide_skipped(skipped: bool) -> String:
	if _speedup_busy:
		return "speedup.error.busy"
	onboarding.start()
	onboarding.skipped = skipped
	return checkpoint(&"onboarding")

func build(definition: RoomDefinition, column: int, floor_index: int) -> Dictionary:
	return _accept_construction(&"build", {"definition": definition, "column": column, "floor_index": floor_index}, &"construction")

func _accept_construction(kind: StringName, arguments: Dictionary, reason: StringName) -> Dictionary:
	if _speedup_busy:
		return {"job": null, "error": "speedup.error.busy"}
	if session == null:
		return {"job": null, "error": "error.command"}
	_advance_construction()
	var now_ms := progress_clock.now_ms()
	_store_modules()
	_speedup_busy = true
	var plan := ConstructionPurchasePlan.prepare(session, construction, kind, arguments, now_ms)
	if not plan.error.is_empty():
		_end_speedup_transaction()
		return {"job": null, "error": plan.error}
	var modules := saves.app_state.duplicate(true)
	modules["construction"] = plan.construction.snapshot()
	last_error = saves.checkpoint(plan.session, reason, modules, false)
	if not last_error.is_empty():
		var error := last_error
		_end_speedup_transaction()
		return {"job": null, "error": error}
	var applied := ConstructionPurchasePlan.apply(construction, kind, arguments, now_ms, session.time)
	assert(applied.error.is_empty(), "Validated construction purchase diverged from its durable plan")
	_end_speedup_transaction()
	saves.checkpoint_completed.emit(reason)
	construction_changed.emit(construction.take_events())
	return applied

func add_floor() -> String:
	return _accept_construction(&"floor", {}, &"floor").error

func hire(definition: EmployeeDefinition, traits: Array[StringName] = []) -> String:
	if _speedup_busy:
		return "speedup.error.busy"
	var error := session.hire(definition, traits)
	return checkpoint(&"staff") if error.is_empty() else error

func upgrade(id: int) -> String:
	return _accept_construction(&"upgrade", {"id": id}, &"upgrade").error

func cancel_construction(id: int) -> String:
	if _speedup_busy:
		return "speedup.error.busy"
	_advance_construction()
	var error := construction.cancel(id, progress_clock.now_ms(), session.time)
	construction_changed.emit(construction.take_events())
	return checkpoint(&"construction_cancelled") if error.is_empty() else error

func specialize(id: int, specialization_id: StringName) -> String:
	return _accept_construction(&"specialize", {"id": id, "specialization": specialization_id}, &"specialization").error

func demolish(id: int) -> String:
	if _speedup_busy:
		return "speedup.error.busy"
	if construction.job_for_room(id) != null:
		return "construction.error.upgrading"
	var error := session.demolish(id)
	return checkpoint(&"demolish") if error.is_empty() else error

func set_tariff(id: int, percent: int) -> String:
	if _speedup_busy:
		return "speedup.error.busy"
	var error := session.set_room_tariff(id, percent)
	return checkpoint(&"tariff") if error.is_empty() else error

func configure_employee(id: int, destination: int) -> String:
	if _speedup_busy:
		return "speedup.error.busy"
	var error := session.configure_employee(id, destination)
	return checkpoint(&"assignment") if error.is_empty() else error

func set_employee_duty(id: int, enabled: bool) -> String:
	if _speedup_busy:
		return "speedup.error.busy"
	var error := session.set_employee_duty(id, enabled)
	return checkpoint(&"staff_duty") if error.is_empty() else error

func set_employee_priority(id: int, priority: StringName) -> String:
	if _speedup_busy:
		return "speedup.error.busy"
	var error := session.set_employee_priority(id, priority)
	return checkpoint(&"staff_priority") if error.is_empty() else error

func dismiss_employee(id: int) -> String:
	if _speedup_busy:
		return "speedup.error.busy"
	var error := session.dismiss_employee(id)
	return checkpoint(&"staff_dismissal") if error.is_empty() else error

func toggle_open() -> void:
	if _speedup_busy:
		return
	session.opened = not session.opened
	checkpoint(&"operation")

func toggle_pause() -> void:
	if _speedup_busy:
		return
	session.speed = 1 if session.speed == 0 else 0
	checkpoint(&"pause")
