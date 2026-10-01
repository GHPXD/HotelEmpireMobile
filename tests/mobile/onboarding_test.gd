extends SceneTree
## Application-level persistence, guide facts and lifecycle during physical work.

var failures: int = 0
var checks: int = 0
var stages: Array[int] = []
var progress_time: RefCounted = preload("res://tests/mobile/fake_progress_time.gd").new()

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game := _controller("new")
	check(game.boot().is_empty() and game.session.economy.cash == 2400 and game.onboarding.active(), "new profile uses mobile budget and guide")
	check(FileAccess.file_exists(game.saves.path) and game.saves.app_state.onboarding.stage == 0, "profile initialized atomically before first command")
	game.saves.app_state["future_module"] = {"owned": ["original_theme"], "count": 2}
	game.guide_advanced.connect(func(stage: int) -> void: stages.append(stage))
	check(game.build(HotelCatalog.room(&"reception"), 0, 0).job != null and game.onboarding.stage == 0, "guide waits for the actual reception, not purchase")
	finish_construction(game, 10000)
	check(game.onboarding.stage == 1, "guide advances after completed reception")
	check(game.build(HotelCatalog.room(&"bedroom"), 3, 0).job != null and game.onboarding.stage == 1, "guide waits for completed bedroom")
	finish_construction(game, 20000)
	check(game.onboarding.stage == 2, "guide advances after real bedroom")
	game.toggle_open()
	check(game.onboarding.stage == 3, "open gate")
	var session := game.session
	for index in 100:
		game.advance(session.rules.tick)
		if session.player_work.task_error(session, "checkin", 1).is_empty():
			break
	var cash: int = session.economy.cash
	check(game.start_player_work("checkin", 1).is_empty() and game.onboarding.stage == 3 and session.economy.cash == cash, "guide waits for completion, never click")
	var before := SessionSnapshot.capture(session)
	check(game.enter_background().is_empty(), "background saves active work")
	game.advance(3600)
	check(preload("res://tests/snapshot_comparison.gd").difference(before, SessionSnapshot.capture(session), "background").is_empty(), "background does not finish work")
	var killed := _controller("new")
	check(killed.boot().is_empty() and killed.onboarding.stage == 3 and not killed.session.player_work.job.is_empty(), "OS kill resumes active task and stage")
	game = killed
	session = game.session
	game.resume()
	for index in 100:
		game.advance(session.rules.tick)
		if session.player_work.job.is_empty():
			break
	check(game.onboarding.stage == 4 and session.player_work.totals.checkins == 1 and session.economy.revenue == 140, "actual checkin advances guide once")
	check(game.build(HotelCatalog.room(&"restaurant"), 5, 0).job != null and game.onboarding.stage == 4, "paid food construction awaits deadline")
	finish_construction(game, 30000)
	check(game.onboarding.stage == 5, "completed food construction")
	var order_id: int = -1
	for index in 1200:
		game.advance(session.rules.tick)
		if not session.player_work.orders.is_empty():
			order_id = int(session.player_work.orders[0].id)
			break
	check(order_id > 0, "natural guest generates room-service opportunity")
	check(game.start_room_service(order_id).is_empty() and game.onboarding.stage == 5, "order start does not complete guide")
	for index in 400:
		game.advance(session.rules.tick)
		if session.player_work.job.is_empty():
			break
	check(game.onboarding.stage == 6 and session.player_work.totals.delivered == 1, "delivery completion advances")
	for index in 2000:
		game.advance(session.rules.tick)
		if session.hotel.rooms[1].dirty:
			break
	check(session.hotel.rooms[1].dirty, "actual departing guest dirties room")
	check(game.start_player_work("cleaning", 2).is_empty(), "manual cleanup after real departure")
	for index in 200:
		game.advance(session.rules.tick)
		if session.player_work.job.is_empty():
			break
	check(game.onboarding.stage == 7 and session.player_work.totals.cleaned == 1, "clean completion")
	check(game.start_player_work("repair", 2).is_empty(), "repair used room")
	for index in 200:
		game.advance(session.rules.tick)
		if session.player_work.job.is_empty():
			break
	check(game.onboarding.stage == 8 and session.hotel.rooms[1].condition == 100, "repair completion")
	check(game.hire(HotelSession.EMPLOYEES[0]).is_empty() and game.onboarding.stage == 9 and not game.onboarding.active(), "first delegation finishes guide")
	check(session.economy.cash == 2400 + session.economy.revenue - session.economy.expenses - session.economy.capital_spent, "real mobile cash flow")
	var reloaded := _controller("new")
	check(reloaded.boot().is_empty() and reloaded.onboarding.stage == 9 and reloaded.session.player_work.totals.delivered == 1, "completed guide survives reload")
	check(reloaded.saves.app_state.future_module.count == 2, "module updates preserve other application state")
	check(reloaded.onboarding.completed_at.size() == 9, "one timestamp per fact")
	var old := _controller("old")
	var old_session := HotelSession.new(17)
	old_session.economy.cash = 34567
	old.saves.app_state = {}
	check(old.saves.checkpoint(old_session).is_empty(), "legacy mobile fixture")
	check(old.boot().is_empty() and old.session.economy.cash == 34567 and not old.onboarding.enabled, "existing mobile profiles retain wealth and are not forced into guide")
	check(old.set_guide_skipped(false).is_empty() and old.onboarding.active(), "existing player can opt into guide")
	check(old.set_guide_skipped(true).is_empty() and not old.onboarding.active() and old.session.speed == 1, "skip never pauses simulation")
	var envelope: Dictionary = AtomicJSONStore.read(game.saves.path).data
	envelope.app_state.onboarding.stage = 99
	check(not SaveService.restore(envelope).error.is_empty(), "malformed guide rejected")
	envelope = AtomicJSONStore.read(game.saves.path).data
	envelope.app_state.onboarding.completed_at = [1.0]
	check(not SaveService.restore(envelope).error.is_empty(), "partial guide rejected")
	var future_module: Dictionary = AtomicJSONStore.read(game.saves.path).data
	future_module.app_state.onboarding.version = 2
	check(SaveService.restore(future_module).error == "save.error.version", "future guide version cannot be downgraded")
	var file := FileAccess.open(game.saves.path, FileAccess.WRITE)
	file.store_string(JSON.stringify(envelope))
	file.close()
	check(_controller("new").boot().is_empty(), "malformed guide primary recovers automatically from valid backup")
	print(JSON.stringify({"suite": "onboarding", "checks": checks, "failures": failures, "initial_stages": stages, "finished_at": session.time, "cash": session.economy.cash}))
	print("MOBILE_TEST_COMPLETE")
	quit(1 if failures else 0)

func _controller(id: String) -> GameController:
	var saves := SaveService.new()
	saves.path = "user://onboarding-" + id + ".json"
	saves.legacy_path = "user://no-legacy-onboarding.json"
	saves.clock = progress_time.utc
	return GameController.new(saves, progress_time.clock())

func finish_construction(game: GameController, milliseconds: int) -> void:
	var ticks := game.session.tick_count
	var speed := game.session.speed
	game.session.speed = 0
	progress_time.advance(milliseconds)
	game.advance(0.01)
	check(game.construction.jobs.is_empty() and game.session.tick_count == ticks, "construction completes at deadline while simulation is paused")
	game.session.speed = speed

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
