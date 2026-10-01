extends SceneTree
## Physical jobs, economic effects, race guards and exact resume across phases.

var failures: int = 0
var checks: int = 0
var phases: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_checkin()
	_cleaning_repair()
	_delivery()
	_capacity_cancel()
	_elevator_cancel()
	_races_and_invalid_active()
	_legacy_malformed()
	for seed_value in [1, 17, 123, 9001, 54321]:
		_solo_policy(seed_value)
	print(JSON.stringify({"suite": "player_work", "checks": checks, "failures": failures, "phases": phases.keys()}))
	print("MOBILE_TEST_COMPLETE")
	quit(1 if failures else 0)

func _hotel(seed_value: int = 123) -> HotelSession:
	var session := HotelSession.new(seed_value)
	check(session.hotel.build(HotelCatalog.room(&"reception"), 0, 0) != null, "reception")
	check(session.hotel.build(HotelCatalog.room(&"bedroom"), 3, 0) != null, "bedroom")
	return session

func _arrived(session: HotelSession) -> ActorState:
	var guest := session.spawn_guest()
	for tick_index in 100:
		session.tick(session.rules.tick)
		if guest.state == &"checkin":
			return guest
	check(false, "guest reaches reception")
	return guest

func _tick(session: HotelSession, count: int, verify: bool = false) -> void:
	for tick_index in count:
		session.tick(session.rules.tick)
		if verify:
			_restore_check(session)

func _restore_check(session: HotelSession) -> void:
	var snapshot := SessionSnapshot.capture(session)
	var result := SessionSnapshot.restore(JSON.parse_string(JSON.stringify(snapshot)))
	check(result.error.is_empty(), "valid snapshot: " + result.error)
	if not result.error.is_empty():
		return
	var resumed: HotelSession = result.session
	check(preload("res://tests/snapshot_comparison.gd").difference(snapshot, SessionSnapshot.capture(resumed), "roundtrip").is_empty(), "snapshot equality")
	if not session.player_work.job.is_empty():
		var key := String(session.player_work.job.kind) + ":" + String(session.player_work.job.phase)
		if not phases.has(key):
			phases[key] = true
			for index in 70:
				var reference := SessionSnapshot.restore(snapshot)
				var original: HotelSession = reference.session
				for next_tick in index + 1:
					original.tick(original.rules.tick)
				resumed.tick(resumed.rules.tick)
				check(preload("res://tests/snapshot_comparison.gd").difference(SessionSnapshot.capture(original), SessionSnapshot.capture(resumed), key).is_empty(), "deterministic continuation " + key)

func _finish(session: HotelSession, limit: int = 500, verify: bool = true) -> void:
	for index in limit:
		if session.player_work.job.is_empty():
			return
		_tick(session, 1, verify)
	check(false, "job completes within physical travel horizon")

func _checkin() -> void:
	var session := _hotel()
	var reception: RoomState = session.hotel.rooms[0]
	var bedroom: RoomState = session.hotel.rooms[1]
	check(session.player_work.start(session, "checkin", reception.id) == "no_arrived_guest" and session.player_work.worker_id == -1, "failed command creates no actor")
	var guest := _arrived(session)
	var behind := session.spawn_guest()
	_tick(session, 30)
	bedroom.dirty = true
	check(session.player_work.start(session, "checkin", reception.id) == "no_ready_bed", "dirty bedroom blocks booking")
	bedroom.dirty = false
	guest.money = 10
	check(session.player_work.start(session, "checkin", reception.id) == "no_ready_bed", "budget checked before reservation")
	guest.money = 320
	var cash: int = session.economy.cash
	check(session.player_work.start(session, "checkin", reception.id).is_empty(), "reserve FIFO head")
	check(session.player_work.reserved_guest() == guest.id and session.economy.cash == cash, "no payment at start")
	check(session.player_work.start(session, "cleaning", bedroom.id) == "player_busy", "single task")
	check(session.hire(HotelSession.EMPLOYEES[0]).is_empty(), "parallel employee")
	_finish(session)
	check(guest.checked_in and not behind.checked_in and session.guests.bookings == 1 and session.player_work.totals.checkins == 1, "only reserved head admitted once")
	check(guest.money == 180 and bedroom.income == 140 and session.economy.revenue == 140, "booking ledger reconciles")
	check(reception.condition == 98, "use wears reception")
	check(session.configure_employee(session.player_work.worker_id, -1) == "Selecione um funcionário.", "player excluded from staff assignment")
	check(session.recurring_costs().salaries == 35, "player has no salary")
	_tick(session, 100, true)
	check(session.guests.bookings == 1, "staff cannot duplicate booking or occupy used room")
	var cancelled := _hotel()
	_arrived(cancelled)
	check(cancelled.player_work.start(cancelled, "checkin", cancelled.hotel.rooms[0].id).is_empty(), "cancel fixture start")
	check(cancelled.player_work.cancel(cancelled) and not cancelled.player_work.cancel(cancelled), "cancel idempotent")
	_finish(cancelled)
	_tick(cancelled, 60, true)
	check(cancelled.guests.bookings == 0 and cancelled.economy.revenue == 0, "cancel no booking benefit")

func _cleaning_repair() -> void:
	var session := _hotel()
	var bedroom: RoomState = session.hotel.rooms[1]
	bedroom.dirty = true
	bedroom.condition = 40
	check(session.player_work.start(session, "cleaning", bedroom.id).is_empty(), "clean reserve")
	check(not session.demolish(bedroom.id).is_empty(), "demolition blocks reserved target")
	check(session.hire(HotelSession.EMPLOYEES[1]).is_empty(), "hire cleaner while manual reserved")
	_finish(session)
	check(not bedroom.dirty and bedroom.cleaning_by == -1 and session.employees.cleaned == 1 and session.player_work.totals.cleaned == 1, "manual clean releases and increments aggregate")
	var slowed: float = bedroom.duration()
	var cash: int = session.economy.cash
	var expenses: int = session.economy.expenses
	check(session.player_work.start(session, "repair", bedroom.id).is_empty(), "repair start")
	check(session.economy.cash == cash, "repair charges completion only")
	_finish(session)
	check(bedroom.condition == 100 and bedroom.repairing_by == -1 and bedroom.duration() < slowed and session.player_work.totals.repaired == 1, "repair restores efficiency")
	check(session.economy.cash == cash - 5 and session.economy.expenses == expenses + 5, "repair is operational cost")
	check(session.player_work.start(session, "repair", bedroom.id) == "no_repair_needed", "no repeated repair exploit")
	bedroom.condition = 20
	check(session.player_work.start(session, "repair", bedroom.id).is_empty(), "late budget repair")
	session.economy.cash = 0
	_finish(session)
	check(bedroom.condition == 20 and bedroom.repairing_by == -1 and session.player_work.last_result == "repair_cash", "cash rechecked before repair benefit")
	bedroom.wear(1000)
	check(bedroom.condition == 0 and is_equal_approx(bedroom.duration(), bedroom.definition().service_duration * 1.2), "wear clamped to 20 percent slowdown")

func _offer(session: HotelSession) -> int:
	var guest := _arrived(session)
	check(session.player_work.start(session, "checkin", session.hotel.rooms[0].id).is_empty(), "offer fixture checkin")
	_finish(session, 200, false)
	check(session.hotel.build(HotelCatalog.room(&"restaurant"), 5, 0) != null, "food source")
	for index in 100:
		session.tick(session.rules.tick)
		if guest.state == &"using" and guest.target_room == guest.bedroom:
			guest.needs.hunger = 60.0
			session.player_work.update_orders(session)
			return int(session.player_work.orders[0].id)
	check(false, "offer at physical bedroom")
	return -1

func _delivery() -> void:
	var session := _hotel()
	var order_id := _offer(session)
	var guest_id: int = session.player_work.order_by_id(order_id).guest_id
	var guest: ActorState = session.actors[guest_id]
	var money: int = guest.money
	var revenue: int = session.economy.revenue
	var source: RoomState = session.hotel.rooms[2]
	check(session.player_work.start_order(session, order_id).is_empty(), "start actual room service")
	check(guest.state == &"room_service_wait" and guest.money == money and session.economy.revenue == revenue, "reserve guest without early payout")
	check(session.set_room_tariff(source.id, 125).is_empty(), "tariff changes midorder")
	_finish(session)
	check(guest.money == money - 28 and source.income == 28 and session.economy.revenue == revenue + 28, "delivery honors pinned price")
	check(session.player_work.totals.delivered == 1 and guest.meals == 1 and session.guests.meals_served == 1 and guest.needs.hunger < 10, "real meal and hunger relief")
	check(not source.users.has(session.player_work.worker_id) and source.condition == 97 and session.player_work.start_order(session, order_id) == "order_expired", "release capacity and reject duplicate completion")
	_restore_check(session)

func _capacity_cancel() -> void:
	for desired_phase in ["travel_source", "source_queue", "prepare", "travel_delivery", "deliver"]:
		var session := _hotel()
		var order_id := _offer(session)
		var guest: ActorState = session.actors[session.player_work.order_by_id(order_id).guest_id]
		var source: RoomState = session.hotel.rooms[2]
		var cash: int = session.economy.cash
		var money: int = guest.money
		check(session.player_work.start_order(session, order_id).is_empty(), "cancel phase start")
		if desired_phase == "source_queue":
			for index in source.capacity():
				var diner := session.spawn_guest()
				diner.state = &"using"
				diner.target_room = source.id
				diner.target_floor = 0
				diner.timer = 40.0
				diner.agreed_price = source.price()
				source.users.append(diner.id)
		for index in 200:
			if session.player_work.job.get("phase") == desired_phase:
				break
			_tick(session, 1, true)
		check(session.player_work.job.get("phase") == desired_phase, "reach cancellation phase " + desired_phase)
		_restore_check(session)
		check(session.player_work.cancel(session), "cancel " + desired_phase)
		check(session.economy.cash == cash and guest.money == money and session.player_work.totals.delivered == 0 and guest.state == &"using", "cancel preserves budget and resumes bedroom")
		check(not source.users.has(session.player_work.worker_id) and not source.queue.members.has(session.player_work.worker_id), "cancel frees source reservation")
		_restore_check(session)

func _elevator_cancel() -> void:
	var session := _hotel()
	check(session.hotel.build(HotelCatalog.room(&"elevator"), 15, 0) != null, "elevator fixture")
	check(session.hotel.add_floor().is_empty(), "upper floor fixture")
	check(session.hotel.build(HotelCatalog.room(&"bedroom"), 0, 1) != null, "upper bedroom")
	var upstairs: RoomState = session.hotel.rooms.back()
	upstairs.dirty = true
	check(session.player_work.start(session, "cleaning", upstairs.id).is_empty(), "upstairs manual clean")
	for index in 400:
		if session.player_work.worker(session).state == &"riding":
			break
		_tick(session, 1, true)
	var actor := session.player_work.worker(session)
	check(actor.state == &"riding", "worker really rides lift")
	var lift := session.transport.lift_by_id(actor.elevator_id)
	check(session.player_work.cancel(session) and actor.state == &"riding" and lift.passengers.has(actor.id), "cancel keeps passenger safely onboard")
	check(upstairs.cleaning_by == -1 and upstairs.dirty and session.player_work.start(session, "repair", session.hotel.rooms[0].id) == "player_busy", "cancel releases room but blocks overlapping transit")
	_tick(session, 120, true)
	check(actor.floor_index == 1 and actor.state == &"idle", "cancel journey ends naturally")
	check(session.player_work.return_to_lobby(session).is_empty(), "return command")
	_tick(session, 200, true)
	check(actor.floor_index == 0 and actor.state == &"idle", "return uses lift")

func _legacy_malformed() -> void:
	var session := _hotel()
	var original := SessionSnapshot.capture(session)
	var legacy := original.duplicate(true)
	legacy.version = 7
	legacy.erase("player_work")
	for room: Dictionary in legacy.rooms:
		room.erase("condition")
		room.erase("repairing_by")
	var restored := SessionSnapshot.restore(legacy)
	check(restored.error.is_empty() and restored.session.player_work.worker_id == -1 and restored.session.hotel.rooms[0].condition == 100, "v7 migrates intact rooms without extra actor")
	for mutation in ["missing_work", "condition", "owner", "counter", "player_duplicate"]:
		var broken := original.duplicate(true)
		match mutation:
			"missing_work": broken.erase("player_work")
			"condition": broken.rooms[0].condition = -1
			"owner": broken.rooms[0].repairing_by = 88
			"counter": broken.player_work.totals.cleaned = 0.5
			"player_duplicate": broken.player_work.worker_id = 1
		check(not SessionSnapshot.restore(broken).error.is_empty(), "reject malformed " + mutation)

func _races_and_invalid_active() -> void:
	var session := _hotel()
	var guest := _arrived(session)
	guest.waiting = session.rules.patience_seconds * guest.archetype().patience_multiplier
	check(session.player_work.start(session, "checkin", 1).is_empty(), "reserve near patience limit")
	_tick(session, 1, true)
	check(session.player_work.job.is_empty() and session.player_work.last_result == "guest_left" and session.guests.bookings == 0, "head abandons before manual completion without charge")
	session = _hotel()
	guest = _arrived(session)
	guest.money = 140
	check(session.player_work.start(session, "checkin", 1).is_empty(), "budget race start")
	session.set_room_tariff(2, 125)
	_finish(session)
	check(not guest.checked_in and session.player_work.last_result == "no_ready_bed" and session.economy.revenue == 0, "budget rechecked at admission after tariff changes")
	session = _hotel()
	var bedroom: RoomState = session.hotel.rooms[1]
	bedroom.condition = 50
	check(session.player_work.start(session, "repair", 2).is_empty(), "repair travel fixture")
	_restore_check(session)
	check(session.player_work.cancel(session) and bedroom.condition == 50 and bedroom.repairing_by == -1, "repair travel cancel has no efficiency benefit")
	_restore_check(session)
	session = _hotel()
	var order_id := _offer(session)
	guest = session.actors[session.player_work.order_by_id(order_id).guest_id]
	check(session.player_work.start_order(session, order_id).is_empty(), "delivery patience fixture")
	guest.waiting = session.rules.patience_seconds * guest.archetype().patience_multiplier
	_tick(session, 1, true)
	check(session.player_work.job.is_empty() and session.player_work.last_result == "guest_left" and session.economy.revenue == 140 and not session.hotel.rooms[1].users.has(guest.id), "abandoned delivery frees bedroom service reservation and creates no meal charge")
	session = _hotel()
	order_id = _offer(session)
	check(session.player_work.start_order(session, order_id).is_empty(), "delivery source removal fixture")
	for index in 200:
		if session.player_work.job.get("phase") == "travel_delivery":
			break
		_tick(session, 1, true)
	check(session.demolish(3).is_empty(), "origin can be removed after preparation releases capacity")
	_tick(session, 1, true)
	check(session.player_work.job.is_empty() and session.player_work.totals.delivered == 0 and session.economy.revenue == 140, "removed origin cancels delivery safely")
	session = _hotel()
	order_id = _offer(session)
	check(session.player_work.start_order(session, order_id).is_empty(), "active malformed fixture")
	var original := SessionSnapshot.capture(session)
	for mutation in ["phase", "duration", "remaining", "guest", "source", "reservation", "worker", "duplicate_order"]:
		var broken := original.duplicate(true)
		match mutation:
			"phase": broken.player_work.job.phase = "deliver"
			"duration": broken.player_work.job.duration = -1
			"remaining": broken.player_work.job.remaining = 100
			"guest": broken.player_work.job.guest_id = -1
			"source": broken.player_work.job.source_room = 2
			"reservation": broken.rooms[1].occupant = -1
			"worker": broken.player_work.worker_id = 1
			"duplicate_order": broken.player_work.orders = [{"id": order_id, "guest_id": broken.player_work.job.guest_id, "expires": session.time + 20}]
		check(not SessionSnapshot.restore(broken).error.is_empty(), "reject contradictory active task " + mutation)

func _solo_policy(seed_value: int) -> void:
	var session := HotelSession.new(seed_value)
	session.economy.cash = session.player_work.rules.mobile_starting_cash
	check(session.hotel.build(HotelCatalog.room(&"reception"), 0, 0) != null, "solo reception")
	check(session.hotel.build(HotelCatalog.room(&"bedroom"), 3, 0) != null, "solo bedroom")
	session.opened = true
	var first_booking: float = -1
	var completed_guide: float = -1
	for index in 6000:
		var work := session.player_work
		if work.totals.checkins > 0 and session.hotel.rooms.size() == 2:
			check(session.hotel.build(HotelCatalog.room(&"restaurant"), 5, 0) != null, "solo food paid")
		if not work.busy(session):
			if not work.orders.is_empty() and work.totals.delivered == 0:
				work.start_order(session, int(work.orders[0].id))
			elif session.hotel.rooms[1].dirty:
				work.start(session, "cleaning", session.hotel.rooms[1].id)
			elif work.totals.cleaned > 0 and work.totals.repaired == 0:
				work.start(session, "repair", session.hotel.rooms[1].id)
			elif work.totals.checkins < 2:
				work.start(session, "checkin", session.hotel.rooms[0].id)
		session.tick(session.rules.tick)
		if first_booking < 0 and session.guests.bookings > 0:
			first_booking = session.time
		if work.totals.checkins > 0 and work.totals.delivered > 0 and work.totals.cleaned > 0 and work.totals.repaired > 0 and session.economy.cash >= 180:
			check(session.hire(HotelSession.EMPLOYEES[0]).is_empty(), "solo first hire affordable")
			completed_guide = session.time
			break
	check(first_booking > 0 and first_booking <= 30, "solo first booking within 30s seed " + str(seed_value))
	check(completed_guide > 0 and completed_guide <= 300, "solo to delegation within five minutes seed " + str(seed_value))
	check(session.economy.cash == 2400 + session.economy.revenue - session.economy.expenses - session.economy.capital_spent, "solo cash flow reconciliation")
	_restore_check(session)
	print(JSON.stringify({"seed": seed_value, "first_booking_seconds": first_booking, "solo_to_hire_seconds": completed_guide, "cash": session.economy.cash, "manual": session.player_work.totals}))

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
