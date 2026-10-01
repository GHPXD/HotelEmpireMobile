extends SceneTree

var failures: int = 0

func _initialize() -> void:
	_test_upgrades()
	_test_tariffs()
	_test_service_contract()
	_test_staff()
	_test_reservations_and_transit()
	_test_migration()
	check(_booking_ticks(true) < _booking_ticks(false), "reception upgrade reduces actual check-in time")
	var baseline: int = _transport_ticks(false)
	var improved: int = _transport_ticks(true)
	check(improved < baseline, "elevator upgrade increases actual throughput")
	print(JSON.stringify({"suite": "management", "failures": failures, "transport_base_ticks": baseline, "transport_upgraded_ticks": improved}))
	quit(1 if failures else 0)

func _test_upgrades() -> void:
	var session := SimulationRunner.make_hotel(44, "standard", 250000)
	_unlock_management(session)
	for room in session.hotel.rooms:
		var definition := room.definition()
		var original_capacity: int = definition.capacity
		var original_price: int = definition.price
		for level in range(2, definition.upgrades.size() + 2):
			var next := room.next_upgrade()
			var cash: int = session.economy.cash
			var capital: int = session.economy.capital_spent
			check(session.upgrade_room(room.id).is_empty(), "upgrade purchase")
			check(room.level == level and session.economy.cash == cash - next.cost and session.economy.capital_spent == capital + next.cost, "upgrade cost charged once")
			check(room.capacity() == original_capacity + next.capacity_bonus and room.price() == original_price + next.price_bonus, "effective stats")
		check(definition.capacity == original_capacity and definition.price == original_price, "shared definitions immutable")
		var cash: int = session.economy.cash
		check(not session.upgrade_room(room.id).is_empty() and session.economy.cash == cash, "max level rejects purchase")
	var expenses: int = session.economy.expenses
	for tick in 1200:
		session.tick(0.1)
	check(session.economy.expenses - expenses == session.recurring_costs().total, "daily expense uses current upgraded room and employee salaries")
	var snapshot := SessionSnapshot.capture(session)
	var restored := SessionSnapshot.restore(JSON.parse_string(JSON.stringify(snapshot)))
	check(restored.error.is_empty(), "upgraded hotel snapshot accepted")
	if restored.session != null:
		var mismatch := preload("res://tests/snapshot_comparison.gd").difference(snapshot, SessionSnapshot.capture(restored.session), "upgrade")
		check(mismatch.is_empty(), "upgrades persist: " + mismatch)
	var broken := snapshot.duplicate(true)
	broken.rooms[0].level = 99
	check(not SessionSnapshot.restore(broken).error.is_empty(), "invalid level rejected")
	var poor := HotelSession.new()
	var room := poor.hotel.build(HotelCatalog.room(&"bedroom"), 0, 0)
	poor.economy.cash = 0
	check(not poor.upgrade_room(room.id).is_empty() and room.level == 1, "unaffordable upgrade leaves state unchanged")

func _test_service_contract() -> void:
	var session := HotelSession.new()
	var room := session.hotel.build(HotelCatalog.room(&"restaurant"), 0, 0)
	var actor := session.spawn_guest()
	actor.state = &"service_queue"
	actor.target_room = room.id
	actor.x = room.center()
	actor.money = room.price()
	session.tick(0.1)
	check(actor.state == &"using" and actor.agreed_price == 28, "price agreed at admission")
	session.upgrade_room(room.id)
	check(session.set_room_tariff(room.id, 125).is_empty(), "change tariff during service")
	var restored := SessionSnapshot.restore(JSON.parse_string(JSON.stringify(SessionSnapshot.capture(session))))
	check(restored.error.is_empty(), "in-flight service survives upgrade/save")
	if restored.session != null:
		session = restored.session
		actor = session.actors[actor.id]
	for tick in 100:
		session.tick(0.1)
		if actor.meals > 0:
			break
	check(actor.money == 0 and session.economy.revenue == 28, "existing guest charged original price")
	var late := session.spawn_guest()
	late.state = &"service_queue"
	late.target_room = room.id
	late.money = 28
	session.tick(0.1)
	check(late.state == &"deciding", "new admission rechecks upgraded price")

func _test_tariffs() -> void:
	var session := HotelSession.new()
	var room := session.hotel.build(HotelCatalog.room(&"restaurant"), 0, 0)
	var reception := session.hotel.build(HotelCatalog.room(&"reception"), 3, 0)
	var cash := session.economy.cash
	check(session.set_room_tariff(room.id, 75).is_empty() and room.price() == 21, "economical service price")
	check(session.economy.cash == cash, "policy change is free")
	check(not session.set_room_tariff(room.id, 80).is_empty() and room.price_percent == 75, "invalid tariff leaves policy unchanged")
	check(not session.set_room_tariff(reception.id, 125).is_empty(), "reception has no tariff")
	check(not session.set_room_tariff(-1, 125).is_empty(), "unknown room rejected")
	var actor := session.spawn_guest()
	actor.state = &"service_queue"
	actor.target_room = room.id
	actor.x = room.center()
	actor.money = 21
	session.tick(0.1)
	check(actor.state == &"using" and actor.agreed_price == 21, "discount enables actual service admission")
	var snapshot := SessionSnapshot.capture(session)
	var restored := SessionSnapshot.restore(JSON.parse_string(JSON.stringify(snapshot)))
	check(restored.error.is_empty(), "discount snapshot valid")
	if restored.session != null:
		check(restored.session.hotel.by_id(room.id).price() == 21, "tariff survives JSON save/load")
	var legacy := snapshot.duplicate(true)
	legacy.version = 4
	for entry: Dictionary in legacy.rooms:
		entry.erase("price_percent")
	var before := JSON.stringify(legacy)
	var migrated := SessionSnapshot.restore(legacy)
	check(migrated.error.is_empty(), "v4 migrates to v5")
	if migrated.session != null:
		check(migrated.session.hotel.by_id(room.id).price_percent == 100, "legacy standard tariff")
	check(JSON.stringify(legacy) == before, "migration preserves input")
	for bad: Variant in [0, 80, 125.5, "75", null]:
		var broken := snapshot.duplicate(true)
		broken.rooms[0].price_percent = bad
		check(not SessionSnapshot.restore(broken).error.is_empty(), "invalid saved tariff rejected")
	var invalid_reception := snapshot.duplicate(true)
	invalid_reception.rooms[1].price_percent = 125
	check(not SessionSnapshot.restore(invalid_reception).error.is_empty(), "saved reception tariff rejected")
	check(session.set_room_tariff(room.id, 125).is_empty() and room.price() == 35, "premium service price")
	var lodging := HotelSession.new()
	lodging.hotel.build(HotelCatalog.room(&"reception"), 0, 0)
	var bedroom := lodging.hotel.build(HotelCatalog.room(&"bedroom"), 3, 0)
	lodging.hire(HotelSession.EMPLOYEES[0])
	var guest := lodging.spawn_guest()
	guest.money = roundi(bedroom.price() * 0.75)
	for tick in 150:
		lodging.tick(0.1)
	check(not guest.checked_in, "standard room beyond guest budget")
	check(lodging.set_room_tariff(bedroom.id, 75).is_empty(), "lower lodging tariff")
	for tick in 100:
		lodging.tick(0.1)
		if guest.checked_in:
			break
	check(guest.checked_in and guest.money == 0 and bedroom.income == bedroom.price(), "discount charged at actual check-in")
	var earned := bedroom.income
	lodging.set_room_tariff(bedroom.id, 125)
	check(bedroom.income == earned and guest.money == 0, "lodging price change never rebills existing occupant")

func _test_staff() -> void:
	var session := HotelSession.new()
	var reception_a := session.hotel.build(HotelCatalog.room(&"reception"), 0, 0)
	var reception_b := session.hotel.build(HotelCatalog.room(&"reception"), 3, 0)
	session.hire(HotelSession.EMPLOYEES[0])
	var receptionist: ActorState = session.actors[1]
	for tick in 50:
		session.tick(0.1)
	check(receptionist.assignment == reception_a.id, "initial automatic assignment")
	check(session.configure_employee(1, reception_b.id).is_empty(), "manual reception accepted")
	for tick in 50:
		session.tick(0.1)
	check(receptionist.assignment == reception_b.id and receptionist.state == &"working", "receptionist reaches manual post")
	session.hire(HotelSession.EMPLOYEES[0])
	check(not session.configure_employee(2, reception_b.id).is_empty(), "duplicate reception assignment rejected")
	session.hotel.add_floor()
	session.hotel.build(HotelCatalog.room(&"elevator"), 15, 0)
	var ground := session.hotel.build(HotelCatalog.room(&"bedroom"), 8, 0)
	var upper := session.hotel.build(HotelCatalog.room(&"bedroom"), 8, 1)
	ground.dirty = true
	upper.dirty = true
	session.hire(HotelSession.EMPLOYEES[1])
	var cleaner: ActorState = session.actors[3]
	for tick in 200:
		session.tick(0.1)
		if cleaner.state == &"cleaning":
			break
	check(cleaner.assignment == ground.id, "cleaner starts first dirty room")
	check(session.configure_employee(cleaner.id, 1).is_empty(), "cleaner floor preference")
	check(cleaner.assignment == ground.id and ground.cleaning_by == cleaner.id, "busy task not cancelled")
	for tick in 500:
		session.tick(0.1)
	check(not ground.dirty and not upper.dirty, "current task finishes then assigned floor serviced")
	ground.dirty = true
	for tick in 100:
		session.tick(0.1)
	check(ground.dirty, "cleaner respects assigned floor")
	check(session.configure_employee(cleaner.id, -1).is_empty(), "return to automatic")
	for tick in 500:
		session.tick(0.1)
	check(not ground.dirty, "automatic routing resumes")
	var restored := SessionSnapshot.restore(JSON.parse_string(JSON.stringify(SessionSnapshot.capture(session))))
	check(restored.error.is_empty() and restored.session.actors[1].preferred_room == reception_b.id, "staff preference persists")
	check(session.demolish(reception_b.id).is_empty(), "idle staffed reception demolition")
	check(receptionist.preferred_room == -1, "demolition clears obsolete post")

func _test_migration() -> void:
	var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/m2-save-v1.json"))
	var encoded := JSON.stringify(original)
	var restored := SessionSnapshot.restore(original)
	check(restored.error.is_empty(), "actual M2 save migrates")
	check(JSON.stringify(original) == encoded, "migration does not mutate source")
	if restored.session != null:
		var session: HotelSession = restored.session
		for room in session.hotel.rooms:
			check(room.level == 1, "legacy room stays level one")
		for tick in 600:
			session.tick(0.1)
		check(SessionSnapshot.restore(SessionSnapshot.capture(session)).error.is_empty(), "migrated save continues and resaves")

func _test_reservations_and_transit() -> void:
	var session := HotelSession.new()
	var first := session.hotel.build(HotelCatalog.room(&"reception"), 0, 0)
	var second := session.hotel.build(HotelCatalog.room(&"reception"), 3, 0)
	session.hire(HotelSession.EMPLOYEES[0])
	session.hire(HotelSession.EMPLOYEES[0])
	check(session.configure_employee(2, first.id).is_empty(), "manual post can be reserved before first tick")
	session.tick(0.1)
	check(session.actors[1].assignment == second.id and session.actors[2].assignment == first.id, "automatic staff respects another employee's reservation")
	session.hotel.add_floor()
	session.hotel.build(HotelCatalog.room(&"elevator"), 12, 0)
	var room := session.hotel.build(HotelCatalog.room(&"bedroom"), 2, 1)
	room.dirty = true
	session.hire(HotelSession.EMPLOYEES[1])
	var cleaner: ActorState = session.actors[3]
	for tick in 200:
		session.tick(0.1)
		if cleaner.state == &"riding":
			break
	check(cleaner.state == &"riding", "cleaner in actual elevator before reassignment")
	check(session.configure_employee(3, 0).is_empty(), "change preference during travel")
	check(cleaner.state == &"riding" and cleaner.assignment == room.id, "travel assignment preserved")
	var restored := SessionSnapshot.restore(JSON.parse_string(JSON.stringify(SessionSnapshot.capture(session))))
	check(restored.error.is_empty(), "pending preference and travel survive save")
	if restored.session != null:
		session = restored.session
		for tick in 400:
			session.tick(0.1)
		check(not session.hotel.by_id(room.id).dirty and session.actors[3].preferred_floor == 0, "current upstairs job completes before ground-floor preference")

func _booking_ticks(upgraded: bool) -> int:
	var session := HotelSession.new()
	var room := session.hotel.build(HotelCatalog.room(&"reception"), 0, 0)
	session.hotel.build(HotelCatalog.room(&"bedroom"), 4, 0)
	session.hire(HotelSession.EMPLOYEES[0])
	if upgraded:
		_unlock_management(session)
		session.upgrade_room(room.id)
		session.upgrade_room(room.id)
	var guest := session.spawn_guest()
	for tick in 200:
		session.tick(0.1)
		if guest.checked_in:
			return tick
	return 9999

func _transport_ticks(upgraded: bool) -> int:
	var session := HotelSession.new()
	session.hotel.add_floor()
	var room := session.hotel.build(HotelCatalog.room(&"elevator"), 5, 0)
	if upgraded:
		_unlock_management(session)
		session.upgrade_room(room.id)
		session.upgrade_room(room.id)
	for id in range(1, 21):
		var actor := ActorState.new()
		actor.id = id
		actor.x = room.center()
		actor.travel_to(4.0, 1, &"idle")
		session.actors[id] = actor
	for tick in 2000:
		session.transport.step(session.actors, 0.1)
		if session.transport.lifts[0].delivered == 20:
			return tick
	return 9999

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _unlock_management(session: HotelSession) -> void:
	session.progression.evaluate({"bookings": 10, "meals": 5, "cleaned": 5, "completed": 20, "reputation": 65})
