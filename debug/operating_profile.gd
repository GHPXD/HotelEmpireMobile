extends SceneTree
## Occupied hotel, unchanged production rules, real scene and HUD.

func _initialize() -> void:
	call_deferred("run")

static func make_busy_hotel() -> HotelSession:
	var session := HotelSession.new(123)
	session.economy.cash = 1000000
	for level in range(1, 20):
		session.hotel.add_floor()
	for column in [0, 3, 6, 9]:
		session.hotel.build(HotelCatalog.room(&"reception"), column, 0)
		session.hotel.build(HotelCatalog.room(&"restaurant"), column, 1)
	for column in [12, 13, 14, 15]:
		session.hotel.build(HotelCatalog.room(&"elevator"), column, 0)
	for level in range(2, 20):
		for column in [0, 2, 4, 6, 8, 10]:
			session.hotel.build(HotelCatalog.room(&"bedroom"), column, level)
	for count in 4:
		session.hire(HotelSession.EMPLOYEES[0])
	for count in 12:
		session.hire(HotelSession.EMPLOYEES[1])
	return session

func paced_arrival(session: HotelSession) -> void:
	if session.guest_count() < session.rules.max_guests:
		session.spawn_guest()

func run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var game := MobileProfileSupport.create(root)
	current_scene = game
	game.audio.enabled = false
	var rows: Array[Dictionary] = []
	var failed: bool = false
	for scenario in ["normal", "paced_one_per_second"]:
		var session := SimulationRunner.make_hotel(123, "standard", 1000000) if scenario == "normal" else make_busy_hotel()
		session.opened = scenario == "normal"
		# Prewarm through actual decisions/services, not manually assigned rooms/states.
		for tick_index in 3000:
			if scenario != "normal" and tick_index % 10 == 0:
				paced_arrival(session)
			session.tick(session.rules.tick)
			if tick_index % 500 == 0:
				await process_frame
		session.speed = 0
		MobileProfileSupport.activate(game, session)
		for frame in 30:
			await process_frame
		for speed in [1, 3]:
			var start_time: float = session.time
			var start_bookings: int = session.guests.bookings
			var start_meals: int = session.guests.meals_served
			var start_cleaned: int = session.employees.cleaned
			var last_tick: int = session.tick_count
			var next_arrival: int = last_tick + 10
			var frames: Array[float] = []
			var populations: Array[int] = []
			var peak_occupied: int = 0
			var states_seen: Dictionary = {}
			var over_budget: int = 0
			session.speed = speed
			while session.time < start_time + 30.0:
				var started: int = Time.get_ticks_usec()
				await process_frame
				var elapsed: float = (Time.get_ticks_usec() - started) / 1000.0
				frames.append(elapsed)
				if elapsed > 1000.0 / 60.0:
					over_budget += 1
				if session.tick_count != last_tick:
					last_tick = session.tick_count
					if scenario != "normal" and last_tick >= next_arrival:
						paced_arrival(session)
						next_arrival = last_tick + 10
					populations.append(session.guest_count())
					var occupied: int = 0
					for room: RoomState in session.hotel.rooms:
						if room.occupant >= 0:
							occupied += 1
					peak_occupied = maxi(peak_occupied, occupied)
					for actor: ActorState in session.actors.values():
						states_seen[actor.state] = true
			session.speed = 0
			frames.sort()
			var total: float = 0
			for value in frames:
				total += value
			var error := SimulationRunner.invariant_error(session, 1000000)
			failed = failed or not error.is_empty()
			var row: Dictionary = {"scenario": scenario, "speed": speed, "start_sim_seconds": start_time, "end_sim_seconds": session.time, "min_guests": populations.min(), "max_guests": populations.max(), "ending_guests": session.guest_count(), "peak_reserved_bedrooms": peak_occupied, "new_bookings": session.guests.bookings - start_bookings, "new_meals": session.guests.meals_served - start_meals, "new_cleanings": session.employees.cleaned - start_cleaned, "states_seen": states_seen.keys(), "frame_mean_ms": total / frames.size(), "frame_p95_ms": frames[int((frames.size() - 1) * 0.95)], "frame_max_ms": frames.back(), "frames": frames.size(), "frames_over_16_67ms_percent": 100.0 * over_budget / frames.size(), "engine_static_memory_bytes": OS.get_static_memory_usage(), "error": error}
			rows.append(row)
			print(JSON.stringify(row))
	var report: Dictionary = {"engine": Engine.get_version_info().string, "cpu": OS.get_processor_name(), "gpu": RenderingServer.get_video_adapter_name(), "window": str(root.size), "rules": "unchanged; max_guests=120", "rows": rows}
	var file := FileAccess.open("user://mobile-m8-operating.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
