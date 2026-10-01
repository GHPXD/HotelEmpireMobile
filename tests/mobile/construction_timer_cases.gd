extends RefCounted
## Paid jobs, reservations, cancellation accounting, boundaries and exact resume.

var checks: int = 0
var failures: int = 0

func run() -> Dictionary:
	_reservations_and_boundaries()
	_cancel_and_budget()
	_vertical_claims_and_floors()
	_upgrade()
	_invalidation()
	_offline_equivalence()
	_corruption()
	_queue_limit()
	return {"suite": "construction_timer", "checks": checks, "failures": failures}

func _hotel() -> HotelSession:
	var session := HotelSession.new(123)
	session.progression.legacy_access = true
	return session

func _build(service: ConstructionService, definition_id: StringName, column: int, floor_index: int = 0, now_ms: int = 0) -> Dictionary:
	var result := service.enqueue_build(HotelCatalog.room(definition_id), column, floor_index, now_ms, 0.0)
	check(result.error.is_empty() and result.job != null, "accept paid job " + String(definition_id))
	return result.job if result.job != null else {}

func _reservations_and_boundaries() -> void:
	var session := _hotel()
	var service := ConstructionService.new(session.hotel)
	var first := _build(service, &"reception", 0)
	var second := _build(service, &"bedroom", 3)
	var third := _build(service, &"bedroom", 5)
	check(first.slot == 0 and second.slot == 1 and third.slot == -1, "two free concurrent slots and FIFO waiting job")
	check(session.hotel.rooms.is_empty() and session.economy.cash == 10000 and session.economy.capital_spent == 2000, "investment charged once before rooms provide service")
	var before := service.snapshot()
	check(service.enqueue_build(HotelCatalog.room(&"bedroom"), 1, 0, 0, 0.0).error == "construction.error.reserved" and service.snapshot() == before, "overlapping blueprint rejected without charge")
	check(service.advance(9999, 0.0).is_empty() and session.hotel.rooms.is_empty(), "no early completion")
	var events := service.advance(10000, 0.0)
	check(events.size() == 1 and events[0].id == first.id and events[0].room_id == 1 and session.hotel.rooms.size() == 1, "first deadline creates one real room")
	check(service.by_id(int(third.id)).start_ms == 10000 and service.by_id(int(third.id)).end_ms == 130000, "waiting job starts on freed boundary, not observation frame")
	check(service.advance(20000, 0.0).size() == 1 and session.hotel.rooms.size() == 2, "second slot finishes independently")
	check(service.advance(130000, 0.0).size() == 1 and service.jobs.is_empty() and service.completed == 3, "FIFO job completes after its own full duration")
	check(session.economy.cash == 10000 and session.economy.revenue == 0 and session.economy.expenses == 0, "completion does not debit twice or manufacture operating income")
	var completed := SessionSnapshot.capture(session)
	check(service.advance(130000, 0.0).is_empty() and SessionSnapshot.capture(session) == completed, "duplicate deadline observation has no effect")
	check(service.take_events().size() == 3 and service.take_events().is_empty(), "completion feedback drains once")
	check(service.restore(JSON.parse_string(JSON.stringify(service.snapshot())), 130000), "completed job history round-trips")

func _cancel_and_budget() -> void:
	var session := _hotel()
	var service := ConstructionService.new(session.hotel)
	var first := _build(service, &"reception", 0)
	_build(service, &"bedroom", 3)
	var third := _build(service, &"bedroom", 5)
	check(service.cancel(int(first.id), 5000, 0.0).is_empty(), "active job can be cancelled")
	check(session.economy.cash == 10800 and session.economy.capital_spent == 1200 and session.economy.profit() == 0, "full investment refund changes capital, never revenue")
	check(service.by_id(int(third.id)).start_ms == 5000 and not service.reserved(HotelCatalog.room(&"reception"), 0, 0), "cancellation releases slot and cells immediately")
	var cash := session.economy.cash
	check(service.cancel(int(first.id), 5000, 0.0) == "construction.error.missing" and session.economy.cash == cash, "duplicate cancel cannot duplicate refund")
	var before := service.snapshot()
	check(service.cancel(int(third.id), -1, 0.0) == "save.error.invalid" and service.advance(-1, 0.0).is_empty() and service.snapshot() == before, "time rollback cannot mutate or cancel jobs")
	check(not session.economy.refund_capital(1201, "invalid", 0.0) and session.economy.cash == cash, "refund cannot exceed net invested capital")
	var poor := _hotel()
	poor.economy.cash = 700
	var unavailable := ConstructionService.new(poor.hotel)
	check(not unavailable.enqueue_build(HotelCatalog.room(&"reception"), 0, 0, 0, 0.0).error.is_empty() and unavailable.jobs.is_empty() and poor.economy.cash == 700, "unaffordable investment creates no job")
	check(not unavailable.enqueue_build(HotelCatalog.room(&"bedroom"), 0, 0, ProgressClock.MAX_TIMESTAMP_MS - 1, 0.0).error.is_empty() and poor.economy.cash == 700, "deadline overflow creates no payment")

func _vertical_claims_and_floors() -> void:
	var session := _hotel()
	check(session.hotel.add_floor().is_empty(), "fixture upper floor")
	var service := ConstructionService.new(session.hotel)
	_build(service, &"elevator", 15)
	check(service.enqueue_build(HotelCatalog.room(&"bedroom"), 14, 1, 0, 0.0).error == "construction.error.reserved", "pending shaft reserves cells on every floor")
	_build(service, &"bedroom", 8, 1)
	check(service.advance(60000, 0.0).size() == 2 and session.hotel.room_at(15, 1) != null, "completed shaft and upper room become actual hotel state")
	var expanding := _hotel()
	var floors := ConstructionService.new(expanding.hotel)
	var a := floors.enqueue_floor(0, 0.0)
	var b := floors.enqueue_floor(0, 0.0)
	check(a.error.is_empty() and b.error.is_empty() and a.job.slot == 0 and b.job.slot == -1 and expanding.hotel.floors == 1, "floor successors wait for their structural dependency")
	check(floors.cancel(int(a.job.id), 0, 0.0) == "construction.error.dependent", "cannot cancel a floor with dependent investments")
	check(floors.restore(JSON.parse_string(JSON.stringify(floors.snapshot())), 0), "dependent floor queue round-trips")
	check(floors.advance(200000, 0.0).size() == 2 and expanding.hotel.floors == 3 and expanding.tick_count == 0, "long absence completes dependent floors without simulation ticks")
	check(expanding.economy.capital_spent == 1500 and expanding.economy.cash == 10500, "floor completion has no second purchase")

func _upgrade() -> void:
	var session := _hotel()
	var room := session.hotel.build(HotelCatalog.room(&"bedroom"), 0, 0)
	var service := ConstructionService.new(session.hotel)
	var cost := room.next_upgrade().cost
	var previous_cash := session.economy.cash
	var duration := room.duration()
	var result := service.enqueue_upgrade(room.id, 0, 0.0)
	check(result.error.is_empty() and room.level == 1 and room.duration() == duration and session.economy.cash == previous_cash - cost, "upgrade reserves investment while old service remains operational")
	check(service.enqueue_upgrade(room.id, 0, 0.0).error == "construction.error.upgrading" and session.economy.cash == previous_cash - cost, "one upgrade per room prevents duplicate investment")
	check(service.advance(59999, 0.0).is_empty() and room.level == 1, "upgrade benefits wait for deadline")
	check(service.advance(60000, 0.0).size() == 1 and room.level == 2 and room.price() == 175 and room.satisfaction_bonus() == 2.0 and room.duration() == duration and session.economy.cash == previous_cash - cost, "bedroom upgrade applies its authored comfort/tariff once at completion")
	result = service.enqueue_upgrade(room.id, 60000, 0.0)
	check(result.error.is_empty() and service.cancel(int(result.job.id), 60000, 0.0).is_empty() and room.level == 2 and session.economy.cash == previous_cash - cost, "cancelling next upgrade restores only its own investment")

func _policy(service: ConstructionService) -> void:
	_build(service, &"reception", 0)
	for column in [3, 5, 7, 9]:
		_build(service, &"bedroom", column)

func _invalidation() -> void:
	var session := _hotel()
	var service := ConstructionService.new(session.hotel)
	var job := _build(service, &"reception", 0)
	var cash := session.economy.cash
	# A trusted authoring operation replaces the reserved geometry. The runtime
	# adapter will prevent this; core still must not create duplicates or lose Cash.
	check(session.hotel.finish_build(HotelCatalog.room(&"reception"), 0, 0) != null, "fixture invalidates pending geometry")
	var events := service.advance(10000, 0.0)
	check(events.size() == 1 and events[0].error == "construction.error.invalidated" and service.cancelled == 1 and service.completed == 0, "invalidated completion does not count as a completed investment")
	check(session.hotel.rooms.size() == 1 and session.economy.cash == cash + 800 and session.economy.capital_spent == 0 and session.economy.profit() == 0, "invalidated job refunds held capital exactly once")
	check(service.cancel(int(job.id), 10000, 0.0) == "construction.error.missing" and service.advance(10000, 0.0).is_empty(), "invalidated job cannot refund again")

func _offline_equivalence() -> void:
	var online := _hotel()
	var offline := _hotel()
	var a := ConstructionService.new(online.hotel)
	var b := ConstructionService.new(offline.hotel)
	_policy(a)
	_policy(b)
	a.advance(5000, 0.0)
	var saved := a.snapshot()
	var restored := SessionSnapshot.restore(JSON.parse_string(JSON.stringify(SessionSnapshot.capture(online))))
	check(restored.error.is_empty(), "hotel with held construction investment restores")
	var c := ConstructionService.new(restored.session.hotel)
	check(c.restore(JSON.parse_string(JSON.stringify(saved)), 300000), "unfinished queue restores before aggregate completion")
	for second in range(6, 301):
		a.advance(second * 1000, 0.0)
	check(b.advance(300000, 0.0).size() == 5 and c.advance(300000, 0.0).size() == 5, "single absence processes entire FIFO chain")
	check(SessionSnapshot.capture(online) == SessionSnapshot.capture(offline) and SessionSnapshot.capture(online) == SessionSnapshot.capture(restored.session), "online, offline and restarted hotel states are identical")
	check(a.snapshot() == b.snapshot() and b.snapshot() == c.snapshot(), "queue counters and timing are identical across settlement strategies")
	check(online.tick_count == 0 and offline.tick_count == 0, "construction settlement is independent of simulation catch-up")

func _reject(service: ConstructionService, data: Variant, now_ms: int = 0) -> void:
	var before := service.snapshot()
	check(not service.restore(data, now_ms), "contradictory persisted jobs rejected")
	check(service.snapshot() == before, "failed restore leaves live queue intact")

func _corruption() -> void:
	var session := _hotel()
	var service := ConstructionService.new(session.hotel)
	_build(service, &"reception", 0)
	_build(service, &"bedroom", 3)
	_build(service, &"bedroom", 5)
	var saved := service.snapshot()
	check(service.restore(JSON.parse_string(JSON.stringify(saved)), 0), "active/waiting mixed queue restores exactly")
	for value: Variant in [null, [], {}, {"version": 2}]:
		_reject(service, value)
	for field: String in ["version", "next_id", "completed", "cancelled", "last_ms", "jobs"]:
		var corrupt := saved.duplicate(true)
		corrupt.erase(field)
		_reject(service, corrupt)
	for field: String in ConstructionService.JOB_FIELDS:
		var corrupt := saved.duplicate(true)
		corrupt.jobs[0].erase(field)
		_reject(service, corrupt)
	for mutation: Dictionary in [{"field": "slot", "value": 2}, {"field": "slot", "value": -0.5}, {"field": "cost", "value": -1}, {"field": "cost", "value": 1000000000}, {"field": "duration_ms", "value": 0}, {"field": "end_ms", "value": 9999}, {"field": "accepted_ms", "value": 1}, {"field": "definition_id", "value": "unknown"}, {"field": "kind", "value": "purchase"}, {"field": "column", "value": -1}, {"field": "room_id", "value": 1}, {"field": "target_level", "value": 2}]:
		var corrupt := saved.duplicate(true)
		corrupt.jobs[0][mutation.field] = mutation.value
		_reject(service, corrupt)
	var corrupt := saved.duplicate(true)
	corrupt.jobs[1].slot = 0
	_reject(service, corrupt)
	corrupt = saved.duplicate(true)
	corrupt.jobs[1].column = 1
	_reject(service, corrupt)
	corrupt = saved.duplicate(true)
	corrupt.jobs[2].start_ms = 0
	_reject(service, corrupt)
	corrupt = saved.duplicate(true)
	corrupt.next_id = 5
	_reject(service, corrupt)
	corrupt = saved.duplicate(true)
	corrupt.jobs[1].id = 1
	_reject(service, corrupt)

func _queue_limit() -> void:
	var session := _hotel()
	check(session.hotel.add_floor().is_empty(), "fixture capacity floor")
	var service := ConstructionService.new(session.hotel)
	for index in ConstructionService.RULES.queue_limit:
		_build(service, &"bedroom", (index % 8) * 2, int(index / 8.0))
	var before := session.economy.cash
	check(service.enqueue_build(HotelCatalog.room(&"bedroom"), 8, 1, 0, 0.0).error == "construction.error.queue_full" and session.economy.cash == before, "queue limit rejects further payment")
	check(service.advance(14400000, 0.0).size() == 12 and service.completed == 12 and service.jobs.is_empty() and session.hotel.rooms.size() == 12, "bounded queue completes during a long absence")
	check(session.economy.cash == before and session.tick_count == 0, "full queue does not generate hidden costs or ticks")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
