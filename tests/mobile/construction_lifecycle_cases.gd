extends RefCounted

var checks: int = 0
var failures: int = 0
var time_source: RefCounted = preload("res://tests/mobile/fake_progress_time.gd").new()

func run() -> Dictionary:
	_restart_and_absence()
	_autosave_and_failed_command()
	_save_validation()
	return {"suite": "construction_lifecycle", "checks": checks, "failures": failures}

func controller(id: String) -> GameController:
	var saves := SaveService.new()
	saves.path = "user://construction-life-" + id + ".json"
	saves.legacy_path = "user://missing-legacy.json"
	saves.clock = time_source.utc
	var result := GameController.new(saves, time_source.clock())
	result.enable_onboarding = false
	return result

func _restart_and_absence() -> void:
	var game := controller("restart")
	check(game.boot().is_empty(), "new application boots and durably writes paired modules")
	var cash := game.session.economy.cash
	var first := game.build(HotelCatalog.room(&"reception"), 0, 0)
	var second := game.build(HotelCatalog.room(&"bedroom"), 3, 0)
	var third := game.build(HotelCatalog.room(&"restaurant"), 5, 0)
	check(first.job != null and second.job != null and third.job != null, "application accepts paid jobs")
	check(game.session.hotel.rooms.is_empty() and game.construction.jobs.size() == 3 and game.construction.jobs[2].slot == -1, "two active crews and FIFO queue are real product state")
	cash -= 800 + 600 + 1000
	check(game.session.economy.cash == cash and game.session.economy.capital_spent == 2400, "cash billed once before service availability")
	var envelope: Dictionary = AtomicJSONStore.read(game.saves.path).data
	var roundtrip := SaveService.restore(envelope)
	check(roundtrip.error.is_empty() and roundtrip.app_state.construction.jobs.size() == 3 and roundtrip.session.hotel.rooms.is_empty(), "pending jobs and paid hotel form a valid atomic envelope")
	time_source.advance(5000)
	game.session.speed = 0
	game.advance(0.1)
	check(game.enter_background().is_empty(), "background stores remaining deadline")
	var ticks := game.session.tick_count
	var saved_clock: Dictionary = game.saves.app_state.progress_clock.duplicate()
	time_source.advance(3600000)
	game.checkpoint(&"background_extra_callback")
	check(game.saves.app_state.progress_clock == saved_clock, "background checkpoints cannot consume the pending absence")
	game = controller("restart")
	check(game.boot().is_empty() and game.construction.jobs.is_empty() and game.construction.completed == 3, "OS kill settles all historical queued deadlines at boot")
	check(game.session.hotel.rooms.size() == 3 and game.session.tick_count == ticks and game.session.economy.cash == cash, "boot completion creates services without ticks or additional charges")
	check(game.return_construction.size() == 3, "return has a bounded completion projection")
	var snapshot := SessionSnapshot.capture(game.session)
	game = controller("restart")
	check(game.boot().is_empty() and game.return_construction.is_empty() and SessionSnapshot.capture(game.session) == snapshot, "second restart cannot replay construction or refunds")
	check(game.upgrade(2).is_empty(), "application accepts a paid room upgrade")
	check(game.demolish(2) == "construction.error.upgrading" and game.session.hotel.by_id(2).level == 1, "pending improvement preserves old level and blocks demolition")
	cash = game.session.economy.cash
	ticks = game.session.tick_count
	game.enter_background()
	time_source.advance(60000)
	game.resume()
	game.resume()
	check(game.session.hotel.by_id(2).level == 2 and game.session.tick_count == ticks and game.session.economy.cash == cash and game.construction.completed == 4, "duplicate lifecycle hooks complete upgrade exactly once")
	check(game.add_floor().is_empty() and game.session.hotel.floors == 1, "floor is paid but unavailable before deadline")
	var id := int(game.construction.jobs[0].id)
	cash = game.session.economy.cash
	check(game.cancel_construction(id).is_empty() and game.session.economy.cash == cash + HotelModel.FLOOR_COST and game.construction.cancelled == 1, "application cancellation refunds capital once")
	check(game.cancel_construction(id) == "construction.error.missing" and game.session.economy.cash == cash + HotelModel.FLOOR_COST, "repeated cancellation cannot duplicate money")
	check(SaveService.restore(AtomicJSONStore.read(game.saves.path).data).error.is_empty(), "refund and counters checkpoint together")

func _autosave_and_failed_command() -> void:
	var game := controller("autosave")
	check(game.boot().is_empty(), "autosave scenario boots")
	game.saves.app_state["other_module"] = {"owned": ["theme"], "count": 2}
	check(game.build(HotelCatalog.room(&"reception"), 0, 0).job != null, "autosave job accepted")
	game.session.speed = 0
	time_source.advance(9000)
	game.advance(30.0)
	var data: Dictionary = AtomicJSONStore.read(game.saves.path).data
	check(data.app_state.progress_clock.time_ms == game.progress_clock.now_ms() and data.app_state.construction.last_ms == game.construction.last_ms and data.hotel.session.tick_count == 0, "paused autosave captures current application clocks without simulation")
	check(data.app_state.other_module.owned == ["theme"], "module updates preserve unrelated global state")
	time_source.advance(1000)
	var result := game.build(HotelCatalog.room(&"reception"), 0, 0)
	check(result.job == null and not result.error.is_empty() and game.construction.completed == 1, "failed purchase still settles a due job")
	data = AtomicJSONStore.read(game.saves.path).data
	check(data.app_state.construction.completed == 1 and data.app_state.construction.jobs.is_empty() and SaveService.restore(data).session.hotel.rooms.size() == 1, "due completion remains durable even when next command fails")
	var saved: Dictionary = data.app_state.progress_clock.duplicate()
	time_source.wall_ms -= 3600000
	game = controller("autosave")
	check(game.boot().is_empty() and game.progress_clock.now_ms() == int(saved.time_ms), "wall rollback cannot undo persisted progress")
	game.enter_background()
	time_source.advance(1000)
	game.resume()
	check(game.progress_clock.now_ms() == int(saved.time_ms), "clock below the watermark cannot claim absence twice")

func _save_validation() -> void:
	var game := controller("validation")
	check(game.boot().is_empty() and game.build(HotelCatalog.room(&"bedroom"), 0, 0).job != null, "validation fixture has a paid reservation")
	var valid: Dictionary = AtomicJSONStore.read(game.saves.path).data
	for module: String in ["construction", "progress_clock"]:
		var bad := valid.duplicate(true)
		bad.app_state.erase(module)
		check(SaveService.restore(bad).error == "save.error.invalid", "missing paired module rejected: " + module)
		bad = valid.duplicate(true)
		bad.app_state[module].version = 2
		check(SaveService.restore(bad).error == "save.error.version", "future module cannot be downgraded: " + module)
		var file := FileAccess.open(game.saves.path, FileAccess.WRITE)
		file.store_string(JSON.stringify(bad))
		file.close()
		var failed := controller("validation")
		check(failed.boot() == "save.error.version" and failed.session == null and failed.saves.write_blocked, "future primary blocks fallback and gameplay")
		check(failed.checkpoint() == "save.error.invalid" and AtomicJSONStore.read(game.saves.path).data.app_state[module].version == 2, "future profile is preserved untouched")
	for mutation: String in ["deadline", "geometry", "capital", "last_ms"]:
		var bad := valid.duplicate(true)
		match mutation:
			"deadline": bad.app_state.construction.jobs[0].end_ms += 1
			"geometry": bad.app_state.construction.jobs[0].column = HotelModel.COLUMNS
			"capital": bad.app_state.construction.jobs[0].cost = 999999
			"last_ms": bad.app_state.construction.last_ms = bad.app_state.progress_clock.time_ms + 1
		check(SaveService.restore(bad).error == "save.error.invalid", "invalid cross-module state rejected: " + mutation)
	var legacy := valid.duplicate(true)
	legacy.app_state.erase("construction")
	legacy.app_state.erase("progress_clock")
	# A pre-timer save contains completed domain rooms, never an unpaid reservation.
	check(SaveService.restore(legacy).error.is_empty(), "pre-timer mobile envelope remains readable")
	var file := FileAccess.open(game.saves.path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	game = controller("validation")
	check(game.boot().is_empty() and game.construction.jobs.is_empty() and game.saves.app_state.has("progress_clock"), "old mobile profile migrates atomically with no invented jobs")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
