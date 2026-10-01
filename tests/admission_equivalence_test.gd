extends SceneTree
## Reference keeps the pre-M8 scan of every room for every arriving guest.

var failures: int = 0

func _initialize() -> void:
	for seed_value in [17, 123, 9001]:
		var optimized := SimulationRunner.make_hotel(seed_value, "tower", 1000000)
		var reference := SimulationRunner.make_hotel(seed_value, "tower", 1000000)
		reference.guests = preload("res://tests/legacy_admission_reference.gd").new(reference.rules)
		# Rebuild reception after other categories; admission must preserve insertion order.
		for session: HotelSession in [optimized, reference]:
			var reception: RoomState = session.hotel.rooms[0]
			var column: int = reception.column
			session.hotel.demolish(reception.id)
			session.hotel.build(HotelCatalog.room(&"reception"), column, 0)
		for tick_index in 240:
			for session: HotelSession in [optimized, reference]:
				for missing in maxi(0, 250 - session.guest_count()):
					session.spawn_guest()
				session.tick(session.rules.tick)
			if tick_index % 40 == 0:
				compare(optimized, reference, "seed %d tick %d" % [seed_value, tick_index])
		compare(optimized, reference, "final")
		var restored := SessionSnapshot.restore(JSON.parse_string(JSON.stringify(SessionSnapshot.capture(optimized))))
		if not restored.error.is_empty():
			failures += 1
		else:
			var resumed: HotelSession = restored.session
			for tick_index in 100:
				optimized.tick(optimized.rules.tick)
				resumed.tick(resumed.rules.tick)
			compare(optimized, resumed, "save continuation")
	print(JSON.stringify({"suite": "admission_equivalence", "failures": failures, "seeds": 3}))
	quit(1 if failures else 0)

func compare(left: HotelSession, right: HotelSession, label: String) -> void:
	var error := preload("res://tests/snapshot_comparison.gd").difference(SessionSnapshot.capture(left), SessionSnapshot.capture(right), label)
	if not error.is_empty():
		failures += 1
		push_error(error)
