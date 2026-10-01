class_name EmployeeSystem
extends RefCounted

var cleaned: int = 0
var dismissed: int = 0
var revision: int = 0
var last_event: Dictionary = {}
var rules: SimulationRules

func _init(config: SimulationRules) -> void:
	rules = config

func complete(actor: ActorState) -> void:
	var promoted := actor.ensure_employee().award(actor.role)
	revision += 1
	last_event = {"id": actor.id, "role": String(actor.role), "level": actor.employee.level(), "result": "promoted" if promoted else "completed"}

func step(actors: Dictionary, hotel: HotelModel, transport: TransportSystem, delta: float) -> void:
	var departures: Array[int] = []
	for actor: ActorState in actors.values():
		if not actor.is_employee():
			continue
		var progress := actor.ensure_employee()
		if progress.dismiss_requested:
			if actor.state == &"employee_exit":
				departures.append(actor.id)
			elif not actor.in_transit():
				actor.travel_to(-0.8, 0, &"employee_exit")
			continue
		if actor.state == &"idle" and progress.duty_enabled:
			_assign(actor, actors, hotel, transport)
		elif actor.state == &"cleaning":
			actor.workload += delta
			actor.timer -= delta * actor.work_efficiency()
			if actor.timer <= SimulationRules.TIME_EPSILON:
				var room := hotel.by_id(actor.assignment)
				if room != null and room.cleaning_by == actor.id and room.dirty:
					room.dirty = false
					room.dirty_since = -1.0
					room.cleaning_quality_bonus = progress.quality()
					room.cleaning_by = -1
					cleaned += 1
					complete(actor)
				actor.assignment = -1
				actor.state = &"idle"
		elif actor.state == &"working":
			actor.workload += delta
			var room := hotel.by_id(actor.assignment)
			var finish_current := false
			if room != null and not room.queue.members.is_empty():
				var head: ActorState = actors.get(room.queue.members[0])
				finish_current = head != null and head.state == &"checkin" and head.timer > 0
			if room == null or (actor.preferred_room >= 0 and actor.assignment != actor.preferred_room) or (not progress.duty_enabled and not finish_current):
				actor.assignment = -1
				actor.state = &"idle"
	for id in departures:
		var actor: ActorState = actors[id]
		dismissed += 1
		revision += 1
		last_event = {"id": id, "role": String(actor.role), "level": actor.employee.level(), "result": "dismissed"}
		actors.erase(id)

func _assign(actor: ActorState, actors: Dictionary, hotel: HotelModel, transport: TransportSystem) -> void:
	var candidate: RoomState
	for room in hotel.rooms:
		if actor.preferred_room >= 0 and room.id != actor.preferred_room:
			continue
		if actor.preferred_floor >= 0 and room.floor_index != actor.preferred_floor:
			continue
		if not transport.accessible(actor.floor_index, room.floor_index):
			continue
		if actor.role == &"receptionist" and room.definition().category == &"reception":
			var assigned: bool = false
			for other: ActorState in actors.values():
				if other.id != actor.id and other.role == &"receptionist" and (other.assignment == room.id or other.preferred_room == room.id):
					assigned = true
			if not assigned:
				actor.assignment = room.id
				actor.travel_to(room.center(), room.floor_index, &"working")
				return
		elif actor.role == &"cleaner" and room.dirty and room.occupant < 0 and room.cleaning_by < 0 and room.repairing_by < 0:
			if candidate == null or _cleaning_precedes(actor, room, candidate):
				candidate = room
	if actor.role != &"cleaner" or candidate == null:
		return
	candidate.cleaning_by = actor.id
	actor.assignment = candidate.id
	actor.timer = rules.cleaning_seconds
	actor.travel_to(candidate.center(), candidate.floor_index, &"cleaning")

func _cleaning_precedes(actor: ActorState, a: RoomState, b: RoomState) -> bool:
	if actor.employee.priority == &"nearest":
		var distance_a := absf(a.center() - actor.x) + 3.0 * absf(a.floor_index - actor.floor_index)
		var distance_b := absf(b.center() - actor.x) + 3.0 * absf(b.floor_index - actor.floor_index)
		if not is_equal_approx(distance_a, distance_b):
			return distance_a < distance_b
	return a.dirty_since < b.dirty_since if not is_equal_approx(a.dirty_since, b.dirty_since) else a.id < b.id
