class_name GuestSystem
extends RefCounted

var completed: int = 0
var meals_served: int = 0
var service_uses: int = 0
var bookings: int = 0
var score_total: float = 0.0
var reputation: float = 65.0
var rules: SimulationRules
const REVIEW_LIMIT: int = 20
var reviews: Array[Dictionary] = []

func _init(config: SimulationRules) -> void:
	rules = config

func step(actors: Dictionary, hotel: HotelModel, transport: TransportSystem, delta: float, time: float) -> void:
	var departures: Array[int] = []
	# Geometry cannot change inside this step. Filter once, preserving build order.
	var arrival_rooms := _arrival_rooms(hotel)
	for actor: ActorState in actors.values():
		if actor.role != &"guest":
			continue
		actor.age += delta
		actor.needs.hunger = minf(100, actor.needs.hunger + delta * rules.hunger_rate)
		actor.needs.energy = minf(100, actor.needs.energy + delta * rules.energy_rate)
		actor.needs.entertainment = minf(100, actor.needs.entertainment + delta * actor.archetype().entertainment_rate)
		actor.needs.comfort = minf(100, actor.needs.comfort + delta * 0.1)
		if actor.needs.hunger > 90:
			actor.happiness = maxf(0, actor.happiness - delta * 0.15)
		match actor.state:
			&"arriving":
				_arrive(actor, arrival_rooms)
			&"checkin":
				_check_in(actor, actors, hotel, transport, delta, time)
			&"deciding":
				_choose(actor, hotel, transport)
			&"service_queue":
				_queue_service(actor, hotel, delta)
			&"using":
				_use(actor, hotel, delta, time)
			&"exit":
				_release_room(actor, hotel)
				completed += 1
				score_total += actor.happiness
				reputation = clampf(lerpf(reputation, actor.happiness, 0.12), 0, 100)
				reviews.append({"guest_id": actor.id, "profile": String(actor.archetype_id), "time": time, "score": actor.happiness, "checked_in": actor.checked_in, "meals": actor.meals, "services": actor.service_uses, "sleeps": actor.sleeps})
				if reviews.size() > REVIEW_LIMIT:
					reviews.pop_front()
				departures.append(actor.id)
	for id in departures:
		actors.erase(id)

func _arrival_rooms(hotel: HotelModel) -> Array[RoomState]:
	var result: Array[RoomState] = []
	for room in hotel.rooms:
		if room.definition().category == &"reception":
			result.append(room)
	return result

func _arrive(actor: ActorState, arrival_rooms: Array[RoomState]) -> void:
	for room in arrival_rooms:
		if room.definition().category == &"reception" and room.queue.join(actor.id):
			actor.target_room = room.id
			actor.travel_to(room.center(), room.floor_index, &"checkin")
			return
	actor.happiness = minf(actor.happiness, 25)
	actor.travel_to(-0.8, 0, &"exit")

func _check_in(actor: ActorState, actors: Dictionary, hotel: HotelModel, transport: TransportSystem, delta: float, time: float) -> void:
	var reception := hotel.by_id(actor.target_room)
	if reception == null:
		actor.travel_to(-0.8, 0, &"exit")
		return
	actor.waiting += delta
	actor.happiness = maxf(0, actor.happiness - delta * rules.waiting_penalty)
	if actor.waiting > rules.patience_seconds * actor.archetype().patience_multiplier + SimulationRules.TIME_EPSILON:
		reception.queue.leave(actor.id)
		actor.happiness = minf(actor.happiness, 35)
		actor.travel_to(-0.8, 0, &"exit")
		return
	if reception.queue.members.is_empty() or reception.queue.members[0] != actor.id:
		return
	var staffed: bool = false
	for employee: ActorState in actors.values():
		if employee.role == &"receptionist" and employee.assignment == reception.id and employee.state == &"working":
			staffed = true
			break
	if not staffed:
		return
	actor.timer += delta
	if actor.timer + SimulationRules.TIME_EPSILON < reception.duration():
		return
	for room in hotel.rooms:
		var definition := room.definition()
		if definition.category != &"lodging" or room.dirty or room.occupant >= 0:
			continue
		if actor.money < room.price() or not transport.accessible(actor.floor_index, room.floor_index):
			continue
		room.occupant = actor.id
		actor.bedroom = room.id
		actor.checked_in = true
		actor.happiness = clampf(actor.happiness + room.lodging_value_delta(actor.archetype()), 0, 100)
		actor.money -= room.price()
		room.income += room.price()
		hotel.economy.transact(room.price(), "Hospedagem", time)
		bookings += 1
		reception.queue.leave(actor.id)
		actor.target_room = room.id
		actor.timer = 0
		actor.travel_to(room.center(), room.floor_index, &"service_queue")
		return

func _choose(actor: ActorState, hotel: HotelModel, transport: TransportSystem) -> void:
	if actor.age + SimulationRules.TIME_EPSILON >= rules.stay_seconds * actor.archetype().stay_multiplier or actor.happiness <= 10:
		_release_room(actor, hotel)
		actor.travel_to(-0.8, 0, &"exit")
		return
	var best: RoomState
	var best_score: float = -INF
	actor.utility_scores.clear()
	for room in hotel.rooms:
		var definition := room.definition()
		if definition.need.is_empty() or (definition.category == &"lodging" and room.id != actor.bedroom):
			continue
		if definition.category == &"service" and actor.money < room.price():
			continue
		if not transport.accessible(actor.floor_index, room.floor_index) or room.queue.members.size() >= room.queue.capacity:
			continue
		var distance: float = absf(room.center() - actor.x) + absf(room.floor_index - actor.floor_index) * 3.0
		var urgency: float = float(actor.needs.get(String(definition.need), 0.0))
		if definition.need == &"entertainment":
			urgency *= actor.archetype().entertainment_weight
		# Relief matters: a snack need not dominate a meal when hunger is high.
		var benefit: float = minf(urgency, definition.relief)
		var score: float = benefit - distance * 0.6 - room.queue.members.size() * 4.0
		if definition.category == &"service":
			score -= room.price() * actor.archetype().price_weight
			score -= room.duration() * actor.archetype().duration_weight
			score += room.satisfaction_bonus()
		actor.utility_scores[str(room.id)] = score
		if score > best_score:
			best = room
			best_score = score
	if best != null:
		actor.target_room = best.id
		actor.travel_to(best.center(), best.floor_index, &"service_queue")
	else:
		_release_room(actor, hotel)
		actor.travel_to(-0.8, 0, &"exit")

func _queue_service(actor: ActorState, hotel: HotelModel, delta: float) -> void:
	var room := hotel.by_id(actor.target_room)
	if room == null:
		actor.state = &"deciding"
		return
	if room.definition().category == &"service" and actor.money < room.price():
		room.queue.leave(actor.id)
		actor.state = &"deciding"
		return
	if not room.queue.join(actor.id):
		actor.state = &"deciding"
		return
	actor.waiting += delta
	if room.queue.members[0] == actor.id and room.users.size() < room.capacity():
		room.queue.take()
		room.users.append(actor.id)
		actor.timer = room.duration()
		actor.agreed_price = room.price() if room.definition().category == &"service" else 0
		actor.state = &"using"
	elif actor.waiting > rules.patience_seconds * actor.archetype().patience_multiplier + SimulationRules.TIME_EPSILON:
		room.queue.leave(actor.id)
		actor.state = &"deciding"
	else:
		actor.happiness = maxf(0, actor.happiness - delta * rules.waiting_penalty)

func _use(actor: ActorState, hotel: HotelModel, delta: float, time: float) -> void:
	actor.timer -= delta
	if actor.timer > SimulationRules.TIME_EPSILON:
		return
	var room := hotel.by_id(actor.target_room)
	if room != null:
		var definition := room.definition()
		room.users.erase(actor.id)
		actor.needs[String(definition.need)] = maxf(0, float(actor.needs.get(String(definition.need), 0)) - definition.relief)
		actor.happiness = minf(100, actor.happiness + 3 + room.satisfaction_bonus())
		if definition.category == &"service":
			actor.money -= actor.agreed_price
			room.income += actor.agreed_price
			hotel.economy.transact(actor.agreed_price, definition.display_name, time)
			actor.service_uses += 1
			service_uses += 1
			if definition.need == &"hunger":
				actor.meals += 1
				meals_served += 1
		else:
			actor.sleeps += 1
	actor.state = &"deciding"

func _release_room(actor: ActorState, hotel: HotelModel) -> void:
	# Rejected arrivals never booked a room; -1 is already the released state.
	if actor.bedroom == -1:
		return
	var room := hotel.by_id(actor.bedroom)
	if room != null and room.occupant == actor.id:
		room.occupant = -1
		room.dirty = true
	actor.bedroom = -1
