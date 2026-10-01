extends SceneTree
## Real completion, delegation boundaries, corruption guards and policy comparison.

var checks: int = 0
var failures: int = 0
var policies: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_recruitment()
	_cleaning()
	_reception()
	_priority()
	_dismissal()
	_persistence()
	for seed_value in [1, 17, 123, 9001, 54321]:
		_policy(seed_value)
	print(JSON.stringify({"suite": "staff_automation", "checks": checks, "failures": failures, "policies": policies}))
	print("MOBILE_TEST_COMPLETE")
	quit(1 if failures else 0)

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func hotel(seed_value: int = 123) -> HotelSession:
	var session := HotelSession.new(seed_value)
	check(session.hotel.build(HotelCatalog.room(&"reception"), 0, 0) != null, "test reception built")
	check(session.hotel.build(HotelCatalog.room(&"bedroom"), 3, 0) != null, "test bedroom built")
	return session

func ticks(session: HotelSession, count: int) -> void:
	for index in count:
		session.tick(session.rules.tick)

func roundtrip(session: HotelSession) -> HotelSession:
	var snapshot := SessionSnapshot.capture(session)
	var restored := SessionSnapshot.restore(JSON.parse_string(JSON.stringify(snapshot)))
	check(restored.error.is_empty(), "staff save accepted: " + restored.error)
	if restored.session == null:
		return null
	check(preload("res://tests/snapshot_comparison.gd").difference(snapshot, SessionSnapshot.capture(restored.session), "staff").is_empty(), "staff exact snapshot roundtrip")
	return restored.session

func _recruitment() -> void:
	for definition in HotelSession.EMPLOYEES:
		for profile: Array in EmployeeProgress.RULES.profiles(definition.id):
			var session := hotel()
			var traits: Array[StringName] = []
			traits.assign(profile)
			var cash := session.economy.cash
			var rng_state := session.rng.state
			check(session.hire(definition, traits).is_empty(), "valid fixed recruitment profile")
			var actor: ActorState = session.actors[1]
			var cost := EmployeeProgress.RULES.hire_cost(definition.hire_cost, traits)
			check(session.economy.cash == cash - cost and session.economy.capital_spent >= cost, "profile price charged once")
			check(session.recurring_costs().salaries == actor.employee.salary(definition.salary), "salary preview equals recurring charge")
			check(session.rng.state == rng_state and actor.employee.level() == 1, "recruitment consumes no random reroll and starts at level one")
			traits.clear()
			check(actor.employee.traits.size() == profile.size(), "recruitment copies trait ownership")
			ticks(session, 100)
			check(actor.employee.xp == 0 and actor.employee.completed_tasks == 0, "idle and walking award no experience")
			roundtrip(session)
		var session := hotel()
		var before := SessionSnapshot.capture(session)
		var invalid: Array[StringName] = []
		invalid.append(&"meticulous" if definition.id == &"receptionist" else &"charismatic")
		check(not session.hire(definition, invalid).is_empty(), "role rejects unrelated trait")
		check(not session.hire(definition, [&"agile", &"agile"]).is_empty(), "duplicate traits rejected")
		check(preload("res://tests/snapshot_comparison.gd").difference(before, SessionSnapshot.capture(session), "reject").is_empty(), "invalid hires preserve cash IDs RNG and state")
		check(definition.skill == 1.0 and definition.salary == (35 if definition.id == &"receptionist" else 30), "shared role definition unchanged")
	var progress := EmployeeProgress.new()
	for index in 100:
		progress.award(&"cleaner")
	check(progress.level() == 5 and progress.xp == 600 and progress.completed_tasks == 100, "bounded level cap preserves cumulative completed work")
	check(is_equal_approx(progress.efficiency(), 1.32) and progress.salary(30) == 36, "level cap has bounded efficiency and salary tradeoff")

func _cleaning() -> void:
	var durations: Dictionary = {}
	for profile: Array in EmployeeProgress.RULES.profiles(&"cleaner"):
		var session := hotel()
		var traits: Array[StringName] = []
		traits.assign(profile)
		session.hire(HotelSession.EMPLOYEES[1], traits)
		var actor: ActorState = session.actors[1]
		var room := session.hotel.rooms[1]
		room.dirty = true
		var count := 0
		while room.dirty and count < 300:
			session.tick(session.rules.tick)
			count += 1
		durations[str(profile)] = count
		check(not room.dirty and room.cleaning_by == -1 and session.employees.cleaned == 1, "actual cleanup finishes exactly once")
		check(actor.employee.xp == 10 and actor.employee.completed_tasks == 1, "one cleanup grants one XP reward")
		check(room.cleaning_quality_bonus == (3 if traits.has(&"meticulous") else 0), "meticulous cleanup supplies next-booking quality")
		ticks(session, 100)
		check(actor.employee.completed_tasks == 1, "idle cannot repeat completion reward")
		roundtrip(session)
	check(durations[str([&"agile"])] < durations[str([])] and durations[str([&"meticulous"])] > durations[str([])], "trait speed differences affect real physical cleanup")
	var session := hotel()
	session.hire(HotelSession.EMPLOYEES[1])
	var actor: ActorState = session.actors[1]
	var room := session.hotel.rooms[1]
	room.dirty = true
	ticks(session, 30)
	check(actor.state == &"cleaning", "cleaner reaches work")
	check(session.set_employee_duty(1, false).is_empty(), "pause delegation accepted")
	var resumed := roundtrip(session)
	ticks(session, 200)
	if resumed != null:
		ticks(resumed, 200)
		check(preload("res://tests/snapshot_comparison.gd").difference(SessionSnapshot.capture(session), SessionSnapshot.capture(resumed), "paused cleanup").is_empty(), "paused active task resumes deterministically")
	check(not room.dirty and actor.employee.xp == 10 and actor.state == &"idle", "pause completes current cleanup")
	room.dirty = true
	ticks(session, 100)
	check(room.dirty and room.cleaning_by == -1 and actor.employee.xp == 10, "paused cleaner takes no next task")
	check(session.recurring_costs().salaries == 30, "pausing does not evade wages")
	session.set_employee_duty(1, true)
	for job in 5:
		room.dirty = true
		room.cleaning_quality_bonus = 0
		ticks(session, 160)
	check(actor.employee.level() == 2 and actor.employee.xp == 60 and actor.employee.completed_tasks == 6, "six actual cleanups promote to level two")
	check(session.recurring_costs().salaries == 32 and actor.work_efficiency() > 1.0, "promotion affects real salaries and service speed")

func _reception() -> void:
	var results: Array[Dictionary] = []
	for profile: Array in [[], [&"charismatic"], [&"agile"]]:
		var traits: Array[StringName] = []
		traits.assign(profile)
		var session := hotel()
		session.hire(HotelSession.EMPLOYEES[0], traits)
		var actor: ActorState = session.actors[1]
		var guest := session.spawn_guest()
		var count := 0
		while not guest.checked_in and count < 200:
			session.tick(session.rules.tick)
			count += 1
		check(guest.checked_in and actor.employee.xp == 6 and actor.employee.completed_tasks == 1, "actual checkin grants one reward")
		results.append({"ticks": count, "happiness": guest.happiness})
		ticks(session, 20)
		check(actor.employee.completed_tasks == 1, "post-booking timer cannot duplicate XP")
		roundtrip(session)
	check(results[1].happiness > results[0].happiness + 2.9 and results[2].ticks < results[0].ticks, "charisma and agility have real guest and throughput effects")
	var session := hotel()
	session.hire(HotelSession.EMPLOYEES[0])
	var guest := session.spawn_guest()
	var next := session.spawn_guest()
	for index in 100:
		session.tick(session.rules.tick)
		if guest.state == &"checkin" and guest.timer > 0:
			break
	session.set_employee_duty(1, false)
	ticks(session, 60)
	check(guest.checked_in and not next.checked_in and next.timer == 0, "reception pause completes head and stops next guest")
	check(session.actors[1].employee.completed_tasks == 1 and session.actors[1].assignment == -1, "paused post released after current admission")
	check(CheckinDiagnostics.reason(session, session.hotel.rooms[0]) == "unstaffed", "paused queue diagnosis explains manual bottleneck")
	var quality := hotel()
	quality.hotel.rooms[1].cleaning_quality_bonus = 3
	var customer := quality.spawn_guest()
	ticks(quality, 30)
	var before := customer.happiness
	check(quality.guests.admit(customer, quality.hotel, quality.transport, quality.time), "manual guest can consume cleaning quality")
	check(is_equal_approx(customer.happiness, before + 3) and quality.hotel.rooms[1].cleaning_quality_bonus == 0, "cleaning quality is granted once at booking")

func _priority() -> void:
	for priority: StringName in [&"oldest", &"nearest"]:
		var session := hotel()
		session.hotel.build(HotelCatalog.room(&"bedroom"), 8, 0)
		ticks(session, 100)
		var near := session.hotel.rooms[1]
		var far := session.hotel.rooms[2]
		near.dirty = true
		near.dirty_since = 9.0
		far.dirty = true
		far.dirty_since = 2.0
		session.hire(HotelSession.EMPLOYEES[1])
		session.set_employee_priority(1, priority)
		session.tick(session.rules.tick)
		check(session.actors[1].assignment == (far.id if priority == &"oldest" else near.id), "priority changes actual next destination")
		roundtrip(session)
		var snapshot := SessionSnapshot.capture(session)
		StaffProjection.department(session, &"cleaner")
		StaffProjection.details(session.actors[1])
		check(preload("res://tests/snapshot_comparison.gd").difference(snapshot, SessionSnapshot.capture(session), "projection").is_empty(), "supervision is read only")

func _dismissal() -> void:
	var session := hotel()
	session.hotel.add_floor()
	session.hotel.build(HotelCatalog.room(&"elevator"), 14, 0)
	var room := session.hotel.build(HotelCatalog.room(&"bedroom"), 3, 1)
	room.dirty = true
	session.hire(HotelSession.EMPLOYEES[1], [&"agile"])
	var actor: ActorState = session.actors[1]
	for index in 300:
		session.tick(session.rules.tick)
		if actor.state == &"riding":
			break
	check(actor.state == &"riding", "dismissal fixture reaches real elevator passenger")
	var lift := session.transport.lift_by_id(actor.elevator_id)
	var cash := session.economy.cash
	check(session.dismiss_employee(1).is_empty(), "dismissal accepted during ride")
	check(room.dirty and room.cleaning_by == -1 and lift.passengers.has(1) and session.economy.cash == cash, "dismissal frees task without teleporting passenger or refund")
	check(not session.dismiss_employee(1).is_empty() and not session.set_employee_duty(1, true).is_empty(), "departing employee cannot resume or be dismissed twice")
	var resumed := roundtrip(session)
	for index in 600:
		session.tick(session.rules.tick)
		if resumed != null:
			resumed.tick(resumed.rules.tick)
		check(SimulationRunner.invariant_error(session, 12000).is_empty(), "dismissal preserves transport and actor invariants")
		if not session.actors.has(1):
			break
	check(not session.actors.has(1) and session.employees.dismissed == 1 and actor.employee.xp == 0, "physical exit removes staff once without unfinished-task XP")
	check(session.recurring_costs().salaries == 0 and room.dirty, "salary stops after departure and cleanup remains pending")
	if resumed != null:
		check(preload("res://tests/snapshot_comparison.gd").difference(SessionSnapshot.capture(session), SessionSnapshot.capture(resumed), "dismissal").is_empty(), "saved passenger dismissal resumes exactly")
	session.player_work.start(session, "cleaning", room.id)
	var player := session.player_work.worker(session)
	if player != null:
		check(not session.dismiss_employee(player.id).is_empty(), "player is never dismissible staff")
	session.player_work.cancel(session)

func _persistence() -> void:
	var session := hotel()
	session.hire(HotelSession.EMPLOYEES[1], [&"agile", &"meticulous"])
	var snapshot := SessionSnapshot.capture(session)
	var old := snapshot.duplicate(true)
	old.version = 8
	old.erase("dismissed")
	for room: Dictionary in old.rooms:
		room.erase("dirty_since")
		room.erase("cleaning_quality_bonus")
	for actor: Dictionary in old.actors:
		actor.erase("employee")
	var restored := SessionSnapshot.restore(old)
	check(restored.error.is_empty() and restored.session.economy.cash == session.economy.cash and restored.session.actors[1].employee.traits.is_empty(), "v8 migration preserves wealth without inventing staff experience or traits")
	for field: String in ["xp", "completed_tasks", "traits", "duty_enabled", "priority", "dismiss_requested"]:
		var broken := snapshot.duplicate(true)
		broken.actors[0].employee.erase(field)
		check(not SessionSnapshot.restore(broken).error.is_empty(), "missing staff field rejected: " + field)
	for invalid: Dictionary in [{"xp": 6}, {"completed_tasks": -1}, {"traits": ["agile", "agile"]}, {"traits": ["charismatic"]}, {"traits": ["agile", "meticulous", "extra"]}, {"priority": "random"}, {"duty_enabled": 1}, {"dismiss_requested": true}]:
		var broken := snapshot.duplicate(true)
		broken.actors[0].employee.merge(invalid, true)
		check(not SessionSnapshot.restore(broken).error.is_empty(), "malformed staff rejected")
	var future := snapshot.duplicate(true)
	future.version += 1
	check(not SessionSnapshot.restore(future).error.is_empty(), "future snapshot stays blocked")

func _policy(seed_value: int) -> void:
	var pair: Array[Dictionary] = []
	for delegated: bool in [false, true]:
		var session := HotelSession.new(seed_value)
		session.economy.cash = 2400
		session.hotel.build(HotelCatalog.room(&"reception"), 0, 0)
		session.hotel.build(HotelCatalog.room(&"bedroom"), 3, 0)
		session.hotel.build(HotelCatalog.room(&"restaurant"), 5, 0)
		session.opened = true
		var hired := false
		var manual := 0
		var manual_after := 0
		var minimum_cash := session.economy.cash
		for index in 12000:
			# Keep one upcoming hotel-day of wages and maintenance after recruitment.
			if delegated and not hired and session.economy.cash >= 330 + session.recurring_costs().total + 65:
				check(session.hire(HotelSession.EMPLOYEES[0]).is_empty() and session.hire(HotelSession.EMPLOYEES[1]).is_empty(), "earned funds support two essential delegates")
				hired = true
			if not session.player_work.busy(session):
				var target := -1
				var kind := "checkin"
				for room in session.hotel.rooms:
					if room.dirty and room.cleaning_by == -1:
						target = room.id
						kind = "cleaning"
						break
				if target < 0 and not hired and session.player_work.task_error(session, "checkin", 1).is_empty():
					target = 1
				if target >= 0 and (not hired or kind == "cleaning" and StaffProjection.department(session, &"cleaner").enabled == 0):
					if session.player_work.start(session, kind, target).is_empty():
						manual += 1
						if session.time >= 600:
							manual_after += 1
			session.tick(session.rules.tick)
			minimum_cash = mini(minimum_cash, session.economy.cash)
		check(session.guests.bookings >= 6 and session.economy.cash > 0 and minimum_cash >= 0, "mobile policy solvent and productive without injected funds")
		check(not delegated or hired, "delegation reached with earned Cash")
		pair.append({"delegated": delegated, "manual": manual, "manual_after_600": manual_after, "bookings": session.guests.bookings, "cleaned": session.employees.cleaned, "cash": session.economy.cash, "reputation": session.guests.reputation, "min_cash": minimum_cash})
	check(pair[0].manual_after_600 > 0 and pair[1].manual_after_600 <= pair[0].manual_after_600 * 0.4, "delegation reduces late-session core manual interventions by at least 60 percent")
	check(pair[1].bookings >= pair[0].bookings * 0.85, "automation retains at least 85 percent of active manual booking throughput")
	policies.append({"seed": seed_value, "scenarios": pair})
