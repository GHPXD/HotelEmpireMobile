class_name EmployeeSystem
extends RefCounted

var cleaned: int = 0
var rules: SimulationRules

func _init(config: SimulationRules) -> void:
	rules = config

func step(actors: Dictionary, hotel: HotelModel, transport: TransportSystem, delta: float) -> void:
	for actor: ActorState in actors.values():
		if actor.role not in [&"receptionist", &"cleaner"]:
			continue
		if actor.state == &"idle":
			_assign(actor, actors, hotel, transport)
		elif actor.state == &"cleaning":
			actor.workload += delta
			actor.timer -= delta * actor.skill
			if actor.timer <= SimulationRules.TIME_EPSILON:
				var room := hotel.by_id(actor.assignment)
				if room != null:
					room.dirty = false
					room.cleaning_by = -1
					cleaned += 1
				actor.assignment = -1
				actor.state = &"idle"
		elif actor.state == &"working":
			actor.workload += delta
			if hotel.by_id(actor.assignment) == null or (actor.preferred_room >= 0 and actor.assignment != actor.preferred_room):
				actor.assignment = -1
				actor.state = &"idle"

func _assign(actor: ActorState, actors: Dictionary, hotel: HotelModel, transport: TransportSystem) -> void:
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
		elif actor.role == &"cleaner" and room.dirty and room.cleaning_by < 0 and room.repairing_by < 0:
			room.cleaning_by = actor.id
			actor.assignment = room.id
			actor.timer = rules.cleaning_seconds
			actor.travel_to(room.center(), room.floor_index, &"cleaning")
			return
