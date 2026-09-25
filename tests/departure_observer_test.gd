extends SceneTree

var failures: int = 0

func _initialize() -> void:
	var session := HotelSession.new(11)
	var observer := preload("res://tests/departure_observer.gd").new()
	check(observer.report().stayed.mean == null, "empty historical population is unknown")
	var stayed := session.spawn_guest()
	stayed.checked_in = true
	stayed.happiness = 80
	stayed.state = &"exit"
	stayed.needs.hunger = 100
	var rejected := session.spawn_guest()
	rejected.happiness = 20
	rejected.state = &"exit"
	rejected.needs.hunger = 100
	session.hire(HotelSession.EMPLOYEES[0])
	var snapshot := SessionSnapshot.capture(session)
	observer.before_step(session)
	check(SessionSnapshot.capture(session) == snapshot, "observer does not mutate inputs")
	session.tick(0.1)
	snapshot = SessionSnapshot.capture(session)
	observer.after_step(session)
	check(SessionSnapshot.capture(session) == snapshot, "observer does not mutate outputs")
	var report := observer.report()
	check(report.stayed.count == 1 and report.no_stay.count == 1, "real removals classified without staff")
	check(is_equal_approx(report.stayed.mean, 79.985) and is_equal_approx(report.no_stay.mean, 19.985), "captures final tick hunger before removal")
	check(is_equal_approx(report.stayed.score_total + report.no_stay.score_total, session.guests.score_total), "cohort totals reconcile with authoritative score")
	observer.after_step(session)
	observer.before_step(session)
	session.tick(0.1)
	observer.after_step(session)
	check(observer.report() == report, "departure never counted twice")
	report.stayed.count = 99
	check(observer.report().stayed.count == 1, "report cannot mutate observer")
	print(JSON.stringify({"suite": "departure_observer", "failures": failures}))
	quit(1 if failures else 0)

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
