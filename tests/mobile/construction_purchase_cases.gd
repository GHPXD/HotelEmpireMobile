extends RefCounted

var checks: int = 0
var failures: int = 0
var observer_game: GameController
var observations: int = 0
var coherent: bool = false

func run() -> Dictionary:
	for kind: StringName in [&"build", &"floor", &"upgrade", &"specialize"]:
		_fault_and_retry(kind)
	_lifecycle()
	return {"suite": "construction_purchase", "checks": checks, "failures": failures}

func _game(id: String, time_source: RefCounted) -> GameController:
	var saves := SaveService.new()
	saves.path = "user://purchase-" + id + ".json"
	saves.legacy_path = "user://no-purchase-legacy.json"
	saves.clock = time_source.utc
	var game := GameController.new(saves, time_source.clock())
	game.enable_onboarding = false
	check(game.boot().is_empty(), "transaction fixture boots")
	game.session.economy.cash = 100000
	game.session.progression.evaluate({"bookings": 3})
	var room := game.session.hotel.build(HotelCatalog.room(&"bedroom"), 0, 0)
	game.session.upgrade_room(room.id)
	game.session.upgrade_room(room.id)
	game.saves.app_state["unrelated"] = {"value": "keep", "owned": ["a", "b"]}
	check(game.checkpoint().is_empty(), "transaction fixture persists neutral N3")
	return game

func _buy(game: GameController, kind: StringName) -> String:
	match kind:
		&"build": return game.build(HotelCatalog.room(&"bedroom"), 3, 0).error
		&"floor": return game.add_floor()
		&"upgrade": return game.upgrade(1)
		&"specialize": return game.specialize(1, &"comfort")
	return "error.command"

func _fault_and_retry(kind: StringName) -> void:
	var time_source: RefCounted = preload("res://tests/mobile/fake_progress_time.gd").new()
	var game := _game(String(kind), time_source)
	if kind == &"upgrade":
		game.session.progression.evaluate({"bookings": 10, "meals": 5, "cleaned": 5})
		game.checkpoint()
	var before := SessionSnapshot.capture(game.session)
	var queue := game.construction.snapshot()
	var stock := game.inventory.snapshot()
	var file := FileAccess.get_file_as_bytes(game.saves.path)
	var backup := FileAccess.get_file_as_bytes(game.saves.path + ".bak")
	var identity := game.session
	var room_identity := game.session.hotel.by_id(1)
	var fault: RefCounted = preload("res://tests/mobile/speedup_fault_writer.gd").new()
	fault.game = game
	game.saves.writer = fault.write
	check(_buy(game, kind) == "save.error.write", "failed storage rejects " + String(kind))
	check(SessionSnapshot.capture(game.session) == before and game.construction.snapshot() == queue and game.inventory.snapshot() == stock, "failed purchase leaves Cash/capital/queue/stock/ticks identical")
	check(FileAccess.get_file_as_bytes(game.saves.path) == file and FileAccess.get_file_as_bytes(game.saves.path + ".bak") == backup, "failed purchase preserves primary and backup bytes")
	check(fault.calls == 1 and fault.nested_error == "speedup.error.busy" and fault.build_error == "speedup.error.busy", "storage hook cannot reenter semantic mutations")
	game.saves.writer = AtomicJSONStore.write
	fault.game = null
	observer_game = game
	observations = 0
	coherent = false
	game.saves.checkpoint_completed.connect(_observed)
	check(_buy(game, kind).is_empty(), "purchase retry succeeds")
	check(game.session == identity and game.session.hotel.by_id(1) == room_identity, "durable commit preserves live model identities")
	check(observations == 1 and coherent, "completion observers see the same durable Cash and queue as live state")
	check(game.construction.jobs.size() == 1 and game.construction.next_id == 2 and game.construction.jobs[0].kind == String(kind), "retry creates exactly one paid job and ID")
	check(game.saves.app_state.unrelated == {"value": "keep", "owned": ["a", "b"]}, "transaction preserves unrelated application modules")
	var cash := game.session.economy.cash
	var revenue := game.session.economy.revenue
	game.enter_background()
	time_source.advance(3600000)
	game.resume()
	check(game.construction.completed == 1 and game.construction.jobs.is_empty() and game.session.economy.cash == cash and game.session.economy.revenue == revenue, "later completion has no second debit or fabricated revenue")
	check(game.session.economy.cash + game.session.economy.capital_spent + game.session.economy.expenses - game.session.economy.revenue == 100000, "durable purchase conserves fixture wealth")
	game.saves.checkpoint_completed.disconnect(_observed)
	observer_game = null

func _observed(_reason: StringName) -> void:
	observations += 1
	var saved: Dictionary = AtomicJSONStore.read(observer_game.saves.path).data
	var result := SaveService.restore(saved)
	coherent = result.error.is_empty() and result.session.economy.cash == observer_game.session.economy.cash and int(saved.app_state.construction.next_id) == observer_game.construction.next_id and saved.app_state.construction.jobs.size() == observer_game.construction.jobs.size() and not observer_game.transaction_active()

func _lifecycle() -> void:
	for mode: String in ["pause", "pause_resume"]:
		var time_source: RefCounted = preload("res://tests/mobile/fake_progress_time.gd").new()
		var game := _game(mode, time_source)
		var fault: RefCounted = preload("res://tests/mobile/speedup_fault_writer.gd").new()
		fault.mode = mode
		fault.game = game
		game.saves.writer = fault.write
		check(game.specialize(1, &"economy").is_empty(), "lifecycle hook cannot interrupt durable purchase")
		check(game.background == (mode == "pause") and game.construction.jobs.size() == 1 and game.session.tick_count == 0, "latest lifecycle request applies after coherent purchase")
		var result := SaveService.restore(AtomicJSONStore.read(game.saves.path).data)
		check(result.error.is_empty() and result.app_state.construction.jobs.size() == 1 and result.session.economy.cash == game.session.economy.cash, "lifecycle checkpoint retains paid job exactly once")
		fault.game = null

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
