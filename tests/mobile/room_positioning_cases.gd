extends RefCounted
## Authored late-game fixtures verify positioning, never paid-store behavior.

var checks: int = 0
var failures: int = 0

func run() -> Dictionary:
	_levels_and_gates()
	_stat_matrix()
	_audience_and_admission()
	_contract_and_migrations()
	_jobs_and_accounting()
	_application_and_future_versions()
	var study := _study()
	return {"suite": "room_positioning", "checks": checks, "failures": failures, "study": study}

func _hotel(seed_value: int = 123) -> HotelSession:
	var session := HotelSession.new(seed_value)
	session.economy.cash = 100000
	session.progression.evaluate({"bookings": 10, "meals": 5, "cleaned": 5, "completed": 20, "reputation": 65})
	session.hotel.build(HotelCatalog.room(&"reception"), 0, 0)
	for column in [3, 5, 7]:
		var room := session.hotel.build(HotelCatalog.room(&"bedroom"), column, 0)
		for _level in 2:
			check(session.upgrade_room(room.id).is_empty(), "fixture purchases real N2/N3")
	return session

func _levels_and_gates() -> void:
	for definition_id: StringName in [&"bedroom", &"reception", &"restaurant"]:
		var session := HotelSession.new()
		session.economy.cash = 100000
		var room := session.hotel.build(HotelCatalog.room(definition_id), 0, 0)
		check(room.definition().upgrades.size() == 4, "primary room has N1–N5")
		check(session.upgrade_room(room.id).is_empty() and room.level == 2, "N2 has no new objective gate")
		var before := SessionSnapshot.capture(session)
		check(not session.upgrade_room(room.id).is_empty() and SessionSnapshot.capture(session) == before, "locked N3 cannot charge or mutate")
		if definition_id == &"restaurant":
			session.progression.evaluate({"bookings": 10, "meals": 5, "cleaned": 5})
		else:
			session.progression.evaluate({"bookings": 3})
		check(session.upgrade_room(room.id).is_empty() and room.level == 3, "existing N3 unlock preserved")
		if definition_id != &"restaurant":
			before = SessionSnapshot.capture(session)
			check(not session.upgrade_room(room.id).is_empty() and SessionSnapshot.capture(session) == before, "N4 requires actual steady service")
		session.progression.evaluate({"bookings": 10, "meals": 5, "cleaned": 5})
		check(session.upgrade_room(room.id).is_empty() and room.level == 4, "N4 unlocks with steady service")
		before = SessionSnapshot.capture(session)
		check(not session.upgrade_room(room.id).is_empty() and SessionSnapshot.capture(session) == before, "N5 requires trusted hotel")
		session.progression.evaluate({"completed": 20, "reputation": 65})
		check(session.upgrade_room(room.id).is_empty() and room.level == 5, "N5 unlocks with trusted hotel")
		before = SessionSnapshot.capture(session)
		check(not session.upgrade_room(room.id).is_empty() and SessionSnapshot.capture(session) == before, "true maximum rejects duplicate payment")
		check(SessionSnapshot.restore(before).error.is_empty(), "all installed tiers validate against progression")
		var broken := before.duplicate(true)
		broken.progression.completed.pop_back()
		check(not SessionSnapshot.restore(broken).error.is_empty(), "forged N5 with missing objective rejected")
		broken = before.duplicate(true)
		broken.rooms[0].level = 4
		broken.progression.completed = ["first_stays"]
		broken.progression.legacy_access = true
		check(not SessionSnapshot.restore(broken).error.is_empty(), "legacy N3 grant cannot bypass installed N4 gate")
	var legacy := HotelSession.new()
	legacy.progression.legacy_access = true
	var room := legacy.hotel.build(HotelCatalog.room(&"bedroom"), 0, 0)
	legacy.upgrade_room(room.id)
	legacy.upgrade_room(room.id)
	check(room.level == 3 and not legacy.upgrade_room(room.id).is_empty(), "legacy access grants only historical N3")
	check(room.specialization_error(&"comfort", legacy.progression) == "specialization.error.locked", "legacy grant does not invent specialization objective")
	check(HotelCatalog.room(&"elevator").upgrades.size() == 2 and HotelCatalog.room(&"cafe").upgrades.is_empty() and HotelCatalog.room(&"lounge").upgrades.is_empty(), "auxiliary rooms keep existing meaningful tiers")

func _stat_matrix() -> void:
	var session := _hotel()
	var room := session.hotel.by_id(2)
	var expected := {"": [0, 0, 0.0, 1.0], "executive": [30, 6, 0.0, 0.9], "comfort": [10, 4, 4.0, 1.15], "economy": [-25, -6, -1.0, 0.85]}
	for level in [3, 4, 5]:
		room.level = level
		for specialization_id: String in expected:
			room.specialization_id = StringName(specialization_id)
			var row: Array = expected[specialization_id]
			for percent in [75, 100, 125]:
				room.price_percent = percent
				var base_price: int = {3: 210, 4: 230, 5: 260}[level]
				var base_maintenance: int = {3: 17, 4: 14, 5: 18}[level]
				var base_quality: float = {3: 4.0, 4: 6.0, 5: 8.0}[level]
				check(room.price() == roundi((base_price + int(row[0])) * percent / 100.0) and room.maintenance() == base_maintenance + int(row[1]), "authored price/maintenance matrix %d/%s/%d" % [level, specialization_id, percent])
				check(is_equal_approx(room.satisfaction_bonus(), base_quality + float(row[2])) and is_equal_approx(room.stay_multiplier(), float(row[3])) and room.capacity() == 1, "quality/stay tradeoff preserves capacity")
	room.specialization_id = &"executive"
	room.level = 5
	room.price_percent = 125
	check(room.price() == 363 and room.price() > HotelCatalog.guest(&"balanced").budget and room.price() <= HotelCatalog.guest(&"business").budget, "premium executive budget threshold is a real tradeoff")
	for definition_id: StringName in [&"reception", &"restaurant"]:
		var space := RoomState.new()
		space.definition_id = definition_id
		for level in [4, 5]:
			space.level = level
			var rec := definition_id == &"reception"
			check(space.maintenance() == ({4: 26, 5: 30}[level] if rec else {4: 38, 5: 46}[level]), "N4/N5 upkeep applies at room level")
			check(is_equal_approx(space.duration(), ({4: 1.6, 5: 1.2}[level] if rec else {4: 5.2, 5: 4.8}[level])) and space.capacity() == (1 if rec else level + 2), "N4/N5 actual service throughput")
	check(HotelCatalog.room(&"bedroom").price == 140 and HotelCatalog.room(&"bedroom").maintenance == 8, "positioning never mutates shared baseline Resource")

func _audience_and_admission() -> void:
	var session := _hotel()
	var ids := [&"executive", &"comfort", &"economy"]
	for index in 3:
		session.hotel.rooms[index + 1].specialization_id = ids[index]
	for profile_id: StringName in [&"business", &"leisure", &"balanced"]:
		var actor := session.spawn_guest()
		actor.archetype_id = profile_id
		actor.money = actor.archetype().budget
		var state := session.rng.state
		var bed := session.guests.available_bed(actor, session.hotel, session.transport)
		var expected: StringName = {&"business": &"executive", &"leisure": &"comfort", &"balanced": &"economy"}[profile_id]
		check(bed != null and bed.specialization_id == expected and session.rng.state == state, "eligible audience preference without extra RNG")
		bed.dirty = true
		check(session.guests.available_bed(actor, session.hotel, session.transport) != bed, "dirty preferred room excluded before preference")
		bed.dirty = false
		bed.repairing_by = actor.id
		check(session.guests.available_bed(actor, session.hotel, session.transport) != bed, "repair reservation excluded")
		bed.repairing_by = -1
		actor.money = bed.price() - 1
		check(session.guests.available_bed(actor, session.hotel, session.transport) != bed, "unaffordable preferred room excluded")
		actor.money = bed.price()
		check(session.guests.available_bed(actor, session.hotel, session.transport) == bed, "exact budget admits preferred room")
	for bed in session.hotel.rooms:
		bed.specialization_id = &""
	var first: ActorState = session.actors[1]
	first.money = 1000
	check(session.guests.available_bed(first, session.hotel, session.transport).id == 2, "neutral hotel preserves original build order")
	var reception := session.hotel.by_id(1)
	reception.level = 4
	var bedroom := session.hotel.by_id(2)
	bedroom.specialization_id = &"executive"
	first.archetype_id = &"business"
	first.state = &"checkin"
	first.target_room = reception.id
	first.happiness = 50
	reception.queue.join(first.id)
	var cash := session.economy.cash
	var budget := first.money
	check(session.guests.admit(first, session.hotel, session.transport, 0.0) and first.bedroom == bedroom.id, "actual admission follows audience selection")
	check(first.money == budget - 240 and session.economy.cash == cash + 240 and bedroom.income == 240 and session.guests.bookings == 1, "one lodging payment, same debit and credit")
	check(first.happiness == 56 and is_equal_approx(first.lodging_stay_multiplier, 0.9), "executive admission +4 and N4 reception +2")
	check(not session.guests.admit(first, session.hotel, session.transport, 0.0) and session.economy.cash == cash + 240, "duplicate admission cannot rebill")
	bedroom.condition = 90
	check(bedroom.arrival_bonus(first.archetype()) == 4, "executive meets minimum condition exactly")
	bedroom.condition = 89
	check(bedroom.arrival_bonus(first.archetype()) == -4, "executive condition below 90 applies documented penalty")
	bedroom.specialization_id = &"comfort"
	first.state = &"using"
	first.target_room = bedroom.id
	first.timer = 0
	first.happiness = 50
	bedroom.users.append(first.id)
	session.guests._use(first, session.hotel, 0.1, 0.0)
	check(first.happiness == 61 and first.sleeps == 1 and first.lodging_stay_multiplier == 0.9, "comfort increases actual sleep quality while old contract persists")

func _contract_and_migrations() -> void:
	var session := _hotel()
	var bedroom := session.hotel.by_id(2)
	bedroom.specialization_id = &"comfort"
	var reception := session.hotel.by_id(1)
	var guest := session.spawn_guest()
	guest.archetype_id = &"balanced"
	guest.state = &"checkin"
	guest.target_room = reception.id
	reception.queue.join(guest.id)
	check(session.guests.admit(guest, session.hotel, session.transport, 0), "contract fixture books comfort")
	bedroom.specialization_id = &"economy"
	var data := SessionSnapshot.capture(session)
	var restored := SessionSnapshot.restore(JSON.parse_string(JSON.stringify(data)))
	check(restored.error.is_empty(), "renovation with old occupant contract survives JSON")
	if restored.session != null:
		session = restored.session
		guest = session.actors[guest.id]
		check(guest.lodging_stay_multiplier == 1.15 and session.hotel.by_id(2).stay_multiplier() == 0.85, "contract remains independent from current positioning after restart")
		guest.age = 114.9
		session.guests._choose(guest, session.hotel, session.transport)
		check(guest.destination_state != &"exit" and guest.bedroom == 2, "old contract does not leave at new economy deadline")
		guest.age = 115.0
		session.guests._choose(guest, session.hotel, session.transport)
		check(guest.destination_state == &"exit" and guest.bedroom == -1, "old contract leaves on its exact deadline")
	var old := data.duplicate(true)
	old.version = 9
	for room_data: Dictionary in old.rooms:
		room_data.erase("specialization_id")
	for actor_data: Dictionary in old.actors:
		actor_data.erase("lodging_stay_multiplier")
	var original := JSON.stringify(old)
	var migrated := SessionSnapshot.restore(old)
	check(migrated.error.is_empty() and JSON.stringify(old) == original, "v9 migration accepts and preserves original document")
	if migrated.session != null:
		check(migrated.session.hotel.by_id(2).specialization_id.is_empty() and migrated.session.actors[guest.id].lodging_stay_multiplier == 1.0, "legacy contracts retain neutral baseline")
	for invalid: Variant in ["unknown", 42, null]:
		var broken := data.duplicate(true)
		broken.rooms[1].specialization_id = invalid
		check(not SessionSnapshot.restore(broken).error.is_empty(), "invalid saved specialization rejected")
	for mutation: String in ["missing", "level", "objective"]:
		var broken := data.duplicate(true)
		match mutation:
			"missing": broken.rooms[1].erase("specialization_id")
			"level": broken.rooms[1].level = 2
			"objective": broken.progression.completed = []
		check(not SessionSnapshot.restore(broken).error.is_empty(), "invalid saved positioning relation: " + mutation)
	for invalid: Variant in [0.0, 0.84, 1.16, true, "1.15", null, NAN, INF]:
		var broken := data.duplicate(true)
		broken.actors[0].lodging_stay_multiplier = invalid
		check(not SessionSnapshot.restore(broken).error.is_empty(), "invalid contracted stay factor rejected")
	var missing := data.duplicate(true)
	missing.actors[0].erase("lodging_stay_multiplier")
	check(not SessionSnapshot.restore(missing).error.is_empty(), "current schema requires explicit stay contract")

func _jobs_and_accounting() -> void:
	var session := _hotel()
	var service := ConstructionService.new(session.hotel)
	var cash := session.economy.cash
	var capital := session.economy.capital_spent
	var result := service.enqueue_specialization(2, &"comfort", 0, 0)
	check(result.error.is_empty() and result.job.kind == "specialize" and result.job.specialization_id == "comfort", "specialization is an actual constructor job")
	check(session.economy.cash == cash - 550 and session.economy.capital_spent == capital + 550 and session.hotel.by_id(2).specialization_id.is_empty(), "pay once, preserve old positioning until deadline")
	var paid := SessionSnapshot.capture(session)
	var queue := service.snapshot()
	for invalid: StringName in [&"", &"unknown", &"economy"]:
		check(not service.enqueue_specialization(2, invalid, 0, 0).error.is_empty() and SessionSnapshot.capture(session) == paid and service.snapshot() == queue, "overlapping renovation rejected atomically")
	check(service.enqueue_upgrade(2, 0, 0).error == "construction.error.upgrading", "upgrade and specialization share exclusive room job")
	check(service.advance(299999, 0).is_empty() and session.hotel.by_id(2).specialization_id.is_empty(), "five-minute renovation cannot complete 1ms early")
	var restored := ConstructionService.new(session.hotel)
	check(restored.restore(JSON.parse_string(JSON.stringify(service.snapshot())), 299999), "pending new job survives JSON")
	check(restored.advance(300000, 0).size() == 1 and session.hotel.by_id(2).specialization_id == &"comfort" and restored.completed == 1, "exact deadline applies positioning once")
	check(restored.advance(300001, 0).is_empty() and session.tick_count == 0 and session.economy.cash == cash - 550, "completion does not manufacture ticks or charges")
	check(restored.enqueue_specialization(2, &"comfort", 300001, 0).error == "specialization.error.current" and restored.enqueue_specialization(2, &"", 300001, 0).error == "specialization.error.invalid", "current and blank choices rejected before payment")
	var change := restored.enqueue_specialization(2, &"economy", 300001, 0)
	check(change.error.is_empty() and session.hotel.by_id(2).specialization_id == &"comfort", "paid reconfiguration keeps current branch during renovation")
	check(restored.cancel(int(change.job.id), 300002, 0).is_empty() and session.economy.cash == cash - 550 and session.economy.capital_spent == capital + 550, "cancel returns only renovation capital")
	check(restored.cancel(int(change.job.id), 300002, 0) == "construction.error.missing" and session.economy.cash == cash - 550, "repeat cancel cannot duplicate refund")
	var first := restored.enqueue_specialization(2, &"executive", 300002, 0)
	var second := restored.enqueue_specialization(3, &"comfort", 300002, 0)
	var third := restored.enqueue_specialization(4, &"economy", 300002, 0)
	check(first.job.slot == 0 and second.job.slot == 1 and third.job.slot == -1, "specializations use two free crews and FIFO")
	check(restored.acceleration_error(int(third.job.id), 300000, 300002) == "speedup.error.queued", "queued renovation cannot consume speedup")
	var inventory := PlayerInventory.new()
	inventory.claim_reward(&"welcome")
	var plan := ConstructionSpeedupPlan.prepare(session, restored, inventory, OnboardingService.new(), {}, {"version": 1}, int(first.job.id), &"5m", inventory.next_operation_id(), 300002)
	check(plan.error.is_empty() and plan.session.hotel.by_id(2).specialization_id == &"executive" and session.hotel.by_id(2).specialization_id == &"comfort", "durable speedup candidate supports new job without mutating live positioning")
	check(restored.accelerate(int(first.job.id), 300000, 300002, 0).error.is_empty() and restored.by_id(int(third.job.id)).start_ms == 300002, "speedup finishes renovation and starts waiting work at current instant")
	check(restored.advance(600002, 0).size() == 2 and session.economy.cash + session.economy.capital_spent + session.economy.expenses - session.economy.revenue == 100000, "all branches conserve initial fixture wealth")
	var old_service := ConstructionService.new(session.hotel)
	check(old_service.enqueue_upgrade(2, 600002, 0).error.is_empty(), "v1 migration fixture has valid paid upgrade")
	var old := old_service.snapshot()
	old.version = 1
	for job: Dictionary in old.jobs:
		job.erase("specialization_id")
	var original := JSON.stringify(old)
	var migrated := ConstructionService.new(session.hotel)
	check(migrated.restore(old, 600002) and JSON.stringify(old) == original and migrated.jobs[0].specialization_id == "", "construction v1 migrates without mutating paid job source")
	check(migrated.jobs[0].id == old.jobs[0].id and migrated.jobs[0].cost == old.jobs[0].cost and migrated.jobs[0].end_ms == old.jobs[0].end_ms, "migration retains IDs, capital and deadline")
	var bad := old_service.snapshot()
	bad.jobs[0].specialization_id = "comfort"
	check(not migrated.restore(bad, 600002), "non-specialization job cannot carry a branch")

func _application_and_future_versions() -> void:
	var time_source: RefCounted = preload("res://tests/mobile/fake_progress_time.gd").new()
	var saves := SaveService.new()
	saves.path = "user://positioning.json"
	saves.legacy_path = "user://no-legacy-positioning.json"
	saves.clock = time_source.utc
	var game := GameController.new(saves, time_source.clock())
	game.enable_onboarding = false
	check(game.boot().is_empty(), "application fixture boots")
	game.session = _hotel()
	game.construction = ConstructionService.new(game.session.hotel)
	check(game.specialize(2, &"comfort").is_empty(), "semantic application command creates durable specialization")
	check(game.demolish(2) == "construction.error.upgrading", "pending specialization blocks demolition through application")
	var saved: Dictionary = AtomicJSONStore.read(saves.path).data
	check(SaveService.restore(saved).error.is_empty() and saved.app_state.construction.jobs[0].specialization_id == "comfort", "hotel and renovation are saved together")
	var ticks := game.session.tick_count
	game.enter_background()
	time_source.advance(300000)
	game = GameController.new(saves, time_source.clock())
	game.enable_onboarding = false
	check(game.boot().is_empty() and game.session.hotel.by_id(2).specialization_id == &"comfort" and game.session.tick_count == ticks and game.return_construction.size() == 1, "OS recreation settles specialization without simulation catch-up")
	var future: Dictionary = AtomicJSONStore.read(saves.path).data
	future.hotel.version = SessionSnapshot.VERSION + 1
	check(SaveService.restore(future).error == "save.error.version", "future domain schema classified before recovery")
	var file := FileAccess.open(saves.path, FileAccess.WRITE)
	file.store_string(JSON.stringify(future))
	file.close()
	check(saves.boot().error == "save.error.version" and saves.write_blocked and AtomicJSONStore.read(saves.path).data.hotel.version == SessionSnapshot.VERSION + 1, "newer primary cannot silently downgrade to older backup")

func _study() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for seed_value in [17, 44, 123, 902, 2026]:
		for specialization_id: StringName in [&"", &"executive", &"comfort", &"economy"]:
			var session := _hotel(seed_value)
			var service := ConstructionService.new(session.hotel)
			if not specialization_id.is_empty():
				for id in [2, 3, 4]:
					check(service.enqueue_specialization(id, specialization_id, 0, 0).error.is_empty(), "study pays authored renovation cost")
				service.advance(600000, 0)
			session.hotel.build(HotelCatalog.room(&"restaurant"), 10, 0)
			session.hire(HotelSession.EMPLOYEES[0])
			session.hire(HotelSession.EMPLOYEES[1])
			session.opened = true
			var rest: HotelSession
			var observed: Dictionary = {}
			var profiles: Dictionary = {}
			var previous_completed := 0
			for tick in 6000:
				session.tick(0.1)
				if session.guests.completed != previous_completed:
					previous_completed = session.guests.completed
					for review in session.guests.reviews:
						if observed.has(review.guest_id):
							continue
						observed[review.guest_id] = true
						var profile: String = review.profile
						if not profiles.has(profile):
							profiles[profile] = {"visits": 0, "stayed": 0, "stayed_score_total": 0.0, "stayed_sleeps": 0}
						profiles[profile].visits += 1
						if review.checked_in:
							profiles[profile].stayed += 1
							profiles[profile].stayed_score_total += float(review.score)
							profiles[profile].stayed_sleeps += int(review.sleeps)
				if tick == 2999:
					var resumed := SessionSnapshot.restore(JSON.parse_string(JSON.stringify(SessionSnapshot.capture(session))))
					check(resumed.error.is_empty(), "study mid-run snapshot validates")
					rest = resumed.session
				elif tick >= 3000 and rest != null:
					rest.tick(0.1)
			var mismatch := "restore failed" if rest == null else preload("res://tests/snapshot_comparison.gd").difference(SessionSnapshot.capture(session), SessionSnapshot.capture(rest), "positioning-study")
			check(mismatch.is_empty(), "fixed-seed restart yields identical outcome: " + mismatch)
			check(session.economy.cash + session.economy.capital_spent + session.economy.expenses - session.economy.revenue == 100000 and session.guests.bookings > 0 and session.employees.cleaned > 0, "study preserves accounting under actual service and cleaning")
			check(observed.size() == session.guests.completed, "observer captures every departure despite bounded product review history")
			result.append({"seed": seed_value, "branch": String(specialization_id), "horizon_seconds": 600, "fixture_cash": 100000, "bookings": session.guests.bookings, "completed": session.guests.completed, "revenue": session.economy.revenue, "expenses": session.economy.expenses, "profit": session.economy.profit(), "cleaned": session.employees.cleaned, "reputation": session.guests.reputation, "all_departures_by_profile": profiles})
	return result

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
