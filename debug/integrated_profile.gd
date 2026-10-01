extends SceneTree
## Real main scene, real-time burst. Reports declining population explicitly.

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var game := MobileProfileSupport.create(root)
	current_scene = game
	game.audio.enabled = false
	var rows: Array[Dictionary] = []
	for population in [100, 250, 500, 1000]:
		var session := SimulationRunner.make_hotel(123, "tower", 1000000)
		session.speed = 0
		MobileProfileSupport.activate(game, session)
		for warmup in 30:
			await process_frame
		for index in population:
			session.spawn_guest()
		session.speed = 1
		var frames: Array[float] = []
		var above_budget: int = 0
		var last_tick: int = -1
		var actual: int = population
		var minimum: int = population
		var summed_guests: int = 0
		while session.time < 12.0:
			var started: int = Time.get_ticks_usec()
			await process_frame
			var elapsed: float = (Time.get_ticks_usec() - started) / 1000.0
			frames.append(elapsed)
			if elapsed > 1000.0 / 60.0:
				above_budget += 1
			if last_tick != session.tick_count:
				last_tick = session.tick_count
				actual = session.guest_count()
				minimum = mini(minimum, actual)
			summed_guests += actual
		session.speed = 0
		frames.sort()
		var total: float = 0
		for value in frames:
			total += value
		var states: Dictionary = {}
		for actor: ActorState in session.actors.values():
			states[actor.state] = int(states.get(actor.state, 0)) + 1
		var error := SimulationRunner.invariant_error(session, 1000000)
		var row: Dictionary = {"initial_guests": population, "ending_guests": actual, "minimum_guests": minimum, "frame_weighted_guests": float(summed_guests) / frames.size(), "simulation_seconds": session.time, "frames": frames.size(), "mean_ms": total / frames.size(), "p95_ms": frames[int((frames.size() - 1) * 0.95)], "max_ms": frames.back(), "percent_frames_over_16_67ms": 100.0 * above_budget / frames.size(), "bookings": session.guests.bookings, "departures": session.guests.completed, "paths": session.transport.path_requests, "ending_states_including_staff": states, "error": error}
		rows.append(row)
		print(JSON.stringify(row))
	var report: Dictionary = {"mode": "integrated_12_seconds_single_arrival_burst", "engine": Engine.get_version_info().string, "cpu": OS.get_processor_name(), "gpu": RenderingServer.get_video_adapter_name(), "window": str(root.size), "hud": true, "vsync": DisplayServer.window_get_vsync_mode(), "rows": rows}
	var file := FileAccess.open("user://mobile-m8-integrated.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	game.queue_free()
	await process_frame
	for row: Dictionary in rows:
		if not row.error.is_empty():
			quit(1)
			return
	quit(0)
