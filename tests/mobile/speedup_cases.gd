extends RefCounted

var checks: int = 0
var failures: int = 0
var time_source: RefCounted = preload("res://tests/mobile/fake_progress_time.gd").new()
var observer_game: GameController
var observed: int = 0
var nested_observer_error: String = ""
var observed_consistent: bool = false

func run() -> Dictionary:
	_inventory()
	_invalid_inventory()
	_full_completion_and_observers()
	_partial_restart()
	_cancellation_and_invalid_targets()
	_storage_failure()
	_lifecycle_during_commit()
	_manual_work_identity()
	_migration_and_future_version()
	return {"suite": "speedup", "checks": checks, "failures": failures}

func controller(id: String, guided: bool = false) -> GameController:
	var saves := SaveService.new()
	saves.path = "user://speedup-" + id + ".json"
	saves.legacy_path = "user://missing-speedup-legacy.json"
	saves.clock = time_source.utc
	var game := GameController.new(saves, time_source.clock())
	game.enable_onboarding = guided
	return game

func _inventory() -> void:
	var inventory := PlayerInventory.new()
	check(inventory.quantity(&"5m") == 0 and inventory.next_operation_id() == 1, "empty global inventory has no invented stock")
	check(inventory.claim_reward(&"welcome") and inventory.quantity(&"5m") == 1, "authored welcome item grants once")
	var before := inventory.snapshot()
	check(not inventory.claim_reward(&"welcome") and not inventory.claim_reward(&"unknown") and inventory.snapshot() == before, "duplicate or unknown source changes nothing")
	check(inventory.spend(&"5m", 2) == "speedup.error.invalid" and inventory.spend(&"1h", 1) == "speedup.error.empty" and inventory.snapshot() == before, "future IDs and empty stock preserve receipts and operation sequence")
	check(inventory.spend(&"5m", 1).is_empty() and inventory.quantity(&"5m") == 0 and inventory.next_operation_id() == 2, "one spend consumes exactly one item")
	before = inventory.snapshot()
	check(inventory.spend(&"15m", 1) == "speedup.error.duplicate" and inventory.spend(&"unknown", 2) == "speedup.error.invalid" and inventory.snapshot() == before, "old operation cannot be replayed with a different item")
	check(inventory.claim_reward(&"tutorial") and inventory.quantity(&"15m") == 1, "tutorial grant is independent of hotel currency")
	check(inventory.spend(&"15m", 2).is_empty() and inventory.next_operation_id() == 3, "spend IDs are monotonic across item types")
	var restored := PlayerInventory.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(inventory.snapshot()))) and restored.snapshot() == inventory.snapshot(), "primitive global stock roundtrip")
	check(not restored.claim_reward(&"welcome") and not restored.claim_reward(&"tutorial") and restored.quantity(&"5m") == 0, "restart cannot restore consumed starter grants")
	var copy := restored.snapshot()
	copy.grants.welcome["5m"] = 999
	check(restored.quantity(&"5m") == 0 and PlayerInventory.RULES.welcome == {"5m": 1}, "snapshots and profile receipts do not mutate definitions")
	for item in PlayerInventory.DEFINITIONS:
		check(item.seconds > 0 and PlayerInventory.definition(item.id) == item, "authored immutable speedup " + String(item.id))

func _invalid_inventory() -> void:
	var inventory := PlayerInventory.new()
	inventory.claim_reward(&"welcome")
	var valid := inventory.snapshot()
	for mutation: String in ["missing", "future", "unknown_source", "unknown_item", "negative", "fractional", "overspend", "sequence", "extra", "missing_stock", "overflow"]:
		var bad := valid.duplicate(true)
		match mutation:
			"missing": bad.erase("grants")
			"future": bad.version = 2
			"unknown_source": bad.grants["store_unverified"] = {"5m": 1}
			"unknown_item": bad.grants.welcome["unknown"] = 1
			"negative": bad.spent["5m"] = -1
			"fractional": bad.grants.welcome["5m"] = 0.5
			"overspend": bad.spent["5m"] = 2
			"sequence": bad.next_spend_id = 99
			"extra": bad["cash"] = 99
			"missing_stock": bad.spent.erase("15m")
			"overflow": bad.grants.welcome["5m"] = PlayerInventory.MAX_ITEMS + 1
		check(not inventory.restore(bad) and inventory.snapshot() == valid, "invalid inventory restore is atomic: " + mutation)

func _full_completion_and_observers() -> void:
	var game := controller("completion", true)
	check(game.boot().is_empty() and game.inventory.quantity(&"5m") == 1, "new profile persists a single free welcome speedup")
	check(game.build(HotelCatalog.room(&"reception"), 0, 0).job != null, "paid reception accepted before acceleration")
	var cash := game.session.economy.cash
	var live_session := game.session
	observer_game = game
	game.saves.checkpoint_completed.connect(_observe_checkpoint)
	check(game.use_speedup(1, &"5m", 1).is_empty(), "confirmed operation completes eligible job")
	check(game.session == live_session and game.session.hotel.rooms.size() == 1 and game.onboarding.stage == 1 and game.inventory.quantity(&"5m") == 0, "live session identity preserved and guide observes completed construction")
	check(game.session.economy.cash == cash and game.session.tick_count == 0 and game.construction.completed == 1, "speedup changes time without cash, simulation ticks or power modifiers")
	check(observed == 1 and observed_consistent and nested_observer_error == "speedup.error.duplicate", "checkpoint observers see fully applied durable state and cannot replay a spend")
	observer_game = null
	game.saves.checkpoint_completed.disconnect(_observe_checkpoint)
	var restored := controller("completion", true)
	check(restored.boot().is_empty() and restored.inventory.quantity(&"5m") == 0 and restored.onboarding.stage == 1 and restored.construction.completed == 1, "OS kill cannot lose delivery or restore consumed stock")
	check(restored.use_speedup(1, &"5m", 1) == "speedup.error.duplicate" and restored.session.economy.cash == cash, "old callback remains idempotent after restart")

func _observe_checkpoint(reason: StringName) -> void:
	if reason != &"speedup":
		return
	observed += 1
	var saved := SaveService.restore(AtomicJSONStore.read(observer_game.saves.path).data)
	var stock := PlayerInventory.new()
	observed_consistent = saved.error.is_empty() and stock.restore(saved.app_state.player_inventory) and stock.snapshot() == observer_game.inventory.snapshot() and SessionSnapshot.capture(saved.session) == SessionSnapshot.capture(observer_game.session)
	nested_observer_error = observer_game.use_speedup(1, &"5m", 1)

func long_hotel(id: String) -> GameController:
	var game := controller(id)
	check(game.boot().is_empty(), "long construction fixture boots " + id)
	game.session.economy.cash = 100000
	check(game.session.hotel.add_floor().is_empty(), "authoring fixture floor")
	for column in range(0, 16, 2):
		check(game.session.hotel.build(HotelCatalog.room(&"bedroom"), column, 0) != null, "authoring fixture room")
	check(game.build(HotelCatalog.room(&"bedroom"), 0, 1).job != null and int(game.construction.jobs[0].duration_ms) == 600000, "mid progression uses authored ten-minute job")
	return game

func _partial_restart() -> void:
	var game := long_hotel("partial")
	var cash := game.session.economy.cash
	var start := int(game.construction.jobs[0].start_ms)
	time_source.advance(10000)
	game.session.speed = 0
	game.advance(0.01)
	check(game.use_speedup(1, &"5m", 1).is_empty() and game.construction.jobs.size() == 1, "partial speedup leaves a real pending project")
	var job := game.construction.jobs[0]
	check(int(job.duration_ms) == 300000 and int(job.end_ms) == start + 300000 and int(job.end_ms) - game.progress_clock.now_ms() == 290000, "five-minute item reduces actual duration by exactly five minutes")
	check(game.inventory.quantity(&"5m") == 0 and game.session.hotel.rooms.size() == 8 and game.session.economy.cash == cash, "partial acceleration creates no early room or extra currency")
	check(SaveService.restore(AtomicJSONStore.read(game.saves.path).data).error.is_empty(), "shortened timing and consumed item form a valid envelope")
	game.enter_background()
	time_source.advance(289999)
	game = controller("partial")
	check(game.boot().is_empty() and game.construction.jobs.size() == 1 and game.session.hotel.rooms.size() == 8, "restart one millisecond early cannot finish shortened job")
	time_source.advance(1)
	game.advance(0.01)
	check(game.construction.jobs.is_empty() and game.session.hotel.rooms.size() == 9 and game.session.tick_count == 0 and game.session.economy.cash == cash, "shortened deadline completes exactly once with no catch-up ticks")

func _cancellation_and_invalid_targets() -> void:
	var game := controller("targets")
	check(game.boot().is_empty(), "target rejection fixture boots")
	for args: Array in [[&"reception", 0], [&"bedroom", 3], [&"restaurant", 5]]:
		check(game.build(HotelCatalog.room(args[0]), args[1], 0).job != null, "queue fixture accepted")
	var before := game.inventory.snapshot()
	check(game.use_speedup(3, &"5m", 1) == "speedup.error.queued" and game.inventory.snapshot() == before, "queued job cannot consume a token")
	check(game.use_speedup(99, &"5m", 1) == "construction.error.missing" and game.use_speedup(1, &"1h", 1) == "speedup.error.empty" and game.inventory.snapshot() == before, "missing target and empty stock preserve all items")
	game.enter_background()
	check(game.use_speedup(1, &"5m", 1) == "speedup.error.background" and game.inventory.snapshot() == before, "background cannot spend items")
	game.resume()
	check(game.use_speedup(1, &"5m", 1).is_empty() and game.construction.by_id(3).slot >= 0 and game.construction.by_id(3).start_ms == game.progress_clock.now_ms(), "instant completion starts waiting project at the actual acceleration boundary")
	var long_game := long_hotel("cancel")
	check(long_game.use_speedup(1, &"5m", 1).is_empty(), "partial acceleration before cancellation")
	var cash := long_game.session.economy.cash
	check(long_game.cancel_construction(1).is_empty() and long_game.session.economy.cash == cash + 600 and long_game.inventory.quantity(&"5m") == 0, "cancellation returns paid capital but never the consumed token")
	var core := ConstructionService.new(HotelSession.new().hotel)
	var result := core.enqueue_build(HotelCatalog.room(&"bedroom"), 0, 0, 0, 0.0)
	check(result.job != null and core.accelerate(1, 0, 0, 0.0).error == "speedup.error.invalid", "non-positive acceleration rejected")
	check(core.accelerate(1, 1, -1, 0.0).error == "speedup.error.invalid", "acceleration cannot rewind construction time")

func _storage_failure() -> void:
	var game := controller("fault")
	check(game.boot().is_empty() and game.build(HotelCatalog.room(&"bedroom"), 0, 0).job != null, "storage fault fixture")
	var hotel := SessionSnapshot.capture(game.session)
	var queue := game.construction.snapshot()
	var stock := game.inventory.snapshot()
	var primary := FileAccess.get_file_as_string(game.saves.path)
	var backup := FileAccess.get_file_as_string(game.saves.path + ".bak")
	var fault: RefCounted = preload("res://tests/mobile/speedup_fault_writer.gd").new()
	fault.game = game
	game.saves.writer = fault.write
	check(game.use_speedup(1, &"5m", 1) == "save.error.write", "failed atomic write reports an error before applying speedup")
	check(game.construction.snapshot() == queue and game.inventory.snapshot() == stock and SessionSnapshot.capture(game.session) == hotel, "write failure preserves stock, room, cash, queue and simulation")
	check(FileAccess.get_file_as_string(game.saves.path) == primary and FileAccess.get_file_as_string(game.saves.path + ".bak") == backup, "failed writer preserves both durable copies")
	check(fault.nested_error == "speedup.error.busy" and fault.build_error == "speedup.error.busy" and not game.transaction_active(), "reentrant commands cannot change a transaction and failure releases its guard")
	game.saves.writer = AtomicJSONStore.write
	fault.game = null
	check(game.use_speedup(1, &"5m", 1).is_empty() and game.inventory.quantity(&"5m") == 0 and game.session.hotel.rooms.size() == 1, "same operation can retry after storage recovers")

func _lifecycle_during_commit() -> void:
	for mode: String in ["pause", "pause_resume"]:
		var game := controller(mode)
		check(game.boot().is_empty() and game.build(HotelCatalog.room(&"bedroom"), 0, 0).job != null, "lifecycle transaction fixture " + mode)
		var fault: RefCounted = preload("res://tests/mobile/speedup_fault_writer.gd").new()
		fault.mode = mode
		fault.game = game
		game.saves.writer = fault.write
		check(game.use_speedup(1, &"5m", 1).is_empty(), "lifecycle transition cannot interrupt a durable consumption " + mode)
		check(fault.nested_error == "speedup.error.busy" and fault.build_error == "speedup.error.busy" and game.session.tick_count == 0, "nested callbacks do not change stock or tick the candidate state " + mode)
		check(game.background == (mode == "pause") and not game.transaction_active() and game.inventory.quantity(&"5m") == 0, "latest lifecycle intent is applied after commit " + mode)
		game.saves.writer = AtomicJSONStore.write
		fault.game = null
		var restored := controller(mode)
		check(restored.boot().is_empty() and restored.inventory.quantity(&"5m") == 0 and restored.session.hotel.rooms.size() == 1, "lifecycle and restart preserve acceleration " + mode)

func _manual_work_identity() -> void:
	var game := controller("manual")
	check(game.boot().is_empty(), "manual operation fixture boots")
	var reception := game.session.hotel.build(HotelCatalog.room(&"reception"), 0, 0)
	game.session.hotel.build(HotelCatalog.room(&"bedroom"), 3, 0)
	reception.condition = 75
	check(game.start_player_work("repair", reception.id).is_empty(), "real manual repair begins independently")
	var live_session := game.session
	var actor := game.session.player_work.worker(game.session)
	var work := PlayerWorkSnapshot.capture(game.session.player_work)
	check(game.build(HotelCatalog.room(&"restaurant"), 5, 0).job != null and game.use_speedup(1, &"5m", 1).is_empty(), "speedup used during a physical task")
	check(game.session == live_session and game.session.player_work.worker(game.session) == actor and PlayerWorkSnapshot.capture(game.session.player_work) == work and reception.condition == 75, "transaction preserves live actor identity and cannot complete physical work")

func _migration_and_future_version() -> void:
	var game := controller("migration")
	check(game.boot().is_empty(), "inventory migration fixture")
	var data: Dictionary = AtomicJSONStore.read(game.saves.path).data
	data.app_state.erase("player_inventory")
	write(game.saves.path, data)
	game = controller("migration")
	check(game.boot().is_empty() and game.inventory.quantity(&"5m") == 1 and game.saves.app_state.has("player_inventory"), "pre-inventory profile migrates with a single free welcome receipt")
	game = controller("migration")
	check(game.boot().is_empty() and game.inventory.quantity(&"5m") == 1, "migration restart cannot repeat the welcome grant")
	data = AtomicJSONStore.read(game.saves.path).data
	data.app_state.player_inventory.version = 2
	write(game.saves.path, data)
	game = controller("migration")
	check(game.boot() == "save.error.version" and game.session == null and game.saves.write_blocked and AtomicJSONStore.read(game.saves.path).data.app_state.player_inventory.version == 2, "future inventory blocks downgrade and preserves primary")

func write(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
