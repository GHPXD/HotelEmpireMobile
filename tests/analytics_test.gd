extends SceneTree

var failures: int = 0

func _initialize() -> void:
	var session := HotelSession.new()
	var empty := HotelAnalytics.summary(session)
	check(empty.beds == 0 and empty.occupancy == 0 and empty.happiness == 0, "empty hotel has finite zero metrics")
	check(empty.satisfaction_groups.checked_in.count == 0 and empty.satisfaction_groups.not_checked_in.count == 0, "empty cohorts have no observations")
	var reception := session.hotel.build(HotelCatalog.room(&"reception"), 0, 0)
	session.hotel.add_floor()
	var bed_a := session.hotel.build(HotelCatalog.room(&"bedroom"), 0, 1)
	var bed_b := session.hotel.build(HotelCatalog.room(&"bedroom"), 2, 1)
	var shaft := session.hotel.build(HotelCatalog.room(&"elevator"), 8, 0)
	bed_a.dirty = true
	var guest := session.spawn_guest()
	guest.happiness = 60
	guest.state = &"checkin"
	guest.target_room = reception.id
	guest.waiting = 12.5
	reception.queue.join(guest.id)
	var other := session.spawn_guest()
	other.happiness = 80
	other.checked_in = true
	other.state = &"using"
	other.bedroom = bed_b.id
	other.target_room = bed_b.id
	bed_b.occupant = other.id
	bed_b.users.append(other.id)
	session.hire(HotelSession.EMPLOYEES[0])
	var passenger := session.spawn_guest()
	passenger.state = &"lift_queue"
	passenger.elevator_id = shaft.id
	passenger.happiness = 70
	passenger.waiting = 8
	session.transport.lifts[0].queue.join(passenger.id)
	var before := SessionSnapshot.capture(session)
	var metrics := HotelAnalytics.summary(session)
	check(metrics.beds == 2 and metrics.occupied == 1 and metrics.dirty == 1 and metrics.occupancy == 50, "occupancy and cleaning derived correctly")
	check(metrics.guests == 3 and metrics.staff == 1 and metrics.happiness == 70, "present guests average excludes staff")
	check(metrics.satisfaction_groups.checked_in.count == 1 and metrics.satisfaction_groups.checked_in.average == 80, "paid stay cohort")
	check(metrics.satisfaction_groups.not_checked_in.count == 2 and metrics.satisfaction_groups.not_checked_in.average == 65, "pre-check-in cohort includes arrivals and waiting")
	var grouped_sum: float = 0
	var grouped_count: int = 0
	for group: Dictionary in metrics.satisfaction_groups.values():
		grouped_sum += group.average * group.count
		grouped_count += group.count
	check(grouped_count == metrics.guests and is_equal_approx(grouped_sum / grouped_count, metrics.happiness), "cohorts reconcile to whole hotel")
	check(metrics.room_queue == 1 and metrics.lift_queue == 1 and metrics.longest_wait == 12.5, "current waits split by service and transport")
	check(metrics.costs.total == session.recurring_costs().total, "fixed-cost projection reconciles")
	check(HotelAnalytics.rooms(session, &"lodging", 1, 2)[0].id == bed_a.id, "category floor and cleaning intersection")
	check(HotelAnalytics.rooms(session, &"lodging", 0).is_empty(), "empty filtered result")
	check(HotelAnalytics.rooms(session, &"transport", 1, 1)[0].id == shaft.id, "shaft appears on all floors with real lift queue")
	var busy := HotelAnalytics.rooms(session, &"", -1, 3)
	check(busy.size() == 1 and busy[0].id == bed_b.id, "in-use includes reserved bedroom")
	var ordered := HotelAnalytics.rooms(session)
	check(ordered[0].id == reception.id and ordered[1].id == shaft.id, "queues first with stable ID tiebreak")
	check(SessionSnapshot.capture(session) == before, "analytics never mutates simulation")
	other.bedroom = -1
	other.travel_to(-0.8, 0, &"exit")
	check(HotelAnalytics.satisfaction_groups(session).checked_in.count == 1, "paid departing visitor retains cohort until leaving")
	other.bedroom = bed_b.id
	other.state = &"using"
	session.actors.erase(guest.id)
	check(HotelAnalytics.satisfaction_groups(session).not_checked_in.count == 1, "departed visitor leaves current cohort")
	session.actors[guest.id] = guest
	var elevator_metrics: Dictionary = HotelAnalytics.rooms(session, &"transport")[0].lift_metrics
	check(elevator_metrics.current_max == 8 and elevator_metrics.boarded == 0, "current unserved wait is separate from boarding history")
	check(UILabels.elevator(elevator_metrics).contains("Sem embarques"), "no history does not imply zero wait")
	# Exercise real boarding and delivery rather than setting historical counters.
	passenger.target_floor = 1
	session.transport.step(session.actors, session.rules.tick)
	elevator_metrics = HotelAnalytics.elevator(session, session.transport.lifts[0])
	check(elevator_metrics.boarded == 1 and elevator_metrics.passengers == 1 and elevator_metrics.current_max == 0, "boarding moves wait into history")
	check(is_equal_approx(elevator_metrics.average_wait, 8.1), "recorded boarding wait includes final tick")
	for tick in 80:
		session.transport.step(session.actors, session.rules.tick)
	check(HotelAnalytics.elevator(session, session.transport.lifts[0]).delivered == 1, "completed passenger trip exposed")
	check(UILabels.state(&"riding") == "No elevador" and UILabels.role(&"guest") == "Hóspede", "player labels translated")
	var path: String = "user://preferences-test.cfg"
	check(UIPreferences.save_large_text(true, path) == OK and UIPreferences.load_large_text(path), "text preference roundtrip")
	check(UIPreferences.save_large_text(false, path) == OK and not UIPreferences.load_large_text(path), "normal text preference roundtrip")
	var config := ConfigFile.new()
	config.set_value("interface", "large_text", "invalid")
	config.save(path)
	check(not UIPreferences.load_large_text(path), "malformed preference defaults safely")
	print(JSON.stringify({"suite": "analytics", "failures": failures}))
	quit(1 if failures else 0)

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
