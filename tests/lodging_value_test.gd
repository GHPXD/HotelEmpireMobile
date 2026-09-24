extends SceneTree

var failures: int = 0

func _initialize() -> void:
	for profile: GuestArchetype in HotelCatalog.GUESTS:
		for percent in [75, 100, 125]:
			check_admission(profile, percent)
	check_admission(HotelCatalog.GUESTS[0], 75, 99)
	check_admission(HotelCatalog.GUESTS[0], 125, 1)
	print(JSON.stringify({"suite": "lodging_value", "cases": 11, "failures": failures}))
	quit(1 if failures else 0)

func check_admission(profile: GuestArchetype, percent: int, initial_happiness: float = 50) -> void:
	var session := HotelSession.new(41)
	var reception := session.hotel.build(HotelCatalog.room(&"reception"), 0, 0)
	var bedroom := session.hotel.build(HotelCatalog.room(&"bedroom"), 3, 0)
	session.hire(HotelSession.EMPLOYEES[0])
	for tick in 80:
		session.tick(0.1)
	var guest := session.spawn_guest()
	guest.archetype_id = profile.id
	guest.state = &"checkin"
	guest.target_room = reception.id
	guest.x = reception.center()
	guest.timer = reception.duration()
	guest.happiness = initial_happiness
	reception.queue.join(guest.id)
	session.set_room_tariff(bedroom.id, percent)
	var money := guest.money
	session.tick(0.1)
	var expected_delta: float = (0.2 if profile.id == &"business" else 0.3) * (100 - percent)
	check(guest.checked_in, "actual check-in completes")
	var expected := clampf(maxf(0, initial_happiness - session.rules.waiting_penalty * 0.1) + expected_delta, 0, 100)
	check(is_equal_approx(guest.happiness, expected), "one bounded value effect at check-in")
	check(guest.money == money - bedroom.price(), "tariff charged exactly once")
	var happy := guest.happiness
	session.set_room_tariff(bedroom.id, 125 if percent != 125 else 75)
	check(guest.happiness == happy, "policy change does not rewrite occupant satisfaction")
	var restored := SessionSnapshot.restore(JSON.parse_string(JSON.stringify(SessionSnapshot.capture(session))))
	check(restored.error.is_empty(), "post-check-in save loads")
	if restored.session != null:
		check(is_equal_approx(restored.session.actors[guest.id].happiness, happy), "value effect persists in existing happiness field")
		for tick in 120:
			session.tick(0.1)
			restored.session.tick(0.1)
		var mismatch := preload("res://tests/snapshot_comparison.gd").difference(SessionSnapshot.capture(session), SessionSnapshot.capture(restored.session), "value")
		check(mismatch.is_empty(), "continuation does not reapply value effect: " + mismatch)

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
