extends SceneTree
## Controlled comparison, not an assertion that each policy should win equally.

var failures: int = 0

func _initialize() -> void:
	var reports: Array[Dictionary] = []
	var value_study := OS.get_cmdline_user_args().has("--lodging-value")
	var mixed := value_study or OS.get_cmdline_user_args().has("--tariff-mixed")
	if mixed:
		for expanded in [false, true]:
			for seed_value in [1, 17, 123]:
				for lodging_percent in [75, 100, 125]:
					for service_percent in ([100] if value_study else [75, 100, 125]):
						reports.append(run_case(seed_value, 8, lodging_percent, service_percent, expanded))
	else:
		for bedrooms in [2, 8]:
			for seed_value in [1, 17, 123]:
				for percent in [75, 100, 125]:
					reports.append(run_case(seed_value, bedrooms, percent))
	var output := "res://.runtime/lodging-value.json" if value_study else ("res://.runtime/tariff-mixed.json" if mixed else "res://.runtime/tariff-scenarios.json")
	var file := FileAccess.open(output, FileAccess.WRITE)
	file.store_string(JSON.stringify({"days": 30, "reports": reports, "failures": failures}, "\t"))
	file.close()
	print(JSON.stringify({"suite": "tariff_scenarios", "failures": failures, "scenarios": reports.size()}))
	quit(1 if failures else 0)

func run_case(seed_value: int, bedrooms: int, percent: int, service_percent: int = -1, expanded: bool = false) -> Dictionary:
	if service_percent < 0:
		service_percent = percent
	var session := HotelSession.new(seed_value)
	var starting_cash := session.economy.cash
	session.hotel.build(HotelCatalog.room(&"reception"), 0, 0)
	session.hotel.build(HotelCatalog.room(&"restaurant"), 3, 0)
	session.hotel.build(HotelCatalog.room(&"elevator"), 6, 0)
	for level in range(1, 2 if bedrooms == 2 else 3):
		session.hotel.add_floor()
		for column in ([0, 2] if bedrooms == 2 else [0, 2, 4, 8]):
			session.hotel.build(HotelCatalog.room(&"bedroom"), column, level)
	for employee in HotelSession.EMPLOYEES:
		check(session.hire(employee).is_empty(), "hire within starting budget")
	check(session.hotel.rooms.size() == bedrooms + 3, "fixture built within budget")
	for room: RoomState in session.hotel.rooms:
		if room.definition().category in [&"lodging", &"service"]:
			check(session.set_room_tariff(room.id, percent if room.definition().category == &"lodging" else service_percent).is_empty(), "tariff applied")
	var construction_cash := session.economy.cash
	var minimum_cash := construction_cash
	var occupied_ticks: int = 0
	var shadow: HotelSession
	var checkpoints: int = 0
	session.opened = true
	for tick in range(1, 36001):
		if expanded and tick == 6001:
			for spec in [[&"cafe", 7], [&"lounge", 9]]:
				var definition := HotelCatalog.room(spec[0])
				check(session.progression.build_error(definition).is_empty(), "natural progression unlocks expansion")
				var added := session.hotel.build(definition, spec[1], 0)
				check(added != null, "earned cash funds expansion")
				if added != null:
					session.set_room_tariff(added.id, service_percent)
				if shadow != null:
					var mirrored := shadow.hotel.build(definition, spec[1], 0)
					if mirrored != null:
						shadow.set_room_tariff(mirrored.id, service_percent)
		session.tick(session.rules.tick)
		if shadow != null:
			shadow.tick(shadow.rules.tick)
			if tick % 6000 == 120:
				var mismatch := preload("res://tests/snapshot_comparison.gd").difference(SessionSnapshot.capture(session), SessionSnapshot.capture(shadow), "tariff continuation")
				check(mismatch.is_empty(), mismatch)
				shadow = null
				checkpoints += 1
		minimum_cash = mini(minimum_cash, session.economy.cash)
		for room: RoomState in session.hotel.rooms:
			if room.occupant >= 0:
				occupied_ticks += 1
		if tick % 100 == 0:
			var error := SimulationRunner.invariant_error(session, starting_cash)
			check(error.is_empty(), error)
			if not error.is_empty():
				break
		if tick % 6000 == 0 and tick < 36000:
			var loaded := SessionSnapshot.restore(JSON.parse_string(JSON.stringify(SessionSnapshot.capture(session))))
			check(loaded.error.is_empty(), "tariff snapshot accepted")
			shadow = loaded.session
	check(checkpoints == 5, "five save continuations checked")
	var report := {"seed": seed_value, "bedrooms": bedrooms, "percent": percent, "starting_cash": starting_cash, "construction_cash": construction_cash, "minimum_cash": minimum_cash, "ending_cash": session.economy.cash, "profit": session.economy.profit(), "bookings": session.guests.bookings, "meals": session.guests.meals_served, "departures": session.guests.completed, "reputation": session.guests.reputation, "occupancy": float(occupied_ticks) / (36000 * bedrooms), "save_checkpoints": checkpoints, "ticks": session.tick_count}
	print(JSON.stringify(report))
	report["service_percent"] = service_percent
	report["expanded"] = expanded
	report["service_uses"] = session.guests.service_uses
	var income: Dictionary = {}
	for room: RoomState in session.hotel.rooms:
		income[room.definition_id] = int(income.get(room.definition_id, 0)) + room.income
	report["income_by_type"] = income
	return report

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
