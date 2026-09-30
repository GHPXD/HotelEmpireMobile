extends SceneTree

var failures: int = 0

func _initialize() -> void:
	var session := HotelSession.new(63)
	var first_id: int = -1
	for index in 25:
		var guest := session.spawn_guest()
		if index == 5:
			first_id = guest.id
		guest.state = &"exit"
		guest.checked_in = index % 2 == 0
		guest.happiness = 85 if guest.checked_in else 30
		session.tick(0.1)
	check(session.guests.reviews.size() == 20 and session.guests.reviews[0].guest_id == first_id, "bounded history discards oldest departures")
	var latest: Dictionary = session.guests.reviews.back()
	check(latest.checked_in and latest.score == 85 and latest.meals == 0, "review copies actual departure facts")
	var before := SessionSnapshot.capture(session)
	var text := GuestReviewsPanel.describe(latest, session.rules.day_seconds)
	check(text.contains("Consegui me hospedar") and text.contains("Refeições: 0"), "factual text follows record")
	check(SessionSnapshot.capture(session) == before, "formatting never mutates RNG or state")
	var restored := SessionSnapshot.restore(JSON.parse_string(JSON.stringify(before)))
	check(restored.error.is_empty(), "review history loads")
	if restored.session != null:
		var mismatch := preload("res://tests/snapshot_comparison.gd").difference({"reviews": session.guests.reviews}, {"reviews": restored.session.guests.reviews}, "history")
		check(mismatch.is_empty(), "all review fields persist: " + mismatch)
		for tick in 40:
			session.tick(0.1)
			restored.session.tick(0.1)
		check(preload("res://tests/snapshot_comparison.gd").difference(SessionSnapshot.capture(session), SessionSnapshot.capture(restored.session), "reviews").is_empty(), "continued save remains equivalent")
	var legacy := before.duplicate(true)
	legacy.version = 5
	legacy.erase("reviews")
	var original := JSON.stringify(legacy)
	var migrated := SessionSnapshot.restore(legacy)
	check(migrated.error.is_empty() and migrated.session.guests.reviews.is_empty(), "v5 starts without invented history")
	check(JSON.stringify(legacy) == original, "migration does not mutate source")
	for field: String in ["score", "time", "guest_id", "profile", "checked_in", "services"]:
		var broken := before.duplicate(true)
		broken.reviews[0][field] = {"score": 101, "time": -1, "guest_id": 0, "profile": "missing", "checked_in": 1, "services": -1}[field]
		check(not SessionSnapshot.restore(broken).error.is_empty(), "invalid review field rejected: " + field)
	var oversized := before.duplicate(true)
	oversized.reviews.append(latest)
	check(not SessionSnapshot.restore(oversized).error.is_empty(), "oversized history rejected")
	var duplicate := before.duplicate(true)
	duplicate.reviews[1] = duplicate.reviews[0].duplicate()
	check(not SessionSnapshot.restore(duplicate).error.is_empty(), "duplicate guest review rejected")
	_test_visit_times()
	_test_v6_history(before)
	print(JSON.stringify({"suite": "reviews", "failures": failures}))
	quit(1 if failures else 0)

func _test_visit_times() -> void:
	var session := HotelSession.new(64)
	var reception := session.hotel.build(HotelCatalog.room(&"reception"), 0, 0)
	var restaurant := session.hotel.build(HotelCatalog.room(&"restaurant"), 3, 0)
	var guest := session.spawn_guest()
	guest.target_room = reception.id
	guest.state = &"checkin"
	reception.queue.join(guest.id)
	for tick in 3:
		session.guests._check_in(guest, session.actors, session.hotel, session.transport, 0.1, 0.0)
	check(is_equal_approx(guest.reception_seconds, 0.3), "reception measures actual check-in ticks")
	reception.queue.leave(guest.id)
	for visit in 2:
		guest.travel_to(restaurant.center(), 0, &"service_queue")
		guest.state = &"service_queue"
		guest.target_room = restaurant.id
		session.guests._queue_service(guest, session.hotel, 0.1)
		check(guest.state == &"using", "immediate service admission is counted once")
		session.guests._use(guest, session.hotel, 8.0, 0.0)
	check(is_equal_approx(guest.service_queue_seconds, 0.2), "service queue totals accumulate across visits")
	var employee := ActorState.new()
	employee.id = 100
	employee.role = &"cleaner"
	employee.state = &"lift_queue"
	guest.state = &"lift_queue"
	var actors := {guest.id: guest, employee.id: employee}
	for tick in 2:
		session.transport.step(actors, 0.1)
	guest.travel_to(-0.8, 0, &"exit")
	guest.state = &"lift_queue"
	session.transport.step(actors, 0.1)
	check(is_equal_approx(guest.lift_queue_seconds, 0.3), "lift waits survive travel reset and add later episodes")
	check(employee.lift_queue_seconds == 0, "guest history excludes employee lift waits")
	guest.travel_to(-0.8, 0, &"exit")
	guest.state = &"exit"
	session.tick(0.1)
	var review: Dictionary = session.guests.reviews.back()
	check(is_equal_approx(review.reception_seconds, 0.3) and is_equal_approx(review.service_queue_seconds, 0.2) and is_equal_approx(review.lift_queue_seconds, 0.3), "departure copies all accumulated visit times")
	check(GuestReviewsPanel.describe(review, session.rules.day_seconds).contains("Filas de elevador: 0.3s"), "review prints measured wait")

func _test_v6_history(before: Dictionary) -> void:
	var loaded := SessionSnapshot.restore(before)
	var active: ActorState = loaded.session.spawn_guest()
	var legacy := SessionSnapshot.capture(loaded.session)
	legacy.version = 6
	for row: Dictionary in legacy.actors:
		for field: String in ActorState.WAIT_FIELDS:
			row.erase(field)
	for row: Dictionary in legacy.reviews:
		for field: String in ActorState.WAIT_FIELDS:
			row.erase(field)
	var untouched := JSON.stringify(legacy)
	var migrated := SessionSnapshot.restore(legacy)
	check(migrated.error.is_empty(), "v6 reviews and active guests migrate")
	check(JSON.stringify(legacy) == untouched, "v6 migration leaves input unchanged")
	if migrated.session == null:
		return
	var guest: ActorState = migrated.session.actors[active.id]
	check(guest.reception_seconds == -1 and guest.lift_queue_seconds == -1 and guest.service_queue_seconds == -1, "legacy active guest times are unknown")
	check(migrated.session.guests.reviews.back().reception_seconds == null, "existing reviews keep unknown times")
	guest.state = &"exit"
	migrated.session.tick(0.1)
	check(GuestReviewsPanel.describe(migrated.session.guests.reviews.back(), migrated.session.rules.day_seconds).contains("não registrado"), "legacy departure never invents zero waits")
	check(migrated.session.spawn_guest().lift_queue_seconds == 0, "new visitors have measured history after migration")
	var invalid := SessionSnapshot.capture(migrated.session)
	invalid.actors.back().lift_queue_seconds = -0.5
	check(not SessionSnapshot.restore(invalid).error.is_empty(), "invalid active wait rejected")
	for value: Variant in [-1, "zero", INF]:
		invalid = before.duplicate(true)
		invalid.reviews[0].lift_queue_seconds = value
		check(not SessionSnapshot.restore(invalid).error.is_empty(), "invalid recorded wait rejected")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
