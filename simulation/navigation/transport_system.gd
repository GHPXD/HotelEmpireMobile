class_name TransportSystem
extends RefCounted

var lifts: Array[ElevatorState] = []
var path_requests: int = 0
var rules: SimulationRules

func _init(config: SimulationRules) -> void:
	rules = config

func sync(hotel: HotelModel) -> void:
	for room in hotel.rooms:
		if room.definition().category != &"transport":
			continue
		var lift := lift_by_id(room.id)
		if lift == null:
			lift = ElevatorState.new()
			lift.room_id = room.id
			lift.column = room.center()
			lifts.append(lift)
		lift.capacity = room.capacity()
		lift.speed_multiplier = room.speed_multiplier()
	for index in range(lifts.size() - 1, -1, -1):
		if hotel.by_id(lifts[index].room_id) == null:
			lifts.remove_at(index)

func lift_by_id(id: int) -> ElevatorState:
	for lift in lifts:
		if lift.room_id == id:
			return lift
	return null

func accessible(from_floor: int, to_floor: int) -> bool:
	return from_floor == to_floor or not lifts.is_empty()

func step(actors: Dictionary, delta: float) -> void:
	for actor: ActorState in actors.values():
		if actor.state == &"walking":
			_walk(actor, delta)
		elif actor.state == &"lift_queue":
			actor.waiting += delta
			if actor.role == &"guest" and actor.lift_queue_seconds >= 0:
				actor.lift_queue_seconds += delta
			actor.happiness = maxf(0, actor.happiness - delta * rules.waiting_penalty)
	for lift in lifts:
		_step_lift(lift, actors, delta)

func _walk(actor: ActorState, delta: float) -> void:
	var goal_x: float = actor.target_x
	if actor.floor_index != actor.target_floor:
		var lift := lift_by_id(actor.elevator_id)
		if lift == null:
			lift = _choose_lift(actor)
			if lift == null:
				return
			actor.elevator_id = lift.room_id
			path_requests += 1
		goal_x = lift.column
	actor.x = move_toward(actor.x, goal_x, actor.walking_speed() * delta)
	if not is_equal_approx(actor.x, goal_x):
		return
	if actor.floor_index == actor.target_floor:
		actor.state = actor.destination_state
		actor.elevator_id = -1
		actor.waiting = 0
	else:
		var lift := lift_by_id(actor.elevator_id)
		if lift.queue.join(actor.id):
			actor.state = &"lift_queue"
			actor.waiting = 0

func _choose_lift(actor: ActorState) -> ElevatorState:
	var best: ElevatorState
	var best_cost: float = INF
	for lift in lifts:
		var cost: float = absf(actor.x - lift.column) + absf(actor.floor_index - lift.floor_position) * 2.0 + lift.queue.members.size() * 2.0
		if cost < best_cost:
			best_cost = cost
			best = lift
	return best

func _step_lift(lift: ElevatorState, actors: Dictionary, delta: float) -> void:
	if not lift.passengers.is_empty() or not lift.queue.members.is_empty():
		lift.busy_seconds += delta
	if lift.door_timer > SimulationRules.TIME_EPSILON:
		lift.door_timer = maxf(0, lift.door_timer - delta)
		return
	if not is_equal_approx(lift.floor_position, float(lift.target_floor)):
		lift.floor_position = move_toward(lift.floor_position, lift.target_floor, rules.elevator_speed * lift.speed_multiplier * delta)
		return
	var exchanged: bool = false
	for id in lift.passengers.duplicate():
		var actor: ActorState = actors.get(id)
		if actor == null:
			lift.passengers.erase(id)
		elif actor.target_floor == lift.target_floor:
			actor.floor_index = lift.target_floor
			actor.x = lift.column
			actor.state = &"walking"
			actor.elevator_id = -1
			lift.passengers.erase(id)
			lift.delivered += 1
			exchanged = true
	for id in lift.queue.members.duplicate():
		var actor: ActorState = actors.get(id)
		if actor == null:
			lift.queue.leave(id)
			continue
		if actor.floor_index == lift.target_floor and lift.passengers.size() < lift.capacity:
			lift.queue.leave(id)
			lift.passengers.append(id)
			lift.wait_total += actor.waiting
			lift.wait_max = maxf(lift.wait_max, actor.waiting)
			lift.boarded += 1
			actor.state = &"riding"
			exchanged = true
	if exchanged:
		lift.door_timer = rules.elevator_door_seconds
	# Oldest onboard rider, then oldest waiting call: bounded and starvation-free.
	if not lift.passengers.is_empty():
		lift.target_floor = actors[lift.passengers[0]].target_floor
	elif not lift.queue.members.is_empty():
		lift.target_floor = actors[lift.queue.members[0]].floor_index
