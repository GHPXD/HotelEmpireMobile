class_name SimulationRunner
extends RefCounted
## Headless benchmark. Timing includes only simulation, never validation or rendering.

static func make_hotel(seed_value: int, template: String, starting_cash: int) -> HotelSession:
	var session := HotelSession.new(seed_value)
	session.economy.cash = starting_cash
	var floor_count: int = 20 if template == "tower" else 3
	for floor_index in range(1, floor_count):
		if not session.hotel.add_floor().is_empty():
			return null
	for column in [0, 3]:
		if session.hotel.build(HotelCatalog.room(&"reception"), column, 0) == null:
			return null
	for column in [6, 9]:
		if session.hotel.build(HotelCatalog.room(&"restaurant"), column, 0) == null:
			return null
	var shafts: Array[int] = [12]
	if template == "tower":
		shafts.assign([12, 13, 14, 15])
	for column in shafts:
		if session.hotel.build(HotelCatalog.room(&"elevator"), column, 0) == null:
			return null
	for floor_index in range(1, floor_count):
		for column in [0, 2, 4, 6, 8, 10]:
			if session.hotel.build(HotelCatalog.room(&"bedroom"), column, floor_index) == null:
				return null
	for count in 2:
		if not session.hire(HotelSession.EMPLOYEES[0]).is_empty():
			return null
	for count in (8 if template == "tower" else 2):
		if not session.hire(HotelSession.EMPLOYEES[1]).is_empty():
			return null
	return session

static func run(options: Dictionary) -> Dictionary:
	var session := make_hotel(options.seed, options.template, options.starting_money)
	if session == null:
		return {"error": "Starting money cannot fund the selected template."}
	session.opened = options.guests == 0
	for count in options.guests:
		session.spawn_guest()
	var durations: Array[int] = []
	var queue_metrics := preload("res://debug/queue_metrics.gd").new()
	var failures: Array[String] = []
	var peak_agents: int = session.actors.size()
	var peak_guests: int = session.guest_count()
	var peak_queue: int = 0
	var actor_samples: int = 0
	var occupied_samples: int = 0
	var beds: int = 0
	for room in session.hotel.rooms:
		if room.definition().category == &"lodging":
			beds += 1
	var samples: int = 0
	var memory_start: int = OS.get_static_memory_usage()
	var peak_memory: int = memory_start
	var ticks: int = roundi(options.days * session.rules.day_seconds / session.rules.tick)
	var objective_ticks: Dictionary = {}
	for index in ticks:
		var started: int = Time.get_ticks_usec()
		session.tick(session.rules.tick)
		durations.append(Time.get_ticks_usec() - started)
		for objective: StringName in session.progression.completed:
			if not objective_ticks.has(objective):
				objective_ticks[objective] = session.tick_count
		queue_metrics.observe(session)
		peak_agents = maxi(peak_agents, session.actors.size())
		peak_guests = maxi(peak_guests, session.guest_count())
		if index % 10 == 0:
			samples += 1
			actor_samples += session.actors.size()
			peak_memory = maxi(peak_memory, OS.get_static_memory_usage())
			for room in session.hotel.rooms:
				if room.occupant >= 0:
					occupied_samples += 1
			var queue_size: int = 0
			for lift in session.transport.lifts:
				queue_size += lift.queue.members.size()
			peak_queue = maxi(peak_queue, queue_size)
			var error := invariant_error(session, options.starting_money)
			if not error.is_empty():
				failures.append("tick %d: %s" % [session.tick_count, error])
				break
		if index > 0 and index % 1200 == 0:
			var restored := SessionSnapshot.restore(JSON.parse_string(JSON.stringify(SessionSnapshot.capture(session))))
			if not restored.error.is_empty():
				failures.append("snapshot tick %d: %s" % [session.tick_count, restored.error])
				break
	var wait_total: float = 0
	var wait_max: float = 0
	var boarded: int = 0
	var delivered: int = 0
	for lift in session.transport.lifts:
		wait_total += lift.wait_total
		wait_max = maxf(wait_max, lift.wait_max)
		boarded += lift.boarded
		delivered += lift.delivered
	var total_usec: int = 0
	for duration in durations:
		total_usec += duration
	durations.sort()
	var profiles: Dictionary = {}
	for actor: ActorState in session.actors.values():
		if actor.role == &"guest":
			profiles[actor.archetype_id] = int(profiles.get(actor.archetype_id, 0)) + 1
	return {"service_uses": session.guests.service_uses, "active_guest_profiles": profiles, "event": HotelEvents.state(session.tick_count, session.rules), "progression": session.progression.snapshot(), "objective_ticks": objective_ticks, "mode": "continuous_arrivals" if options.guests == 0 else "initial_burst", "seed": options.seed, "template": options.template, "days": options.days, "ticks": session.tick_count, "peak_guests": peak_guests, "peak_agents": peak_agents, "mean_agents": float(actor_samples) / maxi(1, samples), "cash": session.economy.cash, "revenue": session.economy.revenue, "expenses": session.economy.expenses, "profit": session.economy.profit(), "bookings": session.guests.bookings, "departures": session.guests.completed, "meals": session.guests.meals_served, "cleaned": session.employees.cleaned, "average_satisfaction": session.guests.score_total / maxi(1, session.guests.completed), "occupancy_ratio": float(occupied_samples) / maxi(1, samples * beds), "queues": queue_metrics.summary(), "elevator_average_wait_seconds": wait_total / maxi(1, boarded), "elevator_max_wait_seconds": wait_max, "elevator_peak_queue": peak_queue, "elevator_delivered": delivered, "path_requests": session.transport.path_requests, "simulation_total_ms": total_usec / 1000.0, "tick_mean_ms": total_usec / (1000.0 * maxi(1, durations.size())), "tick_p95_ms": durations[int((durations.size() - 1) * 0.95)] / 1000.0, "tick_max_ms": durations.back() / 1000.0, "process_memory_start_bytes": memory_start, "process_memory_peak_bytes": peak_memory, "failures": failures}

static func invariant_error(session: HotelSession, starting_money: int) -> String:
	if session.economy.cash != starting_money + session.economy.revenue - session.economy.expenses - session.economy.capital_spent:
		return "Cash does not reconcile with lifetime transactions."
	var staff: int = 0
	for actor: ActorState in session.actors.values():
		if actor.role != &"guest":
			staff += 1
		if not is_finite(actor.x) or actor.happiness < 0 or actor.happiness > 100 or actor.money < 0:
			return "Invalid actor attributes."
		if actor.floor_index < 0 or actor.floor_index >= session.hotel.floors:
			return "Actor outside hotel."
	if session.guest_count() + session.guests.completed + staff + session.employees.dismissed != session.next_actor_id - 1:
		return "An actor was lost or counted twice."
	for room in session.hotel.rooms:
		if room.users.size() > room.capacity() or room.queue.members.size() > room.queue.capacity:
			return "Room capacity exceeded."
		if room.dirty and room.occupant >= 0:
			return "Dirty bedroom allocated."
	for lift in session.transport.lifts:
		if lift.passengers.size() > lift.capacity:
			return "Elevator capacity exceeded."
	return SessionSnapshot._validate_relations(session)

static func parse(arguments: PackedStringArray) -> Dictionary:
	var options: Dictionary = {"seed": 123, "days": 5, "guests": 0, "starting_money": 250000, "template": "standard", "output": ""}
	for argument in arguments:
		if argument == "--simulate":
			continue
		var pair := argument.trim_prefix("--").split("=", true, 1)
		if pair.size() != 2:
			return {"error": "Expected --key=value: " + argument}
		var key: String = pair[0].replace("-", "_")
		if not options.has(key):
			return {"error": "Unknown option: " + key}
		if key in ["seed", "days", "guests", "starting_money"]:
			if not pair[1].is_valid_int():
				return {"error": "Expected integer: " + key}
			options[key] = int(pair[1])
		else:
			options[key] = pair[1]
	if options.days < 1 or options.days > 60 or options.guests < 0 or options.guests > 1000 or options.starting_money < 0 or options.starting_money > 1000000000 or options.template not in ["standard", "tower"]:
		return {"error": "Use days 1–60, guests 0–1000, starting-money 0–1000000000, template standard|tower."}
	return options
