class_name HotelSession
extends RefCounted
## Owns a run. UI sends commands here; systems mutate only their assigned state.

const EMPLOYEES: Array[EmployeeDefinition] = [preload("res://data/employees/receptionist.tres"), preload("res://data/employees/cleaner.tres")]
var rules: SimulationRules = preload("res://data/simulation.tres")
var economy := HotelEconomy.new()
var progression := HotelProgression.new()
var hotel := HotelModel.new(economy, progression)
var transport := TransportSystem.new(rules)
var guests := GuestSystem.new(rules)
var employees := EmployeeSystem.new(rules)
var player_work := PlayerWorkSystem.new()
var actors: Dictionary = {}
var rng := RandomNumberGenerator.new()
var next_actor_id: int = 1
var time: float = 0.0
var tick_count: int = 0
var arrival_timer: float = 0.0
var day: int = 0
var opened: bool = false
var speed: int = 1

func _init(seed_value: int = 123456) -> void:
	rng.seed = seed_value
	hotel.changed.connect(_sync_transport)

func _sync_transport() -> void:
	transport.sync(hotel)

func tick(delta: float) -> void:
	assert(is_equal_approx(delta, rules.tick), "Simulation requires a fixed tick")
	tick_count += 1
	time = tick_count * rules.tick
	transport.sync(hotel)
	employees.step(actors, hotel, transport, delta)
	transport.step(actors, delta)
	player_work.step(self, delta)
	guests.step(actors, hotel, transport, delta, time, player_work.reserved_guest())
	player_work.reconcile(self)
	player_work.update_orders(self)
	if opened:
		arrival_timer -= delta * float(HotelEvents.state(tick_count, rules).multiplier)
		if arrival_timer <= SimulationRules.TIME_EPSILON:
			arrival_timer = rules.arrival_interval * rng.randf_range(0.8, 1.2) * (1.4 - guests.reputation / 100.0)
			if guest_count() < rules.max_guests:
				spawn_guest()
	var current_day: int = floori(time / rules.day_seconds)
	if current_day > day:
		day = current_day
		_pay_daily_expenses()
	progression.evaluate(progression_metrics())

func progression_metrics() -> Dictionary:
	return {"bookings": guests.bookings, "meals": guests.meals_served, "cleaned": employees.cleaned, "completed": guests.completed, "reputation": guests.reputation}

func hire(definition: EmployeeDefinition) -> String:
	if not economy.purchase(definition.hire_cost, "Contratação: " + definition.display_name, time):
		return "Caixa insuficiente para contratar."
	var actor := ActorState.new()
	actor.id = next_actor_id
	next_actor_id += 1
	actor.role = definition.id
	actor.display_name = definition.display_name + " " + str(actor.id)
	actor.state = &"idle"
	actor.speed = definition.speed
	actor.skill = definition.skill
	actors[actor.id] = actor
	return ""

func spawn_guest() -> ActorState:
	var actor := ActorState.new()
	actor.id = next_actor_id
	next_actor_id += 1
	actor.display_name = "Visitante %03d" % actor.id
	var profile: GuestArchetype = HotelCatalog.GUESTS[rng.randi_range(0, HotelCatalog.GUESTS.size() - 1)]
	actor.archetype_id = profile.id
	actor.money = profile.budget
	actor.speed = rules.walk_speed * rng.randf_range(0.85, 1.15)
	actor.needs.hunger = rng.randf_range(30, 55)
	actors[actor.id] = actor
	return actor

func guest_count() -> int:
	var result: int = 0
	for actor: ActorState in actors.values():
		if actor.role == &"guest":
			result += 1
	return result

func demolish(id: int) -> String:
	var room := hotel.by_id(id)
	if room == null:
		return "Selecione uma sala."
	for actor: ActorState in actors.values():
		if actor.assignment == id and actor.in_transit():
			return "Um funcionário está a caminho. Aguarde sua chegada."
		if actor.target_room == id and actor.state != &"exit":
			return "Há alguém usando ou indo para esta sala."
		if room.definition().category == &"transport" and (actor.floor_index > 0 or actor.in_transit()):
			return "Aguarde todos descerem antes de remover o elevador."
	var result := hotel.demolish(id)
	if result.is_empty():
		for actor: ActorState in actors.values():
			if actor.preferred_room == id:
				actor.preferred_room = -1
			if actor.assignment == id:
				actor.assignment = -1
				actor.state = &"idle"
	transport.sync(hotel)
	return result

func alerts() -> String:
	if opened:
		var reception_exists: bool = false
		var staff_exists: bool = false
		for room in hotel.rooms:
			reception_exists = reception_exists or room.definition().category == &"reception"
		for actor: ActorState in actors.values():
			staff_exists = staff_exists or actor.role == &"receptionist"
		if not reception_exists:
			return "Falta recepção: visitantes irão embora. Construa no térreo."
		if not staff_exists:
			return "Recepção sem equipe. Contrate um recepcionista para atender."
	var dirty: int = 0
	var queued: int = 0
	for room in hotel.rooms:
		if room.dirty:
			dirty += 1
		queued += room.queue.members.size()
	var lift_queue: int = 0
	for lift in transport.lifts:
		lift_queue += lift.queue.members.size()
	if lift_queue >= 4:
		return "Elevadores: %d esperando. Considere outro poço." % lift_queue
	if dirty > 0:
		return "%d quarto(s) aguardando limpeza. Contrate camareiros se a fila crescer." % dirty
	if queued > 2:
		return "%d aguardando atendimento. Confira quartos livres e recepcionistas." % queued
	return "Operação estável. Observe a ocupação antes de expandir." if opened else "Hotel fechado para novas chegadas. Construa, contrate e abra as portas."

func _pay_daily_expenses() -> void:
	var costs := recurring_costs()
	if costs.maintenance > 0:
		economy.transact(-costs.maintenance, "Manutenção diária", time)
	if costs.salaries > 0:
		economy.transact(-costs.salaries, "Salários diários", time)

func recurring_costs() -> Dictionary:
	var maintenance: int = 0
	for room in hotel.rooms:
		maintenance += room.maintenance()
	var salaries: int = 0
	for actor: ActorState in actors.values():
		for definition in EMPLOYEES:
			if actor.role == definition.id:
				salaries += definition.salary
	return {"maintenance": maintenance, "salaries": salaries, "total": maintenance + salaries}

func upgrade_room(id: int) -> String:
	var room := hotel.by_id(id)
	if room == null:
		return "Selecione uma sala."
	var next := room.next_upgrade()
	if next == null:
		return "Nível máximo atingido."
	var locked := progression.upgrade_error(room)
	if not locked.is_empty():
		return locked
	if not economy.purchase(next.cost, "Melhoria: %s N%d" % [room.definition().display_name, room.level + 1], time):
		return "Caixa insuficiente para a melhoria."
	room.level += 1
	hotel.changed.emit()
	return ""

func set_room_tariff(id: int, percent: int) -> String:
	var room := hotel.by_id(id)
	if room == null or room.definition().category not in [&"lodging", &"service"]:
		return "Selecione um quarto ou serviço."
	if percent not in [75, 100, 125]:
		return "Tarifa inválida."
	room.price_percent = percent
	hotel.changed.emit()
	return ""

func configure_employee(id: int, destination: int) -> String:
	var actor: ActorState = actors.get(id)
	if actor == null or actor.role not in [&"receptionist", &"cleaner"]:
		return "Selecione um funcionário."
	if destination < -1:
		return "Destino inválido."
	if actor.role == &"receptionist":
		if destination >= 0:
			var room := hotel.by_id(destination)
			if room == null or room.definition().category != &"reception":
				return "Recepcionistas precisam de uma recepção."
			for other: ActorState in actors.values():
				if other.id != id and other.role == &"receptionist" and (other.preferred_room == destination or other.assignment == destination):
					return "Esta recepção já possui um recepcionista."
		actor.preferred_room = destination
	else:
		if destination >= hotel.floors or (destination >= 0 and not transport.accessible(actor.floor_index, destination)):
			return "Andar inexistente ou sem acesso por elevador."
		actor.preferred_floor = destination
	return ""
