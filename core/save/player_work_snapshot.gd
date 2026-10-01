class_name PlayerWorkSnapshot
extends RefCounted
## Reject partial/contradictory reservations before publishing a restored session.

const JOB_FIELDS: Array[String] = ["kind", "target_room", "source_room", "guest_id", "order_id", "phase", "remaining", "duration", "price", "resume_state", "resume_wait"]
const PHASES: Array[String] = ["travel", "action", "travel_source", "source_queue", "prepare", "travel_delivery", "deliver"]

static func capture(work: PlayerWorkSystem) -> Dictionary:
	return {"version": 1, "worker_id": work.worker_id, "next_order_id": work.next_order_id, "job": work.job.duplicate(true), "orders": work.orders.duplicate(true), "totals": work.totals.duplicate(true)}

static func restore(session: HotelSession, data: Variant) -> bool:
	if not data is Dictionary or data.size() != 6 or data.get("version") != 1 or not SessionSnapshot._integer(data.get("worker_id"), -1, session.next_actor_id - 1) or data.worker_id == 0 or not SessionSnapshot._integer(data.get("next_order_id"), 1, 1000000000):
		return false
	var work := session.player_work
	work.worker_id = int(data.worker_id)
	work.next_order_id = int(data.next_order_id)
	if not data.get("totals") is Dictionary or data.totals.size() != PlayerWorkSystem.COUNTERS.size():
		return false
	for key in PlayerWorkSystem.COUNTERS:
		if not SessionSnapshot._integer(data.totals.get(key), 0, 100000000):
			return false
		work.totals[key] = int(data.totals[key])
	var players: int = 0
	for actor: ActorState in session.actors.values():
		if actor.role == &"player":
			players += 1
			if actor.id != work.worker_id or actor.bedroom != -1 or actor.checked_in or actor.preferred_floor != -1 or actor.preferred_room != -1:
				return false
		elif String(actor.state).begins_with("manual_") or String(actor.destination_state).begins_with("manual_") or (actor.state == &"room_service_wait" and actor.role != &"guest"):
			return false
	if (work.worker_id == -1 and players != 0) or (work.worker_id != -1 and players != 1):
		return false
	if int(work.totals.checkins) > session.guests.bookings or int(work.totals.cleaned) > session.employees.cleaned or int(work.totals.delivered) > session.guests.meals_served:
		return false
	if work.worker_id == -1:
		for value: int in work.totals.values():
			if value != 0:
				return false
	if not data.get("orders") is Array or data.orders.size() > work.rules.pending_limit:
		return false
	var order_ids: Dictionary = {}
	var guest_ids: Dictionary = {}
	for item: Variant in data.orders:
		if not item is Dictionary or item.size() != 3 or not SessionSnapshot._integer(item.get("id"), 1, work.next_order_id - 1) or not SessionSnapshot._integer(item.get("guest_id"), 1, session.next_actor_id - 1) or not SessionSnapshot._number(item.get("expires")) or item.expires <= session.time or item.expires > session.time + work.rules.order_lifetime + SimulationRules.TIME_EPSILON:
			return false
		if order_ids.has(int(item.id)) or guest_ids.has(int(item.guest_id)) or not work._eligible(session, int(item.guest_id)):
			return false
		order_ids[int(item.id)] = true
		guest_ids[int(item.guest_id)] = true
		work.orders.append({"id": int(item.id), "guest_id": int(item.guest_id), "expires": float(item.expires)})
	if not data.get("job") is Dictionary:
		return false
	work.job = data.job.duplicate(true)
	var actor := work.worker(session)
	if work.job.is_empty():
		if actor != null and (actor.assignment != -1 or actor.target_room != -1 or actor.state not in [&"idle", &"walking", &"lift_queue", &"riding"] or actor.destination_state != &"idle"):
			return false
	else:
		if actor == null or not _job(session, order_ids):
			return false
	for room in session.hotel.rooms:
		if room.repairing_by >= 0 and (room.repairing_by != work.worker_id or work.job.get("kind") != "repair" or work.job.get("target_room") != room.id):
			return false
		if work.worker_id >= 0 and room.cleaning_by == work.worker_id and (work.job.get("kind") != "cleaning" or work.job.get("target_room") != room.id):
			return false
		if work.worker_id >= 0 and (room.users.has(work.worker_id) or room.queue.members.has(work.worker_id)) and (work.job.get("kind") != "room_service" or work.job.get("source_room") != room.id or work.job.get("phase") not in ["source_queue", "prepare"]):
			return false
	for guest: ActorState in session.actors.values():
		if guest.state == &"room_service_wait" and (work.job.get("kind") != "room_service" or work.job.get("guest_id") != guest.id):
			return false
	return true

static func _job(session: HotelSession, order_ids: Dictionary) -> bool:
	var work := session.player_work
	var job := work.job
	if job.size() != JOB_FIELDS.size():
		return false
	for key in JOB_FIELDS:
		if not job.has(key):
			return false
	if not job.kind is String or job.kind not in PlayerWorkSystem.KINDS or not job.phase is String or job.phase not in PHASES or not job.resume_state is String:
		return false
	for key in ["target_room", "source_room", "guest_id", "order_id", "price"]:
		if not SessionSnapshot._integer(job[key], -1, 1000000000):
			return false
		job[key] = int(job[key])
	for key in ["remaining", "duration", "resume_wait"]:
		if not SessionSnapshot._number(job[key]) or job[key] < 0 or job[key] > 100000000:
			return false
		job[key] = float(job[key])
	if job.remaining > job.duration + SimulationRules.TIME_EPSILON:
		return false
	var target := session.hotel.by_id(job.target_room)
	var actor := work.worker(session)
	if target == null or actor.role != &"player":
		return false
	var destination := target
	var expected: StringName = StringName("manual_" + String(job.kind))
	var guest: ActorState = session.actors.get(job.guest_id)
	if job.kind == "room_service":
		var source := session.hotel.by_id(job.source_room)
		if source == null or source.definition().category != &"service" or source.definition().need != &"hunger" or source.repairing_by >= 0 or guest == null or guest.role != &"guest" or guest.state != &"room_service_wait" or guest.bedroom != target.id or target.occupant != guest.id or guest.target_room != target.id or guest.floor_index != target.floor_index or not is_equal_approx(guest.x, target.center()) or guest.money < job.price or job.price < 1 or job.order_id < 1 or job.order_id >= work.next_order_id or order_ids.has(job.order_id) or job.resume_state not in ["using", "deciding"]:
			return false
		if target.users.has(guest.id) != (job.resume_state == "using"):
			return false
		if job.phase in ["travel_source", "source_queue", "prepare"]:
			destination = source
			expected = &"manual_prepare"
			if not is_equal_approx(job.duration, work.rules.preparation_seconds) or source.users.has(actor.id) != (job.phase == "prepare") or source.queue.members.has(actor.id) != (job.phase == "source_queue"):
				return false
		elif job.phase in ["travel_delivery", "deliver"]:
			expected = &"manual_deliver"
			if not is_equal_approx(job.duration, work.rules.delivery_seconds) or source.users.has(actor.id) or source.queue.members.has(actor.id):
				return false
		else:
			return false
	else:
		if job.phase not in ["travel", "action"] or job.source_room != -1 or job.order_id != -1 or job.price != 0 or job.resume_state != "" or job.resume_wait != 0:
			return false
		match String(job.kind):
			"checkin":
				if target.definition().category != &"reception" or guest == null or guest != work.checkin_guest(session, target) or not is_equal_approx(job.duration, work.rules.checkin_seconds):
					return false
			"cleaning":
				if target.definition().category != &"lodging" or not target.dirty or target.occupant >= 0 or target.cleaning_by != actor.id or target.repairing_by >= 0 or job.guest_id != -1 or not is_equal_approx(job.duration, work.rules.cleaning_seconds):
					return false
			"repair":
				if target.condition >= 100 or target.definition().category == &"transport" or target.occupant >= 0 or not target.users.is_empty() or target.repairing_by != actor.id or target.cleaning_by >= 0 or job.guest_id != -1 or not is_equal_approx(job.duration, work.rules.repair_seconds):
					return false
	if actor.assignment != destination.id or actor.target_room != destination.id or actor.target_floor != destination.floor_index or not is_equal_approx(actor.target_x, destination.center()) or actor.destination_state != expected:
		return false
	if actor.in_transit():
		return job.phase in ["travel", "travel_source", "travel_delivery"]
	return actor.state == expected and actor.floor_index == destination.floor_index and is_equal_approx(actor.x, destination.center())
