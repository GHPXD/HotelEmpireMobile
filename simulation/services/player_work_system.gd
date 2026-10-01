class_name PlayerWorkSystem
extends RefCounted
## One physical worker; commands reserve targets, tick completion owns effects.

const KINDS: Array[String] = ["checkin", "cleaning", "repair", "room_service"]
const COUNTERS: Array[String] = ["checkins", "cleaned", "repaired", "delivered", "cancelled"]
var rules: PlayerWorkRules = preload("res://data/player_work.tres")
var worker_id: int = -1
var next_order_id: int = 1
var job: Dictionary = {}
var orders: Array[Dictionary] = []
var totals: Dictionary = {"checkins": 0, "cleaned": 0, "repaired": 0, "delivered": 0, "cancelled": 0}
var revision: int = 0
var last_result: String = ""

func reserved_guest() -> int:
	return int(job.guest_id) if job.get("kind") == "checkin" else -1

func worker(session: HotelSession) -> ActorState:
	return session.actors.get(worker_id)

func busy(session: HotelSession) -> bool:
	var actor := worker(session)
	return not job.is_empty() or (actor != null and actor.in_transit())

func task_error(session: HotelSession, kind: String, target_id: int) -> String:
	if kind not in KINDS:
		return "unknown_task"
	if busy(session):
		return "player_busy"
	var target := session.hotel.by_id(target_id)
	if target == null:
		return "missing_room"
	var actor := worker(session)
	var floor_index: int = actor.floor_index if actor != null else 0
	if not session.transport.accessible(floor_index, target.floor_index):
		return "no_access"
	match kind:
		"checkin":
			if target.definition().category != &"reception" or target.repairing_by >= 0:
				return "invalid_reception"
			var guest := checkin_guest(session, target)
			if guest == null:
				return "no_arrived_guest"
			if session.guests.available_bed(guest, session.hotel, session.transport) == null:
				return "no_ready_bed"
		"cleaning":
			if target.definition().category != &"lodging" or not target.dirty or target.occupant >= 0:
				return "no_dirty_room"
			if target.cleaning_by >= 0 or target.repairing_by >= 0:
				return "room_reserved"
		"repair":
			if target.definition().category == &"transport" or target.condition >= 100:
				return "no_repair_needed"
			if target.occupant >= 0 or target.cleaning_by >= 0 or target.repairing_by >= 0 or not target.users.is_empty():
				return "room_reserved"
			if session.economy.cash < rules.repair_cost:
				return "repair_cash"
		"room_service":
			return "use_order"
	return ""

func checkin_guest(session: HotelSession, reception: RoomState) -> ActorState:
	if reception.queue.members.is_empty():
		return null
	var guest: ActorState = session.actors.get(reception.queue.members[0])
	return guest if guest != null and guest.role == &"guest" and guest.state == &"checkin" and not guest.checked_in else null

func start(session: HotelSession, kind: String, target_id: int) -> String:
	var error := task_error(session, kind, target_id)
	if not error.is_empty():
		return error
	var target := session.hotel.by_id(target_id)
	var actor := _ensure_worker(session)
	var duration: float = rules.checkin_seconds if kind == "checkin" else (rules.cleaning_seconds if kind == "cleaning" else rules.repair_seconds)
	job = {"kind": kind, "target_room": target_id, "source_room": -1, "guest_id": -1, "order_id": -1, "phase": "travel", "remaining": duration, "duration": duration, "price": 0, "resume_state": "", "resume_wait": 0.0}
	if kind == "checkin":
		job.guest_id = checkin_guest(session, target).id
	elif kind == "cleaning":
		target.cleaning_by = actor.id
	else:
		target.repairing_by = actor.id
	_send(actor, target, StringName("manual_" + kind))
	_changed("started")
	return ""

func order_error(session: HotelSession, order_id: int) -> String:
	if busy(session):
		return "player_busy"
	var order := order_by_id(order_id)
	if order.is_empty() or not _eligible(session, int(order.guest_id)):
		return "order_expired"
	var guest: ActorState = session.actors[order.guest_id]
	var actor := worker(session)
	var floor_index: int = actor.floor_index if actor != null else 0
	if food_source(session, guest, floor_index) == null:
		return "no_food_source"
	return ""

func start_order(session: HotelSession, order_id: int) -> String:
	var error := order_error(session, order_id)
	if not error.is_empty():
		return error
	var order := order_by_id(order_id)
	var guest: ActorState = session.actors[order.guest_id]
	var actor := _ensure_worker(session)
	var source := food_source(session, guest, actor.floor_index)
	job = {"kind": "room_service", "target_room": guest.bedroom, "source_room": source.id, "guest_id": guest.id, "order_id": order_id, "phase": "travel_source", "remaining": rules.preparation_seconds, "duration": rules.preparation_seconds, "price": source.price(), "resume_state": String(guest.state), "resume_wait": guest.waiting}
	guest.state = &"room_service_wait"
	guest.waiting = 0
	orders.erase(order)
	_send(actor, source, &"manual_prepare")
	_changed("started")
	return ""

func food_source(session: HotelSession, guest: ActorState, from_floor: int) -> RoomState:
	for room in session.hotel.rooms:
		if room.definition().category == &"service" and room.definition().need == &"hunger" and room.repairing_by < 0 and room.price() <= guest.money and session.transport.accessible(from_floor, room.floor_index) and session.transport.accessible(room.floor_index, guest.floor_index):
			return room
	return null

func order_by_id(id: int) -> Dictionary:
	for order in orders:
		if order.id == id:
			return order
	return {}

func update_orders(session: HotelSession) -> void:
	for index in range(orders.size() - 1, -1, -1):
		if float(orders[index].expires) <= session.time or not _eligible(session, int(orders[index].guest_id)):
			orders.remove_at(index)
	if orders.size() >= rules.pending_limit:
		return
	for actor: ActorState in session.actors.values():
		if not _eligible(session, actor.id) or food_source(session, actor, actor.floor_index) == null:
			continue
		var listed: bool = false
		for order in orders:
			listed = listed or order.guest_id == actor.id
		if not listed:
			orders.append({"id": next_order_id, "guest_id": actor.id, "expires": session.time + rules.order_lifetime})
			next_order_id += 1
		if orders.size() >= rules.pending_limit:
			break

func _eligible(session: HotelSession, id: int) -> bool:
	var guest: ActorState = session.actors.get(id)
	if guest == null or guest.role != &"guest" or not guest.checked_in or guest.bedroom < 0 or guest.state not in [&"using", &"deciding"] or guest.target_room != guest.bedroom or float(guest.needs.hunger) < rules.order_hunger:
		return false
	var bedroom := session.hotel.by_id(guest.bedroom)
	return bedroom != null and bedroom.occupant == id and guest.floor_index == bedroom.floor_index and is_equal_approx(guest.x, bedroom.center())

func step(session: HotelSession, delta: float) -> void:
	if job.is_empty():
		return
	var actor := worker(session)
	var target := session.hotel.by_id(int(job.target_room))
	if actor == null or target == null:
		cancel(session, "target_lost")
		return
	if job.kind == "checkin":
		var guest := checkin_guest(session, target)
		if guest == null or guest.id != job.guest_id:
			cancel(session, "guest_left")
			return
	elif job.kind == "room_service":
		var guest: ActorState = session.actors.get(int(job.guest_id))
		if guest == null or guest.state != &"room_service_wait" or guest.bedroom != target.id or target.occupant != guest.id:
			cancel(session, "guest_left")
			return
		_step_delivery(session, actor, guest, delta)
		return
	if actor.in_transit():
		return
	if job.phase == "travel":
		job.phase = "action"
		_changed("working")
	job.remaining = maxf(0, float(job.remaining) - delta)
	actor.timer = float(job.remaining)
	actor.workload += delta
	if float(job.remaining) > SimulationRules.TIME_EPSILON:
		return
	match String(job.kind):
		"checkin":
			var guest: ActorState = session.actors.get(int(job.guest_id))
			if guest == null or not session.guests.admit(guest, session.hotel, session.transport, session.time):
				cancel(session, "no_ready_bed")
				return
			totals.checkins += 1
		"cleaning":
			target.dirty = false
			totals.cleaned += 1
			session.employees.cleaned += 1
		"repair":
			if session.economy.cash < rules.repair_cost:
				cancel(session, "repair_cash")
				return
			session.economy.transact(-rules.repair_cost, "Reparo simples", session.time)
			target.condition = 100
			totals.repaired += 1
	_finish(session)

func reconcile(session: HotelSession) -> void:
	if job.is_empty():
		return
	var target := session.hotel.by_id(int(job.target_room))
	if job.kind == "checkin":
		var guest := checkin_guest(session, target) if target != null else null
		if guest == null or guest.id != job.guest_id:
			cancel(session, "guest_left")
	elif job.kind == "room_service":
		var guest: ActorState = session.actors.get(int(job.guest_id))
		if guest == null or guest.state != &"room_service_wait" or target == null or guest.bedroom != target.id or target.occupant != guest.id:
			cancel(session, "guest_left")

func _step_delivery(session: HotelSession, actor: ActorState, guest: ActorState, delta: float) -> void:
	var source := session.hotel.by_id(int(job.source_room))
	if source == null or source.repairing_by >= 0 or guest.money < int(job.price):
		cancel(session, "order_unavailable")
		return
	if actor.in_transit():
		return
	if job.phase in ["travel_source", "source_queue"]:
		if not source.queue.join(actor.id):
			cancel(session, "source_full")
			return
		if job.phase != "source_queue":
			job.phase = "source_queue"
			_changed("waiting_capacity")
		if source.queue.members[0] != actor.id or source.users.size() >= source.capacity():
			return
		source.queue.take()
		source.users.append(actor.id)
		job.phase = "prepare"
		_changed("preparing")
	elif job.phase == "travel_delivery":
		job.phase = "deliver"
		_changed("delivering")
	job.remaining = maxf(0, float(job.remaining) - delta)
	actor.timer = float(job.remaining)
	actor.workload += delta
	if float(job.remaining) > SimulationRules.TIME_EPSILON:
		return
	if job.phase == "prepare":
		source.users.erase(actor.id)
		job.phase = "travel_delivery"
		job.duration = rules.delivery_seconds
		job.remaining = rules.delivery_seconds
		_send(actor, session.hotel.by_id(int(job.target_room)), &"manual_deliver")
		_changed("delivery_travel")
	else:
		guest.money -= int(job.price)
		source.income += int(job.price)
		session.economy.transact(int(job.price), "Room service", session.time)
		guest.needs.hunger = maxf(0, float(guest.needs.hunger) - source.definition().relief)
		guest.happiness = minf(100, guest.happiness + 3 + source.satisfaction_bonus())
		guest.meals += 1
		guest.service_uses += 1
		session.guests.meals_served += 1
		session.guests.service_uses += 1
		source.wear(rules.service_wear)
		totals.delivered += 1
		_finish(session)

func cancel(session: HotelSession, reason: String = "cancelled") -> bool:
	if job.is_empty():
		return false
	totals.cancelled += 1
	_release(session)
	_changed(reason)
	return true

func return_to_lobby(session: HotelSession) -> String:
	if busy(session):
		return "player_busy"
	var actor := worker(session)
	if actor == null:
		return "player_not_present"
	if not session.transport.accessible(actor.floor_index, 0):
		return "no_access"
	actor.assignment = -1
	actor.target_room = -1
	actor.travel_to(0.5, 0, &"idle")
	_changed("returning")
	return ""

func _finish(session: HotelSession) -> void:
	_release(session)
	_changed("completed")

func _release(session: HotelSession) -> void:
	var actor := worker(session)
	var target := session.hotel.by_id(int(job.target_room))
	if target != null and actor != null:
		if target.cleaning_by == actor.id:
			target.cleaning_by = -1
		if target.repairing_by == actor.id:
			target.repairing_by = -1
	if job.kind == "room_service":
		var source := session.hotel.by_id(int(job.source_room))
		if source != null and actor != null:
			source.queue.leave(actor.id)
			source.users.erase(actor.id)
		var guest: ActorState = session.actors.get(int(job.guest_id))
		if guest != null:
			if guest.state == &"room_service_wait":
				guest.state = StringName(job.resume_state)
				guest.waiting = float(job.resume_wait)
			elif guest.state == &"deciding" and target != null:
				target.users.erase(guest.id)
	if actor != null:
		actor.assignment = -1
		actor.target_room = -1
		actor.timer = 0
		actor.destination_state = &"idle"
		if not actor.in_transit():
			actor.state = &"idle"
	job = {}

func _ensure_worker(session: HotelSession) -> ActorState:
	var actor := worker(session)
	if actor == null:
		actor = ActorState.new()
		actor.id = session.next_actor_id
		session.next_actor_id += 1
		worker_id = actor.id
		actor.role = &"player"
		actor.display_name = "Player"
		actor.state = &"idle"
		actor.speed = rules.walk_speed
		session.actors[actor.id] = actor
	return actor

func _send(actor: ActorState, room: RoomState, arrival: StringName) -> void:
	actor.assignment = room.id
	actor.target_room = room.id
	actor.travel_to(room.center(), room.floor_index, arrival)
	actor.timer = float(job.remaining)

func _changed(result: String) -> void:
	revision += 1
	last_result = result
