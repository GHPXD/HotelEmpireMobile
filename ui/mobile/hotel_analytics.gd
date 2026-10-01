class_name HotelAnalytics
extends RefCounted
## Read-only mobile projections. No presentation state enters the save schema.

static func summary(session: HotelSession) -> Dictionary:
	var result: Dictionary = {"beds": 0, "occupied": 0, "dirty": 0, "room_queue": 0, "lift_queue": 0, "staff": 0, "guests": 0, "happiness": 0.0, "longest_wait": 0.0}
	for room in session.hotel.rooms:
		result.room_queue += room.queue.members.size()
		if room.definition().category == &"lodging":
			result.beds += 1
			if room.occupant >= 0:
				result.occupied += 1
			if room.dirty:
				result.dirty += 1
	for lift in session.transport.lifts:
		result.lift_queue += lift.queue.members.size()
	for actor: ActorState in session.actors.values():
		if actor.role == &"guest":
			result.guests += 1
			result.happiness += actor.happiness
		elif actor.is_employee():
			result.staff += 1
		if actor.state in [&"checkin", &"service_queue", &"lift_queue"]:
			result.longest_wait = maxf(result.longest_wait, actor.waiting)
	result.happiness = result.happiness / result.guests if result.guests > 0 else 0.0
	result.occupancy = 100.0 * result.occupied / result.beds if result.beds > 0 else 0.0
	result.costs = session.recurring_costs()
	result.satisfaction_groups = satisfaction_groups(session)
	return result

static func satisfaction_groups(session: HotelSession) -> Dictionary:
	var groups := {"checked_in": {"count": 0, "average": 0.0}, "not_checked_in": {"count": 0, "average": 0.0}}
	for actor: ActorState in session.actors.values():
		if actor.role != &"guest":
			continue
		var group: Dictionary = groups["checked_in" if actor.checked_in else "not_checked_in"]
		group.count += 1
		group.average += actor.happiness
	for group: Dictionary in groups.values():
		group.average = group.average / group.count if group.count > 0 else 0.0
	return groups

static func rooms(session: HotelSession, category: StringName = &"", floor_index: int = -1, status: int = 0) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for room in session.hotel.rooms:
		var definition := room.definition()
		if not category.is_empty() and definition.category != category:
			continue
		if floor_index >= 0 and room.floor_index != floor_index and definition.category != &"transport":
			continue
		var queue: int = room.queue.members.size()
		var occupied: bool = room.occupant >= 0 or not room.users.is_empty()
		var lift := session.transport.lift_by_id(room.id)
		if lift != null:
			queue = lift.queue.members.size()
			occupied = not lift.passengers.is_empty()
		if (status == 1 and queue == 0) or (status == 2 and not room.dirty) or (status == 3 and not occupied):
			continue
		rows.append({"id": room.id, "name": definition.display_name, "floor": room.floor_index, "transport": lift != null, "queue": queue, "dirty": room.dirty, "occupied": occupied, "level": room.level, "income": room.income})
		rows.back()["checkin_reason"] = CheckinDiagnostics.reason(session, room) if definition.category == &"reception" else ""
		rows.back()["lift_metrics"] = elevator(session, lift) if lift != null else {}
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.queue > b.queue if a.queue != b.queue else a.id < b.id)
	return rows

static func elevator(session: HotelSession, lift: ElevatorState) -> Dictionary:
	var current_max: float = 0.0
	for id: int in lift.queue.members:
		var actor: ActorState = session.actors.get(id)
		if actor != null:
			current_max = maxf(current_max, actor.waiting)
	return {"passengers": lift.passengers.size(), "capacity": lift.capacity,
		"queue": lift.queue.members.size(), "current_max": current_max,
		"boarded": lift.boarded, "delivered": lift.delivered,
		"average_wait": lift.average_wait(), "max_wait": lift.wait_max}
