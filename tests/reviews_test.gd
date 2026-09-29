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
	print(JSON.stringify({"suite": "reviews", "failures": failures}))
	quit(1 if failures else 0)

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
